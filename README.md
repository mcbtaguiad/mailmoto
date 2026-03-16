```
                            ███  ████                            █████            
                           ░░░  ░░███                           ░░███             
 █████████████    ██████   ████  ░███  █████████████    ██████  ███████    ██████ 
░░███░░███░░███  ░░░░░███ ░░███  ░███ ░░███░░███░░███  ███░░███░░░███░    ███░░███
 ░███ ░███ ░███   ███████  ░███  ░███  ░███ ░███ ░███ ░███ ░███  ░███    ░███ ░███
 ░███ ░███ ░███  ███░░███  ░███  ░███  ░███ ░███ ░███ ░███ ░███  ░███ ███░███ ░███
 █████░███ █████░░████████ █████ █████ █████░███ █████░░██████   ░░█████ ░░██████ 
░░░░░ ░░░ ░░░░░  ░░░░░░░░ ░░░░░ ░░░░░ ░░░░░ ░░░ ░░░░░  ░░░░░░     ░░░░░   ░░░░░░  

Author: Mark Taguiad <marktaguiad@marktaguaid.dev>
Site: https://marktaguiad.dev
```
This is not a replacement to your production email server solution, this was created as a solution for my low spec edge server (VPS with 1 core and 1gb ram). This sit comforably consumming 30mb RAM and low CPU utilization - on low volume of mails. 

### Quick Start
Use this compose.yml. Edit `environment`, put your domain. Make sure you have a valid TLS Certificate mounted. 
```yaml
services:
  mailmoto:
    container_name: mailmoto
    image: ghcr.io/mcbtaguiad/mailmoto:main
    build:
        context: .
        dockerfile: Dockerfile
    environment:
      MAIL_HOSTNAME: mail.marktaguiad.dev
      MAIL_DOMAIN: marktaguiad.dev
      RSPAMD_ENABLE: true
    volumes:
      - ./tls/fullchain.pem:/data/tls/fullchain.pem
      - ./tls/privkey.pem:/data/tls/privkey.pem
      - ./data:/data
      # - ./log/mail.log:/var/log/mail.log
    ports:
      - "25:25"
      - "587:587"
      - "465:465"
      - "143:143"
      - "993:993" 

    restart: always
    healthcheck:
      test:
        - CMD
        - nc
        - -z
        - localhost
        - "25"
      interval: 30s
      timeout: 5s
      retries: 3
    logging:
      driver: json-file
      options:
        max-size: 10m
        max-file: "3"
```
Deploy.
```bash
docker compose up -d
```
### DNS
Add mail record to you DNS Record.
```
mail    IN    A     <your_ip>
mx1     IN    A     <your_ip> 
<yourdomain>    IN      MX      mail.<yourdomain> 
<yourdomain>    IN      TXT     "v=spf1 mx ~all"
```
### Rspamd or Spamassassin
If you enable `RSPAMD_ENABLE: true`, this will disable Spamassassin, Opendkim, Opendmarc and Postgrey. Rspamd by default has module for dkim and dmarc. I also recommend `Rspamd` as it is a more modern solution to spams.

### DKIM
Dkim is created after you run the compose file, make sure to mount `/data`. 

Navigate to `/data/dkim/<yourdomain>/`, you'll find *mail.txt* and *mail.private*. 

Example.
```
mail._domainkey	IN	TXT	( "v=DKIM1; h=sha256; k=rsa; "
	 "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCz85kQp9hUUn4ybRoJ/7Fg7YT6Z6mj57LY/t5b/VEvWav6Y0oWahx/GM0UOJUJJa/4YGA4KGo+z8x14S3Mkz3YzUmqIBRAD02cizHh2U3F2IzsADyRkjc/XYpsxQtK1pgdvIQiiofkPCaT2mey2CyFWXCQfZm8FmGcRLJyBAPKbwIDAQAB" )  ; ----- DKIM key mail for marktaguiad.dev
```
Add the content of mail.txt to your DNS Record.

### DMARC
Check this [post](https://easydmarc.com/blog/dmarc-step-by-step-guide/) for more explanation and setup. 

Example.
```
_dmarc IN	TXT	( "v=DMARC1; p=quarantine; ruf=mailto:dmarc-report@marktaguiad.dev; rua=mailto:dmarc-report@marktaguiad.dev" )
```
### User Create/ModifyDelete
Exec to the the container and run `mailmoto` to create, modify or delete email user.
```bash
docker exec -it mailmoto bash
./mailmoto
MailMoTo Usage:
./mailmoto create email password
./mailmoto passwd email password
./mailmoto delete email

```
Or.
```bash
docker exec -it mailmoto ./mailmoto
MailMoTo Usage:
./mailmoto create email password
./mailmoto passwd email password
./mailmoto delete email
```

Example.
```bash
docker exec -it mailmoto ./mailmoto create user@marktaguiad.dev AstrongPassword123!
Creating mailbox user@marktaguiad.dev
User created: user@marktaguiad.dev
```
### Logging
You can mount `/var/log/mail.log` if you plan to use `fail2ban`. If not just simply use docker stdout. 

If the container failed to start, make sure *mail.log* exist on the host - if mounted. 

### Testing
Send email to gmail, if your email server or IP is reputable it would be received by gmail. Click on your message and click on `show original`. SPF, DKIM and DMARC should show 'PASS'. Reply and send, if spamassassin or rspamd is working then you would received the email from gmail. 
