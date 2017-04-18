library(shiny)
library(shinydashboard)
library(DT)

shinyServer(function(input, output, session) {
        output$uredeno_trziste_tablica <- renderDataTable(
                zse_listed_table %>% select(simbol, 
                                            izdavatelj,
                                            ISIN,
                                            datum_uvrstenja,
                                            broj_izdanih,
                                            nominala,
                                            nominala_valuta
                                            ) %>% 
                        filter(str_detect(simbol, 'R-A')),
                colnames = c("Simbol", 
                             "Izdavatelj",
                             "ISIN",
                             "Datum uvrštenja",
                             "Broj izdanih dionica",
                             "Nominalna vrijednost",
                             "Valuta"
                             ),
                class = "stripe hover",
                options = list(
                        dom = "lftip",
                        language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/Croatian.json'),
                        columnDefs = list(list(className = 'dt-right', targets = 4)),
                        rowCallback = JS(
                                "function(row, data) {",
                                "var num = data[5].toString().replace(/\\B(?=(\\d{3})+(?!\\d))/g, ',');",
                                "$('td:eq(5)', row).html(num);",
                                "var num = data[6].toString().replace(/\\B(?=(\\d{3})+(?!\\d))/g, ',') + '.00';",
                                "$('td:eq(6)', row).html(num);",
                                "}")
                )
        )        
})