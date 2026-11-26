library(shiny)
source("replay.R", local = TRUE)

log <- example_log()
ui <- fluidPage(
  tags$main(style = "max-width:48rem;margin:2rem auto;padding:0 1rem",
    h1("Which quote had arrived?"),
    p("Replay a fictional home-team moneyline. Move the decision time to see which price the analyst had received."),
    radioButtons("second", "Decision time (UTC)",
                 choices = setNames(c(0, 4, 6, 7, 9, 11),
                                    paste0("14:00:", c("00", "04", "06", "07", "09", "11"))),
                 selected = 4, inline = TRUE),
    h2(`aria-live` = "polite", textOutput("answer", inline = TRUE)),
    p(textOutput("explanation", inline = TRUE)),
    h3("Messages received by the decision time"),
    tableOutput("arrivals")
  )
)
server <- function(input, output, session) {
  cutoff <- reactive(example_start() + as.integer(input$second))
  result <- reactive(quote_at(log, "home", cutoff()))
  output$answer <- renderText({
    r <- result()
    if (r$state == "quoted") return(sprintf("Home price: %.2f", r$price))
    if (r$state == "withdrawn") return("Home quote withdrawn")
    "No home quote received"
  })
  output$explanation <- renderText({
    switch(input$second,
      "0" = "The log contains later quotes. None had arrived when this decision was made.",
      "4" = "The 2.10 update was created at 14:00:03. It arrives two seconds after this decision.",
      "6" = "The 2.10 update arrives exactly at the cutoff and is now eligible.",
      "7" = "A delayed 1.85 message just arrived. Its source update is older than the 2.10 update.",
      "9" = "The source withdrew the quote. Carrying 2.10 forward would invent an available price.",
      "11" = "The source issued a new quote after the withdrawal."
    )
  })
  output$arrivals <- renderTable({
    rows <- log[log$received <= cutoff(), ]
    data.frame(Selection = rows$stream,
               Updated = format(rows$updated, "%H:%M:%S", tz = "UTC"),
               Received = format(rows$received, "%H:%M:%S", tz = "UTC"),
               State = rows$state, Price = rows$price)
  }, digits = 2, na = "—")
}
shinyApp(ui, server)
