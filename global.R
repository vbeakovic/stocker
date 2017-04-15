#### Libraries ####
library(rvest)
library(readr)
library(purrr)
library(dplyr)
library(stringr)
library(tidyr)
library(readxl)
library(gdata)
library(XLConnect)
library(xlsx)
library(reshape2)
library(lubridate)

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



#### Market cap data frame ####
# filter regular marketed stocks
zse_listed_regular_stock <- zse_listed_table %>% 
                                filter(str_detect(simbol, 'R-A'))
no_transactions <- c("VDZG-R-A", "PAN-R-A", "DALS-R-A") 
zse_listed_regular_stock <- filter(zse_listed_regular_stock, !(simbol %in% no_transactions))


zse_listed_regular_stock_details <- map(tickers, function(x) {
        if (str_detect(names(x)[1], "R-A")) {
                ticker <- x
                names(ticker) <- names(x)
                ticker
        } 
}) %>% compact()

# Take out basic ticker info #
tickers_info <- map(zse_listed_regular_stock_details, function(x) {
        info_box <- map_df(x, function(x) {
                if (str_detect(x['X1'], "Zadnja cijena")) {
                        x
                } else {
                        return()
                }
        })
        if (nrow(info_box) == 0) {
                info_box <- NULL
        } else {
        info_box$simbol <- names(x)[1]
        }
        info_box
        #print(paste(class(info_box), names(x)[1]))
}) %>% compact() %>% bind_rows() %>% filter(nchar(X1) > 1) %>% 
        spread(key = X1, value = X2)

# calculate market cap
zse_regular_stocks_overview <- left_join(zse_listed_regular_stock, tickers_info)

names(zse_regular_stocks_overview) <- c(
        "simbol",
        "izdavatelj",
        "ISIN",
        "broj_izdanih",
        "nominala",
        "datum_uvrstenja",
        "t52_najniza",
        "t52_najvisa",
        "broj_transakcija",
        "np_kupnja",
        "np_prodaja",
        "min_cijena",
        "max_cijena",
        "start_cijena",
        "promjena",
        "ukupna_kolicina",
        "ukupni_promet",
        "zadnja_cijena",
        "zakljucna_cijena"
)

# remove . and mil
remove_dot_mil <- function(x) {
        pos <- grepl(pattern = "mil", x = x)
        x[pos] <- gsub(pattern = ".", replacement = "", x = x[pos], fixed = TRUE)
        x[pos] <- gsub(pattern = "mil", replacement = "0000", x = x[pos], fixed = TRUE)
        x <- gsub("\\s", "", x)
        as.numeric(x)
}

# remove % 
remove_percent <- function(x) {
        x <- gsub("%", "", x = x, fixed = TRUE)
}

zse_regular_stocks_overview <- zse_regular_stocks_overview %>% 
        mutate_at(vars(
                broj_izdanih,
                nominala,
                t52_najniza,
                t52_najvisa,
                broj_transakcija,
                np_kupnja,
                np_prodaja,
                min_cijena,
                max_cijena,
                start_cijena,
                promjena,
                ukupna_kolicina,
                ukupni_promet,
                zadnja_cijena,
                zakljucna_cijena
        ), str_replace_all, pattern = "\\.", replacement = "") %>% 
        mutate_at(vars(
                broj_izdanih,
                nominala,
                t52_najniza,
                t52_najvisa,
                broj_transakcija,
                np_kupnja,
                np_prodaja,
                min_cijena,
                max_cijena,
                start_cijena,
                promjena,
                ukupna_kolicina,
                ukupni_promet,
                zadnja_cijena,
                zakljucna_cijena
        ), str_replace_all, pattern = "\\,", replacement = ".") %>% 
        mutate_at(vars(ukupna_kolicina, 
                       ukupni_promet), remove_dot_mil) %>% 
        mutate_at(vars(promjena), remove_percent) %>% 
        mutate_at(vars(
                broj_izdanih,
                nominala,
                t52_najniza,
                t52_najvisa,
                broj_transakcija,
                np_kupnja,
                np_prodaja,
                min_cijena,
                max_cijena,
                start_cijena,
                promjena,
                zadnja_cijena,
                zakljucna_cijena
        ), as.numeric)


# market cap
zse_regular_stocks_overview <- zse_regular_stocks_overview %>% 
        mutate(market_cap = broj_izdanih * zadnja_cijena) %>% 
        arrange(desc(market_cap))
