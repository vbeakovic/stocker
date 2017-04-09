#### Libraries ####
library(rvest)


#### Read in listed stocks ####
if (file.exists("./varijable/rba_kune.Rdata")) {
        load("./varijable/rba_kune.Rdata")
} else {
zse_url <- "http://zse.hr/default.aspx?id=26472"
zse_listed_web <- read_html(zse_url)
zse_listed_table <- html_nodes(zse_listed_web, xpath = "//table[@id='dnevna_trgovanja']")
zse_listed_table <- html_table(zse_listed_table[[1]])
save(zse_listed_table, file = "data/zse_listed_table.RData")
}