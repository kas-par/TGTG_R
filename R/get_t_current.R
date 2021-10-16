get_t_current <- function(client = client, augen = augen, emails) {
  
  #source("R/sending_email.R")
  
  # 1. Set up the DB connection details
  
  ## 1.1 Check if DB already exists - if yes -> load data; and if not -> create DB ====
  
  sqlitePath = "tgtg_database.db"
  
  db <- dbConnect(RSQLite::SQLite(), sqlitePath) #establish connection
  temp_table = try(dbGetQuery(db, "SELECT * FROM Food where Datum = current_date"))
  dbDisconnect(db)
  
  if (class(temp_table) == "try-error"){
    db <- dbConnect(RSQLite::SQLite(), sqlitePath) #establish connection
    print("first time database created")
    t_food = tibble(Name = NA_character_, Datum = NA_character_, Zeit = NA_character_, 
                    Anzahl = NA_real_)
    dbWriteTable(db, "Food", t_food)
    print("Table initialisiert")
    dbDisconnect(db)
    t_food = filter(t_food, Name !="test")
  } else {
    t_food = as_tibble(temp_table[,])
  }
  
  rm(temp_table)
  
  
  ## 1.2 Set up TGTG-Client and load newest data
  
  t_newest_tgtg_data = client$get_items(
    favorites_only = F,
    latitude=47.42391, #St. Galler Koordinaten
    longitude=9.37477,
    radius = 100,
    with_stock_only = T,
    page_size  = 100
  )
  
  t_current = tibble(Name = rep(NA, length(t_newest_tgtg_data)), Datum = Sys.Date(), 
                     Zeit = Sys.time(), Anzahl = rep(NA, length(t_newest_tgtg_data)))
  
  
  for (stores in 1:length(t_newest_tgtg_data)) {
    t_current$Name[stores] = t_newest_tgtg_data[[stores]]$display_name
    t_current$Anzahl[stores] = t_newest_tgtg_data[[stores]]$items_available
  }
  
  
  
  t_current = t_current %>% 
    filter(Name %in% augen) %>% 
    anti_join(t_food, by="Name") %>%  #check if already in the database
    mutate(Datum = as.character(Datum),
           Zeit = as.character(Zeit))
  
  
  if (nrow(t_current)>0){
    db <- dbConnect(RSQLite::SQLite(), sqlitePath) #establish connection
    dbWriteTable(db, "Food", t_current, append = TRUE) #zu Tabelle "Food"
    dbDisconnect(db)
  } else {
    
    return(NULL)
  }
  
  if (is.null(t_current) == F) {
    sending_email(t_current, emails)
  } else {
    print("Nichts Neues vorhanden.")
  }
  
}
