source("SurveyScraper.r")
library(sp)
require(sf)
require(mapview)

# Get course info and all data
courses = getSnowCourses()
snow = getAllCourseRecords(courses)

# Merge the dataframes

snow_full = snow %>% left_join(courses, by = "Course")

# correct non-negative longitude:
courses = 
  courses %>% mutate_at("Longitude", function(x) -1*abs(x)) 

# remove negative snow depths:
courses = 
  courses %>% mutate_at("April_1_Avg_inches", function(x) pmax(x,0))

# create simple features dataframe for mapping
courses_sf = st_as_sf(x = courses,
                      coords = c("Longitude","Latitude"),
                      crs = "+proj=longlat +datum=WGS84")


# Interactive map of courses:
mapviewOptions(basemaps = c("Esri.WorldShadedRelief", "OpenStreetMap", "Esri.WorldImagery", "OpenTopoMap"),
               raster.palette = grey.colors,
               vector.palette = colorRampPalette(c(rgb(1,1,1,0.5),rgb(0,0,1,0.5)), alpha=TRUE)(12),
               na.color = "magenta",
               layers.control.pos = "topright")
mapview(courses_sf,
        zcol = "April_1_Avg_inches",
        lwd = 0)

