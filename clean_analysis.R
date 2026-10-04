library(tidyverse)
library(lubridate)
library(janitor)
library(scales)

# ---- LOAD ----
permits_raw <- read_csv("City_of_Waterloo_Building_Permits_8832863641993349974.csv") |>
  clean_names()

glimpse(permits_raw)
# ---- CLEAN ----
permits <- permits_raw |>
  distinct(permit_id, .keep_all = TRUE) |>
  mutate(
    issue_date = as_date(mdy_hms(issuedate, quiet = TRUE)),
    year = coalesce(as.integer(issue_year), year(issue_date)),
    construction_value = if_else(contrvalue > 0 & contrvalue < 5e8, contrvalue, NA_real_),
    units = if_else(units >= 0, units, NA_real_),
    permitdesc = str_squish(permitdesc),
    workdesc = str_squish(workdesc),
    is_residential = str_detect(permitdesc, regex("^residential", ignore_case = TRUE))
  ) |>
  filter(!is.na(year), year >= 1999)

# Drop the current partial year so trends aren't distorted
cutoff_year <- if (max(permits$year) >= year(Sys.Date())) year(Sys.Date()) - 1 else max(permits$year)
permits_yr <- permits |> filter(year <= cutoff_year)

# ---- CHECKS ----
nrow(permits_raw)                           # rows before cleaning
nrow(permits)                               # rows after cleaning
range(permits$year)                         # year range
sum(is.na(permits$issue_date))              # dates that failed to parse
sum(is.na(permits$construction_value))      # missing values
count(permits, status)
count(permits, permitdesc, sort = TRUE)

# ---- ANALYZE ----
yearly <- permits_yr |>
  group_by(year) |>
  summarise(
    permits = n(),
    total_value = sum(construction_value, na.rm = TRUE),
    median_value = median(construction_value, na.rm = TRUE),
    new_res_units = sum(units[workdesc == "New" & is_residential], na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(permit_growth_pct = round((permits / lag(permits) - 1) * 100, 1))

print(yearly, n = Inf)

# Trend: how many more (or fewer) permits per year?
trend <- lm(permits ~ year, data = yearly)
coef(trend)[["year"]]
# ---- PREP FOR CHARTS ----
by_type <- permits_yr |>
  mutate(permit_group = fct_lump_n(replace_na(permitdesc, "Unknown"), n = 6, other_level = "Other")) |>
  count(year, permit_group)

seasonal <- permits_yr |>
  filter(!is.na(issue_date)) |>
  mutate(month = month(issue_date, label = TRUE)) |>
  count(year, month) |>
  group_by(month) |>
  summarise(avg_permits = mean(n), .groups = "drop")

# ---- CHARTS ----
dir.create("charts", showWarnings = FALSE)

p1 <- ggplot(yearly, aes(year, permits)) +
  geom_line(linewidth = 1, colour = "#1f4e79") +
  geom_point(size = 2, colour = "#1f4e79") +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, linetype = "dashed", colour = "#d95f02") +
  scale_y_continuous(labels = comma) +
  labs(title = "Building permits issued per year",
       subtitle = "City of Waterloo, dashed line = linear trend",
       x = NULL, y = "Permits",
       caption = "Source: City of Waterloo Open Data") +
  theme_minimal(base_size = 13)
ggsave("charts/01_permits_per_year.png", p1, width = 9, height = 5, dpi = 200)

p2 <- ggplot(yearly, aes(year, total_value)) +
  geom_col(fill = "#1f4e79") +
  scale_y_continuous(labels = label_dollar(scale = 1e-6, suffix = "M")) +
  labs(title = "Total construction value of permits per year",
       x = NULL, y = "Construction value",
       caption = "Source: City of Waterloo Open Data. Permits with missing values excluded.") +
  theme_minimal(base_size = 13)
ggsave("charts/02_construction_value.png", p2, width = 9, height = 5, dpi = 200)

p3 <- ggplot(by_type, aes(year, n, fill = permit_group)) +
  geom_col() +
  scale_fill_brewer(palette = "Set2") +
  scale_y_continuous(labels = comma) +
  labs(title = "Permits by type over time", x = NULL, y = "Permits", fill = "Permit type",
       caption = "Source: City of Waterloo Open Data") +
  theme_minimal(base_size = 13)
ggsave("charts/03_permits_by_type.png", p3, width = 10, height = 5.5, dpi = 200)

p4 <- ggplot(seasonal, aes(month, avg_permits)) +
  geom_col(fill = "#d95f02") +
  labs(title = "Average permits issued by month",
       x = NULL, y = "Average permits per month",
       caption = "Source: City of Waterloo Open Data") +
  theme_minimal(base_size = 13)
ggsave("charts/04_seasonality.png", p4, width = 9, height = 5, dpi = 200)

p1; p2; p3; p4

# ---- EXPORT SUMMARIES ----
write_csv(yearly, "yearly_summary.csv")
write_csv(by_type, "permits_by_type.csv")
