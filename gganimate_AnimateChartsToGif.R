#a<- tempfile()
## animate from r-blogger

library(quantmod)
library(dplyr)
library(lubridate)
library(gganimate)

# Define stock tickers and the time period
tickers <- c("AMZN", "AAPL", "GOOGL", "MSFT", "META", "TSLA", "NVDA")
start_date <- Sys.Date() - years(10)
end_date <- Sys.Date()

# The getSymbols() function returns a data.frame of stock data for a given ticker
head(getSymbols("NVDA", src = "yahoo", from = start_date, to = end_date, auto.assign = FALSE), 10)

# Function to download and aggregate stock data
get_monthly_averages <- function(ticker) {
  # Download stock data from Yahoo Finance
  stock_data <- getSymbols(ticker, src = "yahoo", from = start_date, to = end_date, auto.assign = FALSE) 
  # Remove ticker prefix from column names
  colnames(stock_data) <- gsub(paste0(ticker, "\\."), "", colnames(stock_data)) 
  # Keep only the 'Adjusted' column from the data
  stock_data <- stock_data[, "Adjusted"] 
  # Convert the data to a data frame with Date and Adjusted columns
  stock_data <- data.frame(Date = index(stock_data), Adjusted = coredata(stock_data))
  # Add a YearMonth column by flooring the Date to the nearest month
  stock_data$YearMonth <- floor_date(stock_data$Date, "month") 
  
  # Group the data by month and calcualte the mean adjusted price for each period
  monthly_data <- stock_data %>% 
    group_by(YearMonth) %>%
    summarize(Value = mean(Adjusted, na.rm = TRUE)) %>%
    ungroup() %>%
    mutate(Ticker = ticker)
  
  return(monthly_data)
}

data <- lapply(tickers, get_monthly_averages)
data <- bind_rows(data)
data <- data %>%
  arrange(YearMonth, desc(Value))

head(data, 10)

chart_data <- data %>%
  group_by(YearMonth) %>%
  mutate(
    Rank = rank(-Value),
    Label = paste0("$", round(Value, 2))
  )

head(chart_data, 10)

chart_colors <- c(
  AMZN = "#FF9900",
  AAPL = "#555555",
  GOOGL = "#0F9D58",
  MSFT = "#FFB900",
  META = "#0081FB",
  TSLA = "#cc0000",
  NVDA = "#76B900"
)

ggplot(chart_data %>% filter(YearMonth == "2024-05-01"), aes(Rank, group = Ticker, fill = as.factor(Ticker), color = as.factor(Ticker))) +
  geom_tile(aes(y = Value / 2, height = Value, width = 0.9), alpha = 0.9, color = NA) +
  geom_text(aes(y = 0, label = Ticker), vjust = 0.2, hjust = 1.3) +
  geom_text(aes(y = Value, label = Label, hjust = -0.15)) +
  coord_flip(clip = "off", expand = FALSE) +
  scale_x_reverse() +
  scale_fill_manual(values = chart_colors) +
  scale_color_manual(values = chart_colors) +
  theme_minimal() +
  theme(
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    plot.title = element_text(size = 18, face = "bold", color = "#424242"),
    legend.position = "none",
    plot.margin = margin(1, 2, 1, 2, unit = "cm")
  )

p <- ggplot(chart_data, aes(Rank, group = Ticker, fill = as.factor(Ticker), color = as.factor(Ticker))) +
  geom_tile(aes(y = Value / 2, height = Value, width = 0.9), alpha = 0.9, color = NA) +
  geom_text(aes(y = 0, label = Ticker), vjust = 0.2, hjust = 1.3) +
  geom_text(aes(y = Value, label = Label, hjust = -0.15)) +
  coord_flip(clip = "off", expand = FALSE) +
  scale_x_reverse() +
  scale_fill_manual(values = chart_colors) +
  scale_color_manual(values = chart_colors) +
  theme_minimal() +
  theme(
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    plot.title = element_text(size = 18, face = "bold", color = "#424242"),
    legend.position = "none",
    plot.margin = margin(1, 2, 1, 2, unit = "cm")
  )

anim <- p + transition_states(YearMonth, transition_length = 4, state_length = 1) +
  view_follow(fixed_x = TRUE) +
  labs(title = "Average monthly stock price in USD ({closest_state})")

animate(
  anim,
  width = 1024,
  height = 768,
  res = 150,
  nframes = 600,
  fps = 60,
  end_pause = 60,
  renderer = gifski_renderer("stock_race_chart.gif")
)

