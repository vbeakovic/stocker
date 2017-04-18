library(shiny)
library(shinydashboard)
library(shinythemes)
library(DT)

#### Header ####
header <- dashboardHeader(
        title = "Stocker"
)

#### Sidebar ####
sidebar <- dashboardSidebar(
        sidebarMenu(
                menuItem("Uređeno tržište", tabName = "uredeno_trziste", icon = icon("bank"))
        )
)

#### Body ####
body <- dashboardBody(
        tabItems(
                tabItem(tabName = "uredeno_trziste", 
                        fluidRow(
                                box(width = 12, solidHeader = TRUE, status = NULL,
                                        dataTableOutput("uredeno_trziste_tablica"))
                                )
                        )
                )
        )

dashboardPage(
        skin = "black",
        header,
        sidebar,
        body
)