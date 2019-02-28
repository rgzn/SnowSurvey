source("SurveyScraper.r")
library(sp)
require(sf)
require(mapview)

# Get course info and all data
courses = getSnowCourses()
snow = getAllCourseRecords(courses)

# Merge the dataframes

snow_long = snow %>% gather(key = "Measurement", value = "value_in", c("Depth", "Water", "Adjusted"))
snow_full = snow_long %>% left_join(courses, by = "Course")

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

