############################################################
# Project: Retail Market & Location-Based Business Analysis
# Tools: R, tidyverse, ggplot2
# Dataset: Online Retail (UCI)
############################################################

# 1. Load required libraries
library(readxl)
library(tidyverse)
library(ggplot2)

# 2. Load data
file_path <- "C:/Users/micha/Downloads/online+retail/Online Retail.xlsx"

if (!file.exists(file_path)) {
  stop("File not found. Check your file path.")
}

retail <- read_excel(file_path)

# 3. Initial inspection
str(retail)
dim(retail)
summary(retail)

# 4. Data cleaning
# - Remove negative quantities and prices
# - Remove missing country values
# - Create Revenue feature
retail_clean <- retail %>%
  filter(
    Quantity > 0,
    UnitPrice > 0,
    !is.na(Country)
  ) %>%
  mutate(Revenue = Quantity * UnitPrice)

dim(retail_clean)
summary(retail_clean$Revenue)
length(unique(retail_clean$Country))

# 5. Handle skewness and extreme outliers
# Visual check
boxplot(retail_clean$Revenue,
        main = "Revenue Distribution (Before Outlier Removal)",
        horizontal = TRUE)

# Remove extreme outliers above 50,000
# Justification: values above this threshold represent rare bulk transactions
# that distort central tendency and visual interpretation
retail_clean <- retail_clean %>%
  filter(Revenue <= 50000)

summary(retail_clean$Revenue)

hist(retail_clean$Revenue,
     breaks = 50,
     main = "Revenue Distribution (After Outlier Removal)")

# 6. Country-level revenue analysis
country_revenue <- retail_clean %>%
  group_by(Country) %>%
  summarise(
    TotalRevenue = sum(Revenue),
    AvgRevenue = mean(Revenue),
    Transactions = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(TotalRevenue))

head(country_revenue, 10)

# 7. Visualization: Top 10 countries by revenue
top10 <- country_revenue %>% slice_head(n = 10)

ggplot(top10,
       aes(x = reorder(Country, TotalRevenue), y = TotalRevenue)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Top 10 Countries by Total Revenue",
    x = "Country",
    y = "Total Revenue"
  )

# 8. Identify under-served markets
# Revenue per transaction indicates pricing power / market depth
country_revenue <- country_revenue %>%
  mutate(RevenuePerTransaction = TotalRevenue / Transactions)

underserved <- country_revenue %>%
  filter(Transactions > 100) %>%   # ignore very small markets
  arrange(desc(RevenuePerTransaction))

head(underserved, 10)

ggplot(underserved %>% slice_head(n = 10),
       aes(x = reorder(Country, RevenuePerTransaction),
           y = RevenuePerTransaction)) +
  geom_bar(stat = "identity", fill = "orange") +
  coord_flip() +
  labs(
    title = "Top 10 Under-Served Markets",
    x = "Country",
    y = "Revenue per Transaction"
  )

# 9. Time-based analysis (seasonality)
retail_clean <- retail_clean %>%
  mutate(
    Month = as.integer(format(InvoiceDate, "%m")),
    Hour  = as.integer(format(InvoiceDate, "%H"))
  )

monthly_rev <- retail_clean %>%
  group_by(Month) %>%
  summarise(TotalRevenue = sum(Revenue), .groups = "drop")

ggplot(monthly_rev,
       aes(x = Month, y = TotalRevenue)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Monthly Revenue Trend",
    x = "Month",
    y = "Total Revenue"
  )

# 10. Pricing analysis
retail_clean %>%
  summarise(
    MinPrice    = min(UnitPrice),
    MedianPrice = median(UnitPrice),
    MeanPrice   = mean(UnitPrice),
    MaxPrice    = max(UnitPrice)
  )

# 11. Market concentration analysis
country_revenue %>%
  mutate(RevenueShare = (TotalRevenue / sum(TotalRevenue)) * 100) %>%
  arrange(desc(RevenueShare)) %>%
  select(Country, TotalRevenue, RevenueShare) %>%
  slice_head(n = 5)

############################################################
# KEY BUSINESS INSIGHTS:
# 1. Retail revenue is highly right-skewed; median transaction values
#    better represent typical customer behavior than the mean.
# 2. A small number of countries dominate total revenue,
#    indicating significant market concentration risk.
# 3. Several countries show high revenue per transaction but
#    lower transaction volume, suggesting under-served markets.
# 4. Revenue exhibits seasonal patterns, making timing a critical
#    factor in retail business strategy.
# 5. Pricing analysis shows most transactions occur in low-to-mid
#    price ranges, emphasizing volume-based business models.
############################################################
