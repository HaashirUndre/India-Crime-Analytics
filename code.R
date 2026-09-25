install.packages(c(
  "tidyverse",
  "janitor",
  "lubridate",
  "ggplot2",
  "scales",
  "corrplot"
))

crime_data <- read.csv("crime_dataset_india.csv")

View(crime_data)
summary(crime_data)
