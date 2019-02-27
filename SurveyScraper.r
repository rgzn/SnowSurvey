library(tidyverse)
library(httr)
library(rvest)
library(glue)

# getSnowCourses
# retrieve dataframe of all snowcourses and their info
getSnowCourses <- function() {
  snowcourses_url = "http://cdec.water.ca.gov/snow/misc/SnowCourses_ss.html"
  snowcourses_html = read_html(snowcourses_url)
  
  # convert HTML table to df:
  snowcourses_df = snowcourses_html %>% 
    rvest::html_nodes("table") %>% 
    .[[1]] %>% 
    rvest::html_table()
  
  # remove spaces and special characters from column names:
  names(snowcourses_df) = names(snowcourses_df) %>% 
    str_replace_all(" ", "_") %>% 
    str_replace_all("[()]", "") %>%
    str_replace_all("_#", "")
  
  # extract names of river basins, which are not in proper tabular format
  basins = snowcourses_df %>% filter(str_detect(`Course`, "[a-zA-Z]+")) %>% .[,1]
  
  # create river basin column with appropriate entry:
  for ( i in 1:nrow(snowcourses_df)) {
    if (snowcourses_df[i,1] %in% basins) {
      basin = snowcourses_df[i,1]
    }
    snowcourses_df[i, "Basin"] = basin
  }
  
  # remove non-tabular river basin rows:
  snowcourses_df = snowcourses_df %>% 
    filter(str_detect(`Course`, "[0-9]+"))
  
  # convert data to proper types:
  snowcourses_df = snowcourses_df %>% mutate_at(c("Course"), as.integer) 
  snowcourses_df = snowcourses_df %>% mutate_at(
    c("Elev_feet", "Latitude", "Longitude", "April_1_Avg_inches"),
    as.numeric) 
  
  return(snowcourses_df)
}

# getCourseRecord
# get data for a single snow course using its course number
getCourseRecord = function(course_num, start_year="1900", end_year="2019", month="(ALL)") {
  # example request:
  #   http://cdec.water.ca.gov/cgi-progs/snowQuery_ss?course_num=221&month=%28All%29&start_date=1900&end_date=2019&csv_mode=Y&data_wish=Retrieve+Data

  course_num = as.character(course_num)
  start_year = as.character(start_year)
  end_year = as.character(end_year)
  month = as.character(month)
  
  base_url = "http://cdec.water.ca.gov/cgi-progs/snowQuery_ss?"
  csv_param = "csv_mode=Y"
  wish_param = "data_wish=Retrieve+Data"
  course_param = glue("course_num={course_num}")
  month_param = glue("month={month}")
  start_param = glue("start_date={start_year}")
  end_param = glue("end_date={end_year}")
  
  request_url = glue(
    "{base_url}{course_param}&{month_param}&{start_param}&{end_param}&{csv_param}&{wish_param}")
  
  r = httr::GET(request_url)
  httr::stop_for_status(r)
  
  # HTML response indicates no data:
  if(r$headers$`content-type` == "text/html") {
    return(NULL)
  }
  
  result = httr::content(r, encoding = "UTF-8")
  result = gsub("^[^\n]*\n","", result) # remove first line, which is not csv
  record = read_csv(result, col_names = TRUE, na = "--")
  record = add_column(record, Course = as.integer(course_num), .before = 1)
  return(record)
}

# getAllCourseRecords
# gets records for multiple courses, by default all courses, all months, 1900-2019
getAllCourseRecords = function(snowcourses_df = getSnowCourses(), start_year="1900", end_year="2019", month="(ALL)") {
  courses_list = snowcourses_df$Course
  record_list = lapply(courses_list, function(x) getCourseRecord(course_num = x, 
                                              start_year = start_year,
                                              end_year = end_year,
                                              month = month))
  all_records = bind_rows(record_list)
  return(all_records)
}

