# SnowSurvey

This is a collection of R functions and scripts to download and analyse data from California Cooperative Snow Surveys. 
All data is public data obtained from [CDEC](http://cdec.water.ca.gov)

## Files:
 
  + SurveyScraper.r: Collection of functions to download and format data from CDEC API
  + SurveyAnalyze.r: Script with data manipulation, mapping, and analysis 

## Use:

Get a dataframe of all the snowcourses:

```R
source("SurveyScraper.r")
snowcourses_df = getSnowCourses()
head(snowcourses_df)
```
```
  Course             Name  ID Elev_feet Latitude Longitude April_1_Avg_inches             Measuring_Agency    Basin
1      1      PARKS CREEK PRK      6700   41.367   122.550               37.4 Mount Shasta Ranger District SHASTA R
2      2    LITTLE SHASTA LSH      6200   41.808   122.195               19.0    Goosenest Ranger District SHASTA R
3      3       SWEETWATER SWT      5850   41.382   122.533               13.7 Mount Shasta Ranger District SHASTA R
4      5 MIDDLE BOULDER 1 MBL      6600   41.217   122.807               32.4  Scott River Ranger District  SCOTT R
5    417         BOX CAMP BXC      6450   41.597   123.165               35.9  Scott River Ranger District  SCOTT R
6    311 MIDDLE BOULDER 3 MB3      6200   41.225   122.811               28.3  Scott River Ranger District  SCOTT R
```

Get a records for a specific snow course using the course number:

```R
snowcourse_221 = getCourseRecord(course_num = 221, start_year="1900", end_year="2019", month="(ALL)")
head(snowcourse_221)
```

```
# A tibble: 6 x 6
  Course Date   Meas.Date   Depth Water Adjusted
   <int> <chr>  <chr>       <dbl> <dbl>    <dbl>
1    221 4/1926 25-MAR-1926  16.4   6.2       NA
2    221 5/1927 27-APR-1927  34.6  12.3       NA
3    221 3/1928 16-FEB-1928   8     1.8       NA
4    221 1/1929 15-JAN-1929  16.8   2.9       NA
5    221 4/1929 02-APR-1929  20.3   7.2       NA
6    221 2/1930 11-FEB-1930  11.4   3.1       NA
```

Get all snowcourse data:
```R
courses = getSnowCourses()
snow = getAllCourseRecords()

# join course and snow data:
snow_full = snow %>% left_join(courses, by = "Course") 
head(snow_full)
```

```
# A tibble: 6 x 14
  Course Date   Meas.Date   Depth Water Adjusted Name        ID    Elev_feet Latitude Longitude April_1_Avg_inches Measuring_Agency             Basin  
   <int> <chr>  <chr>       <dbl> <dbl>    <dbl> <chr>       <chr>     <dbl>    <dbl>     <dbl>              <dbl> <chr>                        <chr>  
1      1 3/1936 06-MAR-1936  95.2  37.8     37.8 PARKS CREEK PRK        6700     41.4      123.               37.4 Mount Shasta Ranger District SHASTA~
2      1 2/1937 21-JAN-1937  38.8  11.8     17.7 PARKS CREEK PRK        6700     41.4      123.               37.4 Mount Shasta Ranger District SHASTA~
3      1 4/1937 27-MAR-1937 118.   32.9     33.3 PARKS CREEK PRK        6700     41.4      123.               37.4 Mount Shasta Ranger District SHASTA~
4      1 2/1938 26-JAN-1938  45.7  14.4     18.1 PARKS CREEK PRK        6700     41.4      123.               37.4 Mount Shasta Ranger District SHASTA~
5      1 4/1938 25-MAR-1938 116.   32.2     32.2 PARKS CREEK PRK        6700     41.4      123.               37.4 Mount Shasta Ranger District SHASTA~
6      1 2/1939 24-JAN-1939  38.4  12.3     13.3 PARKS CREEK PRK        6700     41.4      123.               37.4 Mount Shasta Ranger District SHASTA~
```
