from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

def sendingMail (subject, body, From, to):
  msg = MIMEMultipart("alternative")
  msg["Subject"] = subject
  msg["From"] = From
  msg["To"] = to
  part1 = MIMEText(body,
                 "plain", "utf-8")
  msg.attach(part1)
  return(msg)

