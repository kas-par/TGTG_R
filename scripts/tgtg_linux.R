###
# Main file - Controlling the data colelction and sending the newest offers by mail
###

# 1. Settings ----

## 1.1 Load the required R packages ====

my_packages <- c("reticulate", "RSQLite", "tidyverse", "htmlTable")

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

source("R/get_t_current.R")
source("R/sending_email.R")


# 2. Define the Offers and stores, which should be observed ----

augen = c("Globus ★★★delicatessa - St. Gallen", "Café Goldkind", "Franz", 
          "Schiffchuchi", "Alnatura - St. Gallen (vegetarisch)", "Greco Fine Food", 
          "dean&david - Neumarkt (Vegetarisch)",
          "tibits - St. Gallen  (vegan)", "tibits - St. Gallen  (vegetarisch)",
          "MÜLLER Reformhaus - St Gallen")


# 3. Set up TGTG client, load newest data and set the offers by email ----

client = tgtg$TgtgClient(email="k.lichtsteiner@hotmail.com", password="a782nlfsklFFF!!.fsdfsd", 
                         user_agent = "TooGoodToGo/21.9.3 (541) (iPhone/iPhone 7 (GSM); iOS 13.6; Scale/2.00)")



while (TRUE == TRUE) {
  t_current = get_t_current(client, augen)
  print(t_current)
  Sys.sleep(300)
}                             
