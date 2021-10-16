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

os <- import("os")
use_python("/usr/local/bin/python3")

my_python_packages = c("smtplib", "tgtg", "emails", "schedule")

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

source("/../R/get_t_current.R")
source("R/sending_email.R")


# 2. Define the Offers and stores, which should be observed ----

augen = c("Geschmackslokal", "Café Goldkind", "Franz", 
          "Schiffchuchi", "Brezelkönig", "Migros", "dean&david",
          "tibits - St. Gallen  (vegan)", "tibits - St. Gallen  (vegetarisch)")


# 3. Set up TGTG client, load newest data and set the offers by email ----

client = tgtg$TgtgClient(email="k.lichtsteiner@hotmail.com", password="a782nlfsklFFF!!.fsdfsd")

while (TRUE == TRUE) {
  t_current = get_t_current(client, augen)
  print(t_current)
  Sys.sleep(10)
}                             
