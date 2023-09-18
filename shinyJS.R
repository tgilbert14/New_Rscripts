##https://deanattali.com/shinyjs/basic
library(shiny)
library(shinydashboard)
library(shinyjs)

ui <- dashboardPage(
  dashboardHeader(),
  dashboardSidebar(),
  dashboardBody(
    useShinyjs(),
    actionButton("button", "Click me"),
    div(id = "hello", "Hello yall!")
    
  )
)

server <- function(input, output) {
  shinyjs::hide("hello")
  observeEvent(input$button, {
    toggle("hello")
  })
}

shinyApp(ui, server)
