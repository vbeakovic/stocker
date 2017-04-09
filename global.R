#### Libraries ####
library(rvest)
library(readr)
library(purrr)

#### Read in listed stocks ####
if (file.exists("./data/zse_listed_table.RData")) {
        load("./data/zse_listed_table.RData")
} else {
zse_url <- "http://zse.hr/default.aspx?id=26472"
zse_listed_web <- read_html(zse_url)
zse_listed_table <- html_nodes(zse_listed_web, xpath = "//table[@id='dnevna_trgovanja']")
zse_listed_table <- html_table(zse_listed_table[[1]])
names(zse_listed_table) <- c("simbol", 
                             "izdavatelj", 
                             "ISIN", 
                             "broj_izdanih", 
                             "nominala", 
                             "datum_uvrstenja")
zse_listed_table <- zse_listed_table[2:nrow(zse_listed_table), ]
save(zse_listed_table, file = "data/zse_listed_table.RData")
}

#### Read in official market tickers ###
if (file.exists("./data/official_market_tickers.RData")) {
        load("./data/official_market_tickers.RData")
} else {
official_market_tickers <- read_lines("files/official_market.txt")
official_market_tickers <- gsub("\t", "", x = official_market_tickers)
save(official_market_tickers, file = "data/official_market_tickers.RData")
}
#### Read in regular market tickers ###
if (file.exists("./data/regular_market_tickers.RData")) {
        load("./data/regular_market_tickers.RData")
} else {
regular_market_tickers <- read_lines("files/regular_market.txt")
regular_market_tickers <- gsub("\t", "", x = regular_market_tickers)
save(regular_market_tickers, file = "data/regular_market_tickers.RData")
}

#### Get each ticker info ####
if (file.exists("./data/tickers.RData")) {
        load("./data/tickers.RData")
} else {
tickers <- map(zse_listed_table$simbol, function(x) {
        ticker_url <- paste("http://zse.hr/default.aspx?id=10006&dionica=", x, sep = "")
        ticker_page <- read_html(ticker_url)
        ticker_table <- html_nodes(ticker_page, xpath = "//table[@class='dioniceSheet1']")
        
        ticker <- map(ticker_table, function(x) {
                html_table(x)
        })
        names(ticker) <- rep(x = x, times = length(ticker))
        ticker
})
save(tickers, file = "data/tickers.RData")
}