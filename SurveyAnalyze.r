source("SurveyScraper.r")
# library(sp)
require(sf)
require(mapview)
require(ggplot2)
require(ggmap)

# Get course info and all data
courses = getSnowCourses()
snow = getAllCourseRecords(courses)

# Merge the dataframes

snow_long = snow %>% gather(key = "Measurement", value = "value_in", c("Depth", "Water", "Adjusted"))
snow_full = snow_long %>% left_join(courses, by = "Course")

# import external polygons:
ru_shapefile = "./shapefiles/Recovery_Units.shp"
ru_polygons = st_read(ru_shapefile)
ru_crs = st_crs(ru_polygons)

# join polygons of like recovery units into multipolygons:
gcu_list = unique(ru_polygons$GCU)
ru_sf_list = lapply(gcu_list, function(gcu) {
  ru_geom = st_union(ru_polygons %>% filter(GCU == gcu))
  return(st_sf(data.frame(RU=gcu, geom=ru_geom)))
})
ru_sf = reduce(ru_sf_list, rbind)


# create simple features dataframe for mapping
courses_sf = st_as_sf(x = courses,
                      coords = c("Longitude","Latitude"),
                      crs = "+proj=longlat +datum=WGS84")
courses_sf = st_transform(courses_sf, ru_crs)

# Interactive map of courses:
mapviewOptions(basemaps = c("Esri.WorldShadedRelief", "OpenStreetMap", "Esri.WorldImagery", "OpenTopoMap"),
               raster.palette = grey.colors,
               vector.palette = colorRampPalette(c(rgb(1,1,1,0.5),rgb(0,0,1,0.5)), alpha=TRUE)(12),
               na.color = "magenta",
               layers.control.pos = "topright")
mapview(courses_sf,
        zcol = "April_1_Avg_inches",
        lwd = 0)


ca_basemap <- get_map(location="Reno, CA", zoom=6, maptype = 'terrain')

