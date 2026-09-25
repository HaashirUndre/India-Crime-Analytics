## ============================================================
## INDIA CRIME ANALYTICS
## Statistical Exploration of Reported Crime Patterns Across Major Cities
## ============================================================

## ---- 1. SETUP ----------------------------------------------
library(tidyverse)
library(janitor)
library(lubridate)
library(scales)
library(sf)
library(geodata)

## ---- 2. LOAD + CLEAN DATA ------------------------------------

crime_data <- read.csv("crime_dataset_india.csv") %>%
  clean_names() %>%
  mutate(
    date_occurred = mdy_hm(date_of_occurrence),   # format: MM-DD-YYYY HH:MM
    year          = year(date_occurred),
    month         = month(date_occurred, label = TRUE),
    day_of_week   = wday(date_occurred, label = TRUE),
    hour          = hour(date_occurred)
  )

# sanity check - should be 0
sum(is.na(crime_data$date_occurred))


## ---- 3. STATE MAPPING (for choropleth) ------------------------

state_lookup <- tibble(
  city = c("Delhi","Mumbai","Bangalore","Hyderabad","Kolkata","Chennai","Pune",
           "Ahmedabad","Jaipur","Lucknow","Kanpur","Surat","Nagpur","Agra",
           "Ludhiana","Visakhapatnam","Thane","Ghaziabad","Indore","Patna",
           "Bhopal","Meerut","Srinagar","Nashik","Vasai","Kalyan","Varanasi",
           "Faridabad","Rajkot"),
  state = c("NCT of Delhi","Maharashtra","Karnataka","Telangana","West Bengal","Tamil Nadu","Maharashtra",
            "Gujarat","Rajasthan","Uttar Pradesh","Uttar Pradesh","Gujarat","Maharashtra","Uttar Pradesh",
            "Punjab","Andhra Pradesh","Maharashtra","Uttar Pradesh","Madhya Pradesh","Bihar",
            "Madhya Pradesh","Uttar Pradesh","Jammu and Kashmir","Maharashtra","Maharashtra","Maharashtra","Uttar Pradesh",
            "Haryana","Gujarat")
)

crime_data <- crime_data %>%
  left_join(state_lookup, by = "city")

# sanity check - should be 0 unmatched
sum(is.na(crime_data$state))


## ============================================================
## GRAPH 1 — Crime Domain Distribution
## ============================================================

crime_data %>%
  count(crime_domain, sort = TRUE) %>%
  mutate(pct = percent(n / sum(n)))

ggplot(crime_data, aes(x = fct_infreq(crime_domain))) +
  geom_bar(fill = "steelblue") +
  labs(title = "Crime Domain Distribution", x = "Crime Domain", y = "Count") +
  theme_minimal()


## ============================================================
## GRAPH 2 — Top 15 Crime Types
## ============================================================

crime_data %>%
  count(crime_description, sort = TRUE) %>%
  head(15) %>%
  ggplot(aes(x = reorder(crime_description, n), y = n)) +
  geom_col(fill = "darkred") +
  coord_flip() +
  labs(title = "Top 15 Crime Types", x = NULL, y = "Count") +
  theme_minimal()


## ============================================================
## GRAPH 3 — Total Reported Crimes by City
## ============================================================

city_summary <- crime_data %>%
  count(city, sort = TRUE)

ggplot(city_summary, aes(x = reorder(city, n), y = n)) +
  geom_col(fill = "darkorange") +
  coord_flip() +
  labs(title = "Total Reported Crimes by City", x = NULL, y = "Count") +
  theme_minimal()


## ============================================================
## GRAPH 4 — Reported Crimes by State (Choropleth Map)
## ============================================================

# download India state boundaries
india_states <- gadm(country = "IND", level = 1, path = tempdir()) %>%
  st_as_sf()

state_summary <- crime_data %>%
  count(state, sort = TRUE)

india_map_data <- india_states %>%
  left_join(state_summary, by = c("NAME_1" = "state"))

# sanity check - should be 15 (states present in dataset)
india_map_data %>% st_drop_geometry() %>% filter(!is.na(n)) %>% nrow()

ggplot(india_map_data) +
  geom_sf(aes(fill = n), color = "white", size = 0.2) +
  scale_fill_gradient(
    low = "lightyellow", high = "darkred", na.value = "grey90",
    name = "Reported\nCrimes"
  ) +
  labs(
    title    = "Reported Crimes by State (India)",
    subtitle = "Based on dataset covering 29 major cities",
    caption  = "Grey states = no cities from this dataset located there"
  ) +
  theme_minimal() +
  theme(axis.text = element_blank(), axis.ticks = element_blank())


## ============================================================
## GRAPH 5 + STATS — Crime Volume vs Case Closure Rate
## (Correlation + Simple Linear Regression)
## ============================================================

crime_stats <- crime_data %>%
  group_by(crime_description) %>%
  summarise(
    total_incidents = n(),
    closed_count    = sum(case_closed == "Yes"),
    closure_rate    = closed_count / total_incidents * 100
  ) %>%
  arrange(desc(total_incidents))

# correlation test
cor.test(crime_stats$total_incidents, crime_stats$closure_rate)

# linear regression
model <- lm(closure_rate ~ total_incidents, data = crime_stats)
summary(model)

# plot
ggplot(crime_stats, aes(x = total_incidents, y = closure_rate)) +
  geom_point(color = "steelblue", size = 3) +
  geom_smooth(method = "lm", se = TRUE, color = "darkred") +
  labs(
    title = "Crime Volume vs Case Closure Rate",
    x = "Total Reported Incidents", y = "Closure Rate (%)"
  ) +
  theme_minimal()

## ============================================================
## END OF SCRIPT
## ============================================================