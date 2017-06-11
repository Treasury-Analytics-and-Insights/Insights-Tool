treasury_header <- function() {
  div(
    id = "treasury-header",
    div(class = "treasury-topbar"),
    div(
      class = "treasury-brand",
      tags$a(class = "treasury-brand", href = "http://www.treasury.govt.nz/",
             title = "Treasury NZ",
             tags$img(src = "img/treasury-logo.png",
                      alt = "Treasury NZ")),
      h1("SII Dashboard")
    )
  )
}


