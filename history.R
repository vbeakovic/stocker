# Description
# The script loads the historical transactions data od regular marketed stocks on ZSE
#### Ticker history ####
# function to load regular stock transaction data
ticker_history <- function(x, path, start, end) {
        
        # define .Rdata file name and path to store stock data
        var_name <- tolower(gsub("-", "_", x, fixed = TRUE))
        file_path <- paste0(path, var_name, ".RData")
        # ticker data load function
        load_ticker_history <- function(x, path, start, end){
                url <- paste0(
                        "http://zse.hr/export.aspx?ticker=",
                        x,
                        "&reporttype=security&DateTo=",
                        end,
                        "&DateFrom=",
                        start,
                        "&range=&lang=hr&version=2"
                )
                dest_file <- paste0(path, x,".xlsx")
                download.file(url, destfile = dest_file, method = "auto")
                ticker_data <- read.xlsx2(dest_file, sheetIndex = 1, stringsAsFactors = FALSE, 
                                          colClasses = c(
                                                  "Date",
                                                  "character",
                                                  "numeric",
                                                  "numeric",
                                                  "numeric",
                                                  "numeric",
                                                  "numeric",
                                                  "numeric",
                                                  "numeric",
                                                  "numeric",
                                                  "numeric"
                                          ))
                names(ticker_data) <- c(
                        "datum", "vrsta_prometa", "prva", "zadnja", "najvisa", 
                        "najniza", "prosjecna", "promjena", "broj_transakcija",
                        "kolicina", "promet"
                )
                if (nrow(ticker_data) > 0) {
                        ticker_data$simbol = x        
                }
                file.remove(dest_file)
                ticker_data
        }
        
        ticker_data <- NULL
        ticker_data_append <- NULL
        if (file.exists(file_path)) {
                ticker_data <- get0(load(file_path))  
                if (!is.null(ticker_data)) {
                        if (max(ticker_data$datum) < end) {
                                end_day = paste0(day(end), ".", month(end), ".", year(end))
                                start_tmp <- max(ticker_data$datum) + 1 
                                start_day = paste0(day(start_tmp), ".", month(start_tmp), ".", year(start_tmp))
                                ticker_data_append <- load_ticker_history(x, path, start = start_day, end = end_day)
                        }
                }
                
                if (!is.null(ticker_data_append)) {
                        ticker_data <- rbind(ticker_data, ticker_data_append) 
                }
        } else {
                end_day = paste0(day(end), ".", month(end), ".", year(end))
                start_day = paste0(day(start), ".", month(start), ".", year(start))
                ticker_data_append <- load_ticker_history(x, path, start = start_day, end = end_day)   
                if (nrow(ticker_data_append) > 0) {
                        ticker_data <- ticker_data_append        
                } else {
                        ticker_data <- NULL
                }
        }
        ifelse(nrow(ticker_data) > 0, ticker_data <- arrange(ticker_data, datum), NULL)
        assign(var_name, ticker_data, pos = -1)
        save(list = var_name, file = file_path)
        ticker_data
}

#### Load tickers transactions data ####
zse_regular_stocks_history <- map(zse_regular_stocks_overview$simbol, ticker_history, path = "./history/", start = "2016-01-01", end = "2017-04-14") %>% 
        compact()



### fill in missing dates
### ubacivanje datuma koji fale
date_seq <- seq.Date(zse_regular_stocks_history[[1]]$datum[1], as.Date("2017-04-14"), by = "day")
date_seq_df <- data.frame(datum = date_seq)
test_join <- full_join(date_seq_df, zse_regular_stocks_history[[1]])

fill_dates <- function(x, end) {
        print(str(x$datum))
        date_seq <- seq.Date(x$datum[1], as.Date("2017-04-14"), by = "day")
        date_seq_df <- data.frame(datum = date_seq)
        x_filled <- test_join <- full_join(date_seq_df, x)
        x_filled$prva <- na.locf(x_filled$prva)
        x_filled$zadnja <- na.locf(x_filled$zadnja)
        x_filled$najvisa <- na.locf(x_filled$najvisa)
        x_filled$najniza <- na.locf(x_filled$najniza)
        x_filled$prosjecna <- na.locf(x_filled$prosjecna)
        x_filled$simbol <- na.locf(x_filled$simbol)
        x_filled
}


zse_regular_stocks_history_filled <- map(zse_regular_stocks_history, fill_dates, end = as.Date("2017-04-14"))




