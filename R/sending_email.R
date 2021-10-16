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
  
  source_python('R/sendingMail.py')
  
  # create a html table of the body
  
  body = t_current %>% 
    select(-Zeit) %>% 
    htmlTable()
  
  message = sendingMail(subject = s_temp, body = body, From = gmail_user, to = to_mail)
  
  smtpObj = smtplib$SMTP_SSL('smtp.gmail.com', port = "465")
  smtpObj$ehlo()
  smtpObj$login(gmail_user, gmail_password)
  smtpObj$sendmail(gmail_user, to, message$as_string())
  smtpObj$quit()
  
}
