library(tidyverse)
library(httr)
# library(rvest)
library(glue)
library(sf)

start_date_string = "1900-01-01"
end_date_str = format(Sys.time(), "%Y-%m-%d")

# Create dataframne of all CDEC stations:

# stations file generated from request to:
# http://cdec.water.ca.gov/dynamicapp/staSearch?sta=&sensor_chk=on&sensor=18&collect=NONE+SPECIFIED&dur=&active=&lon1=&lon2=&lat1=&lat2=&elev1=-5&elev2=99000&nearby=&basin=NONE+SPECIFIED&hydro=NONE+SPECIFIED&county=NONE+SPECIFIED&agency_num=160&display=sta

stations_file = "stations.csv"
stations = read_csv(stations_file)
stations_sf = st_as_sf(x = stations,
                      coords = c("Longitude","Latitude"),
                      crs = "+proj=longlat +datum=WGS84")

# Create dataframe listing the snow sensors and their ids:
measurement = c("SWE","SNOW_DEPTH","SWE_REVISED")
sensor_id = c(3, 18, 82)
sensors = data.frame(measurement, sensor_id)

# import external polygons:
ru_shapefile = "./shapefiles/Recovery_Units.shp"
ru_polygons = st_read(ru_shapefile)
ru_crs = st_crs(ru_polygons)

# join polygons of like recovery units into multipolygons:
gcu_list = unique(ru_polygons$GCU)
ru_sf_list = lapply(gcu_list, function(gcu) {
  ru_geom = st_union(ru_polygons %>% filter(GCU == gcu))
  ru_df = data.frame(RU=gcu, geom=ru_geom)
  return(st_sf(ru_df))
})
ru_sf = reduce(ru_sf_list, rbind) # m-polygons for each RU
sheep_sf = st_union(ru_sf) # single m-polygon for all sheep
sheep_crs = st_crs(sheep_sf)

stations_sf = st_transform(stations_sf, sheep_crs)
stations_sf = stations_sf %>% mutate(sheep_distance = st_distance(x = geometry, y = sheep_sf))

# find closest recovery unit for each station:
get_closest_sf = function(x, ys) {
  x = st_transform(x, st_crs(ys))
  # ys = st_transform(ys, st_crs(x))
  ys_distance = ys %>% mutate(distance = st_distance(geometry, x))
  min_y = filter(ys_distance, rank(distance, ties.method="min") == 1)
  return(min_y)
}

get_closest_ru = function(x, rus) {
  closest_ru = get_closest_sf(x, rus)
  closest_ru = as.data.frame(closest_ru)
  return(as.character(closest_ru$RU))
}

# This is maddening:
closest_ru = lapply(stations_sf$geometry, function(x) get_closest_ru(st_sfc(x,crs=sheep_crs), ru_sf))

stations_sf$closest_RU = closest_ru

# select stations from which to pull data:
my_stations = stations_sf %>% 
  filter(ElevationFeet > 6000) %>%
  filter(sheep_distance < 10000)


# Request data for filtered stations and snow measurements:
cdec_base_url = "http://cdec.water.ca.gov/dynamicapp/req/CSVDataServlet?"
station_field = glue("Stations=", paste(my_stations$ID, collapse=","))
sensor_field = glue("SensorNums=", paste(sensors$sensor_id, collapse=","))
duration_field = glue("dur_code=M")
start_field = glue("Start=", start_date_string)
end_field = glue("End=", end_date_str)
param_string = paste(station_field, sensor_field, duration_field, start_field, end_field, sep="&")
request_url = glue(cdec_base_url, param_string)

r = httr::GET(request_url)
httr::stop_for_status(r)
records = read_csv(httr::content(r, encoding = "UTF-8"), 
                   col_names = TRUE, na = "")

# full table of snow records:
snow = records %>% left_join(stations_sf, by = c("STATION_ID" = "ID"))
