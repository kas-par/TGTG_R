###
# Main file - Controlling the data colelction and sending the newest offers by mail
###

# 1. Settings ----

## 1.1 Load the required R packages ====

my_packages <- c("reticulate", "RSQLite", "tidyverse")

for (i in 1:length(my_packages)){
  if(!require(my_packages[i], character.only = TRUE)){
    install.packages(my_packages[i])
  }
}


## 1.2 Load the required Python Packages ====

use_python("/usr/local/bin/python3")
os <- import("os")

my_python_packages = c("smtplib", "tgtg", "emails", "schedule", "email.mime.text",
                       "email.mime.multipart")

for (i in my_python_packages) {
  
  tryCatch(
    expr = {
      assign(i,import(i))
    },
    error = function(e){ 
      py_install(i)
      assign(i, import(i))
      paste0(i, " package is not installed. Starting installation process")
    }
  )
}

rm(my_packages, my_python_packages, i)

## 1.3 Load the required functions ====

#source("/../R/get_t_current.R")
#source("R/sending_email.R")


# 2. Define the Offers and stores, which should be observed ----

augen = c("Globus ★★★delicatessa - St. Gallen", "Café Goldkind", "Franz", 
          "Schiffchuchi", "Alnatura - St. Gallen (vegetarisch)", "Greco Fine Food", 
          "dean&david - Neumarkt (Vegetarisch)",
          "tibits - St. Gallen  (vegan)", "tibits - St. Gallen  (vegetarisch)",
          "MÜLLER Reformhaus - St Gallen")


# 3. Set up TGTG client, load newest data and set the offers by email ----

client = tgtg$TgtgClient(email="k.lichtsteiner@hotmail.com", password="a782nlfsklFFF!!.fsdfsd", 
                         user_agent = "TooGoodToGo/21.9.3 (541) (iPhone/iPhone 7 (GSM); iOS 13.6; Scale/2.00)")

sending_email <- function(t_current, to_mail){
  
  # 4. Set up Email ----
  
  ## 4.1 Settings ----
  
  gmail_user = "HeutigerFreudenSprung@gmail.com"
  gmail_password = 'fuvnu8-hoqsYk-tesmov'
  to = to_mail
  
  
  ## 4.2 Prepare the Message ====
  
  # The email message needs to be constructed differently if there is more than 1 new offer
#  s_message = "From: Heutiger Freudensprung <HeutigerFreudenSprung@gmail.com>
# Subject: "
  
  if (nrow(t_current) > 1) {
    
    s_temp = paste0("Portionen von ",  paste(t_current$Name, collapse = ", "), " sind vorhanden")
    
  } else if (nrow(t_current) == 1){
    
    s_temp <- paste0(t_current$Anzahl," Portionen von ", t_current$Name, 
                     " sind vorhanden")
  }

  #s_message_final <- paste0(s_message, s_temp)
  

  # Python script is needed to encrypt the message in utf-8, such that special characters
  # in TGTG-Response are encoded correctly
  
  source_python('sendingMail.py')
  message = sendingMail(subject = s_temp, body = "", From = gmail_user, to = to_mail)

  smtpObj = smtplib$SMTP_SSL('smtp.gmail.com', port = "465")
  smtpObj$ehlo()
  smtpObj$login(gmail_user, gmail_password)
  smtpObj$sendmail(gmail_user, to, message$as_string())
  smtpObj$quit()
  
}

get_t_current <- function(client = client, augen = augen) {
  
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
    t_food = tibble(Name = "test", Datum = "", Zeit = "", Anzahl = 0)
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
    sending_email(t_current, "kaspar.lichtsteiner@inscreen.ch")
  } else {
    print("Nichts Neues vorhanden.")
  }
  
}

while (TRUE == TRUE) {
  t_current = get_t_current(client, augen)
  print(t_current)
  Sys.sleep(300)
}                             
