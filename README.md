# Self-Hosted Vaultwarden with Traefik, DuckDNS, Let's Encrypt and Ngrok

```markdown
> Austin.Lai |
> -----------| September 22nd, 2023
> -----------| Updated on September 25th, 2023
```

---

## Table of Contents

<!-- TOC -->

- [Self-Hosted Vaultwarden with Traefik, DuckDNS, Let's Encrypt and Ngrok](#self-hosted-vaultwarden-with-traefik-duckdns-lets-encrypt-and-ngrok)
    - [Table of Contents](#table-of-contents)
    - [Disclaimer](#disclaimer)
    - [Description](#description)
    - [Pre-requisites for this setup](#pre-requisites-for-this-setup)
        - [WSL Configuration](#wsl-configuration)
        - [DuckDNS Configuration](#duckdns-configuration)
        - [Windows Host file](#windows-host-file)
        - [Prepare and create acme.json file](#prepare-and-create-acmejson-file)
        - [vaultwarden docker compose file](#vaultwarden-docker-compose-file)
        - [NGROK Account](#ngrok-account)
        - [ngrok docker compose file](#ngrok-docker-compose-file)
        - [env file](#env-file)
        - [init.sh file](#initsh-file)
        - [init.py file](#initpy-file)

<!-- /TOC -->

<br>

## Disclaimer

<span style="color: red; font-weight: bold;">DISCLAIMER:</span>

This project/repository is provided "as is" and without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

This project/repository is for <span style="color: red; font-weight: bold;">Educational</span> purpose <span style="color: red; font-weight: bold;">ONLY</span>. Do not use it without permission. The usual disclaimer applies, especially the fact that me (Austin) is not liable for any damages caused by direct or indirect use of the information or functionality provided by these programs. The author or any Internet provider bears NO responsibility for content or misuse of these programs or any derivatives thereof. By using these programs you accept the fact that any damage (data loss, system crash, system compromise, etc.) caused by the use of these programs is not Austin responsibility.

<br>

## Description

<!-- Description -->

This project/repository is a local setup of <span style="color: red; font-weight: bold;">self-hosted vaultwarden with traefik (that using duckdns and let's encrypt) and ngrok</span>.

<span style="color: orange; font-weight: bold;">Note:</span>

- The configurations in this project/repository are for your reference ONLY (the reasons are as follows):
    - The setup is hosted in <span style="color: green; font-weight: bold;">docker container</span> environment, leveraging <span style="color: green; font-weight: bold;">WSL</span> on a <span style="color: green; font-weight: bold;">Windows</span> host.
    - The main reason for using <span style="color: green; font-weight: bold;">WSL</span> instead of deploying the <span style="color: green; font-weight: bold;">docker container</span> directly using Windows is due to the `acme.json` file permission issue that is used by <span style="color: green; font-weight: bold;">Let's Encrypt</span> in <span style="color: green; font-weight: bold;">Traefik</span>, causing an error.
    - You can register a free subdomain with <span style="color: green; font-weight: bold;">DuckDNS</span> just for the purpose of getting a certificate signed by <span style="color: green; font-weight: bold;">Let's Encrypt</span>.
    - However, there is no need to change the DNS configuration in your firewall or home router since this setup is purely hosted locally. If there is a need to access <span style="color: green; font-weight: bold;">vaulwarden publicly</span>, that's where the <span style="color: green; font-weight: bold;">Ngrok</span> service will be spinning up.
    - This setup has two separate docker compose files:
        - One for <span style="color: green; font-weight: bold;">ngrok (ngrok-docker-compose.yml)</span>.
        - One for <span style="color: green; font-weight: bold;">vaultwarden & traefik (vaultwarden-docker-compose.yml)</span>.
    - Please change the configuration accordingly to suits your hosting environment.

<!-- /Description -->

<br>

This project/repository has the following files and directories in the structure as below:

- Directories

    ```bash
    .
    ├── assets
    │   └── images
    ├── images
    ├── ngrok
    ├── traefik
    │   └── traefik-config
    └── vaultwarden
    ```

- All files and directories

    ```
    .
    ├── assets
    │   └── images
    ├── images
    ├── ngrok
    │   ├── ngrok.log
    │   └── ngrok.yml
    ├── traefik
    │   └── traefik-config
    │       ├── acme.json
    │       └── config.yml
    ├── vaultwarden
    ├── .env
    ├── init.sh
    ├── LICENSE.md
    ├── ngrok-docker-compose.yml
    ├── README.md
    ├── vaultwarden-docker-compose.yml
    └── wsl.conf
    ```

<!-- /Description -->

<br>

## Pre-requisites for this setup

### WSL Configuration

<span style="color: orange; font-weight: bold;">ATTENTION:</span>

- The CONFIG FILE should place in `/etc/wsl.conf`.
- It is required by any distro of WSL to get the correct `acme.json` file permission.
- Remember to enable docker support for WSL.
- <span style="color: red; font-weight: bold;">Please change the "YOUR_WSL_USER" !!!</span>

The `wsl.conf` file can be found [here](./wsl.conf) or below:

```conf
# Automatically mount Windows drive when the distribution is launched
[automount]

# Set to true will automount fixed drives (C:/ or D:/) with DrvFs under the root directory set above. Set to false means drives won't be mounted automatically, but need to be mounted manually or with fstab.
enabled = true

# DrvFs-specific options can be specified.
options = "umask=077,case=off"



# Set the user when launching a distribution with WSL.
[user]
# CHANGE HERE !!!
default = YOUR_WSL_USER
```

<br>

### DuckDNS Configuration

1. Go to DuckDNS website and sign-up/login
2. Add your domain
3. Note down the FQDN

<br>

### Windows Host file

Add a DNS entry in Windows host file located in `C:\Windows\System32\drivers\etc`.

The IP can be any interface or IP even localhost on Windows host.

Example:

```
# Self-Hosted Vaultwarden with Traefik, DuckDNS, Let's Encrypt and Ngrok
127.0.0.1 traefik.example.duckdns.org vaultwarden.example.duckdns.org
```

<br>

### Prepare and create `acme.json` file

<span style="color: red; font-weight: bold;">The "acme.json" file must created in WSL environment to ensure the permission is correct.</span>

- In Windows Host, open Command Prompt <span style="color: green; font-weight: bold;">OR</span> Windows Terminal.
- go to the project/repository directory.
- Change to `traefik/traefik-config`.
- Switch to WSL at your preference <span style="color: red; font-weight: bold;">(use the same distro where "wsl.conf" is placed)</span>.
- Use `touch acme.json` command to create the file.
- Then use `chmod 600 acme.json` to change the file permission.

<br>

### vaultwarden docker compose file

The `vaultwarden-docker-compose.yml` file can be found [here](./vaultwarden-docker-compose.yml) or below:

<details>

<summary><span style="padding-left:10px;">Click here to expand for the "vaultwarden-docker-compose.yml" !!!</span>

</summary>

```yml
version: "3.9"

networks:
  example-network:
    name: example-network
    driver: bridge

services:
  vaultwarden:
    image: ${VAULTWARDEN_IMAGE_TAG}
    container_name: ${VAULTWARDEN_CONTAINER_NAME}
    volumes:
      - "./vaultwarden:/data/" # Map the "vaultwarden" directory from Windows host to "/data/" in container.
    environment:
      - ADMIN_TOKEN=${ADMIN_TOKEN} # Disable admin page by not issue any admin token
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_FROM=${SMTP_FROM}
      - SMTP_SECURITY=${SMTP_SECURITY} # The security method used by your SMTP server. Possible values: “starttls” / “force_tls” / “off”.
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USERNAME=${SMTP_USERNAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
      - LOGIN_RATELIMIT_MAX_BURST=10
      - LOGIN_RATELIMIT_SECONDS=60
      - ADMIN_RATELIMIT_MAX_BURST=10
      - ADMIN_RATELIMIT_SECONDS=60
      - SENDS_ALLOWED=${SENDS_ALLOWED} # This setting determines whether users are allowed to create Bitwarden Sends – a form of credential sharing.
      - SIGNUPS_ALLOWED = ${SIGNUPS_ALLOWED} # This setting controls whether or not new users can register for accounts without an invitation. Possible values: true / false. Can change to false to disable anyone create account - for better security
      - SIGNUPS_VERIFY=${SIGNUPS_VERIFY} # This setting determines whether or not new accounts must verify their email address before being able to login to Vaultwarden. Possible values: true / false.
      - SIGNUPS_VERIFY_RESEND_TIME=${SIGNUPS_VERIFY_RESEND_TIME}
      - SIGNUPS_VERIFY_RESEND_LIMIT=${SIGNUPS_VERIFY_RESEND_LIMIT}
      - SIGNUPS_DOMAINS_WHITELIST=${SIGNUPS_DOMAINS_WHITELIST}
      - EMERGENCY_ACCESS_ALLOWED=${EMERGENCY_ACCESS_ALLOWED} # This setting controls whether users can enable emergency access to their accounts. This is useful, for example, so a spouse can access a password vault in the event of death so they can gain access to account credentials. Possible values: true / false.
      - WEBSOCKET_ENABLED=${WEBSOCKET_ENABLED}
      - WEB_VAULT_ENABLED=${WEB_VAULT_ENABLED} # This setting determines whether or not the web vault is accessible. Stopping your container then switching this value to false and restarting Vaultwarden could be useful once you’ve configured your accounts and clients to prevent unauthorized access. Possible values: true/false.
      - DOMAIN=${DOMAIN}
      - LOG_FILE=${LOG_FILE}
      - INVITATIONS_ALLOWED=${INVITATIONS_ALLOWED}
      - SHOW_PASSWORD_HINT=${SHOW_PASSWORD_HINT}
      - PASSWORD_HINTS_ALLOWED=${PASSWORD_HINTS_ALLOWED}
      - PUSH_ENABLED=${PUSH_ENABLED}
      - PUSH_INSTALLATION_ID=${PUSH_INSTALLATION_ID}
      - PUSH_INSTALLATION_KEY=${PUSH_INSTALLATION_KEY}
    restart: ${RESTART_STATUS}
    networks:
      - example-network
    ports:
      - 8880:80
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 90s
    depends_on:
      traefik:
        condition: service_healthy
    security_opt:
      - no-new-privileges:${NO_NEW_PRIVILEGES}
    labels:
      - traefik.enable=${TRAEFIK_ENABLE}
      - traefik.http.routers.vaultwarden.rule=Host(`${VAULTWARDEN_HOSTNAME}`)
      - traefik.http.routers.vaultwarden.service=vaultwarden
      - traefik.http.routers.vaultwarden.entrypoints=websecure
      - traefik.http.services.vaultwarden.loadbalancer.server.port=80
      - traefik.http.routers.vaultwarden.tls=true
      - traefik.http.routers.vaultwarden.tls.certresolver=letsencrypt
      - traefik.http.services.vaultwarden.loadbalancer.passhostheader=true
      - traefik.http.routers.vaultwarden.middlewares=compresstraefik
      - traefik.http.middlewares.compresstraefik.compress=true
      - traefik.docker.network=example-network



  traefik:
    image: ${TRAEFIK_IMAGE_TAG}
    container_name: ${TRAEFIK_CONTAINER_NAME}
    security_opt:
      - no-new-privileges:${NO_NEW_PRIVILEGES}
    restart: ${RESTART_STATUS}
    environment:
      - DUCKDNS_TOKEN=${DUCKDNS_TOKEN}
    command:
      - --log.level=${TRAEFIK_LOG_LEVEL}
      - --accesslog=${ACCESS_LOG}
      - --api.dashboard=${API_DASHBOARD}
      - --api.insecure=${API_INSECURE}
      - --ping=${PING_ENABLED}
      - --ping.entrypoint=${PING_ENTRYPOINT}
      - --entryPoints.ping.address=${ENTRYPOINTS_PING_ADDRESS}
      - --entryPoints.web.address=${ENTRYPOINTS_WEB_ADDRESS}
      - --entryPoints.websecure.address=${ENTRYPOINTS_WEBSECURE_ADDRESS}
      - --providers.docker=${PROVIDERS_DOCKER}
      - --providers.docker.endpoint=unix:///var/run/docker.sock
      - --providers.docker.exposedByDefault=${PROVIDERS_DOCKER_EXPOSEDBYDEFAULT}
      - --certificatesresolvers.letsencrypt.acme.dnschallenge=${CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_DNSCHALLENGE}
      - --certificatesresolvers.letsencrypt.acme.dnschallenge.provider=${DNSCHALLENGE_PROVIDER}
      - --certificatesresolvers.letsencrypt.acme.caserver=${LETSENCRYPT_ACME_CASERVER}
      - --certificatesresolvers.letsencrypt.acme.dnschallenge.resolvers=${LETSENCRYPT_ACME_DNSCHALLENGE_RESOLVERS}
      - --certificatesresolvers.letsencrypt.acme.dnschallenge.delayBeforeCheck=${LETSENCRYPT_ACME_DNSCHALLENGE_DELAYBEFORECHECK}
      - --certificatesresolvers.letsencrypt.acme.email=${TRAEFIK_ACME_EMAIL}
      - --certificatesresolvers.letsencrypt.acme.storage=${LETSENCRYPT_ACME_STORAGE}
      - --global.checkNewVersion=${GLOBAL_CHECKNEWVERSION}
      - --global.sendAnonymousUsage=${GLOBAL_SENDANONYMOUSUSAGE}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/traefik-config/acme.json:/acme.json
      - ./traefik/traefik-config/config.yml:/config.yml:ro
      - ./traefik/logs:/var/log/traefik
    networks:
      - example-network
    ports:
      - 80:80
      - 443:443
    healthcheck:
      test: ["CMD", "wget", "http://localhost:8082/ping","--spider"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s
    labels:
      - traefik.enable=${TRAEFIK_ENABLE}
      - traefik.docker.network=example-network
      - traefik.http.routers.dashboard.rule=Host(`${TRAEFIK_HOSTNAME}`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`)) # Must be /dashboard/ or /api/ only the authentication will happen
      - traefik.http.routers.dashboard.entrypoints=websecure
      - traefik.http.routers.dashboard.service=api@internal
      - traefik.http.routers.dashboard.tls=true
      - traefik.http.routers.dashboard.tls.certresolver=letsencrypt
      - traefik.http.routers.dashboard.middlewares=authtraefik
      - traefik.http.services.dashboard.loadbalancer.server.port=8080
      - traefik.http.services.dashboard.loadbalancer.passhostheader=true
      - traefik.http.middlewares.authtraefik.basicauth.users=${TRAEFIK_BASIC_AUTH}
      - traefik.http.routers.http-catchall.rule=HostRegexp(`{host:.+}`)
      - traefik.http.routers.http-catchall.entrypoints=web
      - traefik.http.routers.http-catchall.middlewares=redirect-to-https
      - traefik.http.routers.traefik-secure.tls.domains[0].main=shbwvwwnat.duckdns.org
      - traefik.http.routers.traefik-secure.tls.domains[0].sans=*.shbwvwwnat.duckdns.org
      - traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https
```

</details>

<span style="color: red; font-weight: bold;">Things to take note:</span>

- <span style="color: green; font-weight: bold;">Please replace the naming of "example-network" to the name you want across the docker compose file and also </span><span style="color: red">in the labels!</span>
- <span style="color: green; font-weight: bold;">Please replace the domain name across the docker compose file </span><span style="color: red">in the labels!</span>

<br>

### NGROK Account

This setup required you to have NGROK Account.

- Go to <https://ngrok.com/>.
- Go to <span style="color: green">"CloudEdge"</span> > <span style="color: green">"Domain"</span>, NGROK given one free domain (subdomain) for the account. Please note down the domain, you will need it later.
- Then go to <span style="color: green">"CloudEdge"</span> > <span style="color: green">"Edges"</span> > <span style="color: green">"Create an edge"</span> (If the edge does not exist)
- Create <span style="color: green">"HTTPS"</span> edge, enabled <span style="color: green">"compression"</span> and leave everything as default.
- Then you will have the option to start a tunnel with config file.
- We need copy the configuration to <span style="color: green">a temporary file that to be used in "/ngrok/ngrok.yml"</span>.

<br>

We provide you a sample of <span style="color: green">"ngrok.yml"</span> [here](./ngrok/ngrok.yml) or you can refer to below:

<details>

<summary><span style="padding-left:10px;">Click here to expand for the "ngrok.yml" !!!</span></summary>

```yml
authtoken: YOUR_AUTHTOKEKN_HERE
connect_timeout: 30s
console_ui: true
console_ui_color: transparent
dns_resolver_ips:
  - 1.1.1.1
  - 8.8.8.8
heartbeat_interval: 1m
heartbeat_tolerance: 5s
inspect_db_size: 50000000 # 50MB
log_level: info
log_format: json
log: /var/log/ngrok.log
metadata: '{"name": "example"}'
version: 2
web_addr: localhost:4040
tunnels:
  shbwvwwnat:
    labels:
      - edge=YOUR_EDGE_NAME
    addr: http://vaultwarden:80
```

</details>

Please REPLACE the following with the configuration from NGROK:

- "name"
- "edge"
- "authtoken"

You cane refer to the official guide:

- <https://ngrok.com/docs/secure-tunnels/ngrok-agent/reference/config/#metadata>
- <https://ngrok.com/docs/api/>

<br>

### ngrok docker compose file

The `ngrok-docker-compose.yml` file can be found [here](./ngrok-docker-compose.yml) or below:

<details>

<summary><span style="padding-left:10px;">Click here to expand for the "ngrok-docker-compose.yml" !!!</span></summary>

```yml
version: "3.9"

networks:
  example-network:
    external: true

services:
  ngrok:
    image: ${NGROK_IMAGE_TAG}
    container_name: ${NGROK_CONTAINER_NAME}
    security_opt:
      - no-new-privileges:${NO_NEW_PRIVILEGES}
    restart: ${RESTART_STATUS}
    command:
      - "start"
      - "--all"
      - "--config"
      - "/etc/ngrok.yml"
    volumes:
      - ./ngrok/ngrok.yml:/etc/ngrok.yml
      - ./ngrok/ngrok.log:/var/log/ngrok.log
    networks:
      - example-network
    ports:
      - 8888:4040
```

</details>

<span style="color: red; font-weight: bold;">Things to take note:</span>

- <span style="color: green; font-weight: bold;">Please replace the naming of "example-network" to the name you want across the docker compose file!</span>

<br>

### .env file

The `.env` file store all the variables and values to be used in `ngrok-docker-compose.yml` and `vaultwarden-docker-compose.yml`.

Change variables in the `.env` to meet your requirements. There is `# CHANGE HERE !!!` in the `.env` shown below to remind you to make the change.

<span style="color: red; font-weight: bold;">Note</span> that the `.env` file should be in the same directory as  `ngrok-docker-compose.yml` and `vaultwarden-docker-compose.yml`.

<br>

The content of `.env` file shown in below:

<details>

<summary><span style="padding-left:10px;">Click here to expand for the ".env" !!!</span></summary>

```sh
# GLOBAL VARIABLES
RESTART_STATUS=always
NO_NEW_PRIVILEGES=true
TRAEFIK_ENABLE=true





# TRAEFIK VARIABLES
TRAEFIK_IMAGE_TAG=traefik:latest
TRAEFIK_CONTAINER_NAME=traefik
TRAEFIK_LOG_LEVEL=WARN
ACCESS_LOG=true
API_DASHBOARD=true
API_INSECURE=true
PING_ENABLED=true
PING_ENTRYPOINT=ping
ENTRYPOINTS_PING_ADDRESS=:8082
ENTRYPOINTS_WEB_ADDRESS=:80
ENTRYPOINTS_WEBSECURE_ADDRESS=:443
PROVIDERS_DOCKER=true
PROVIDERS_DOCKER_EXPOSEDBYDEFAULT=false
CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_DNSCHALLENGE=true
LETSENCRYPT_ACME_CASERVER=https://acme-staging-v02.api.letsencrypt.org/directory # Here's using staging acme, you can change to use production amce!
LETSENCRYPT_ACME_DNSCHALLENGE_RESOLVERS=8.8.8.8:53,8.8.4.4:53
LETSENCRYPT_ACME_DNSCHALLENGE_DELAYBEFORECHECK=5
LETSENCRYPT_ACME_STORAGE=acme.json
GLOBAL_CHECKNEWVERSION=true
GLOBAL_SENDANONYMOUSUSAGE=false
TRAEFIK_ACME_EMAIL=YOU_EMAIL_ADDRESS # CHANGE HERE !!!
TRAEFIK_HOSTNAME=traefik.example.duckdns.org # CHANGE HERE !!!

# Basic Authentication for Traefik Dashboard
# Username/Password: traefikadmin
# Passwords must be encoded using MD5, SHA1, or BCrypt https://hostingcanada.org/htpasswd-generator/
# TRAEFIK_BASIC_AUTH=traefikadmin:$$apr1$$E.Kk5hS/$$f4paP0Qa.WOjl6jUnQwjQ/
# Or to create own user pass
# htpasswd -nb traefikadmin traefikadmin | sed 's/\$/\$\$/g'
TRAEFIK_BASIC_AUTH=traefikadmin:$$apr1$$E.Kk5hS/$$f4paP0Qa.WOjl6jUnQwjQ/ # CHANGE HERE !!!

DNSCHALLENGE_PROVIDER=duckdns
DUCKDNS_TOKEN=YOUR_DUCKDNS_TOKEN # CHANGE HERE !!!

# VAULTWARDEN VARIABLES
VAULTWARDEN_IMAGE_TAG=vaultwarden/server:latest
VAULTWARDEN_CONTAINER_NAME=vaultwarden
VAULTWARDEN_HOSTNAME=vaultwarden.example.duckdns.org # CHANGE HERE !!!

# You can randomly generated string of characters, for example running "openssl rand -base64 48"
# Or you can run "docker run --rm -it vaultwarden/server /vaultwarden hash"
# OR using command below for Bitwarden defaults
# echo -n "MySecretPassword" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4
# Output: $argon2id$v=19$m=65540,t=3,p=4$NVRsQ08waktkZ0J0VVRKQThiREhNWXdrVjk0dzloSXc5YUFoeHhsNk1wdz0$fAGrOzMNfBSj3qCpmOS5prvp1XCQTjhmC5YQbUqSQcE
# Or using command below for OWASP minimum recommended settings
# echo -n "MySecretPassword" | argon2 "$(openssl rand -base64 32)" -e -id -k 19456 -t 2 -p 1
# Output: $argon2id$v=19$m=19456,t=2,p=1$cXpKdUxHSWhlaUs1QVVsSStkbTRPQVFPSmdpamFCMHdvYjVkWTVKaDdpYz0$E1UgBKjUCD2Roy0jdHAJvXihugpG+N9WcAaR8P6Qn/8
# Need to accomodate the password to docker compose
# echo 'your-authentication-token-here' | sed 's#\$#\$\$#g'
# echo -n "MySecretPassword" | argon2 "$(openssl rand -base64 32)" -e -id -k 19456 -t 2 -p 1 | sed 's#\$#\$\$#g'
ADMIN_TOKEN=$$argon2id$$v=19$$m=19456,t=2,p=1$$alZDVUc0RTNkQm9IUldSTW5BWkxrLzJnVUFMODJXVmJpcnl1OHpTYmVaMD0$$VlpfMyvDcdmfdTad705HNgOdeEs6SkQE+up8XTC/Sfk # CHANGE HERE !!!

SMTP_HOST=smtp.gmail.com # CHANGE HERE !!!
SMTP_FROM=vaultwarden@vaultwarden.example.duckdns.org # CHANGE HERE !!!
SMTP_SECURITY=starttls # CHANGE HERE !!!
SMTP_PORT=587 # CHANGE HERE !!!
SMTP_USERNAME=YOUR_EMAIL_ADDRESS # CHANGE HERE !!!

# Go to Google Account > Security > 2FA > Generate App Password
SMTP_PASSWORD=YOUR_SMTP_PASSWORD # CHANGE HERE !!!
SENDS_ALLOWED=false
SIGNUPS_ALLOWED=false
SIGNUPS_VERIFY=true
SIGNUPS_VERIFY_RESEND_TIME=3600
SIGNUPS_VERIFY_RESEND_LIMIT=5
SIGNUPS_DOMAINS_WHITELIST=example.com # CHANGE HERE !!!
EMERGENCY_ACCESS_ALLOWED=false
WEBSOCKET_ENABLED=true
WEB_VAULT_ENABLED=true
DOMAIN=https://vaultwarden.example.duckdns.org # CHANGE HERE !!!
LOG_FILE=/data/bitwarden.log
INVITATIONS_ALLOWED=false
SHOW_PASSWORD_HINT=false
PASSWORD_HINTS_ALLOWED=false
PUSH_ENABLED=true

# Go to https://bitwarden.com/host/ to request PUSH_INSTALLATION_ID and PUSH_INSTALLATION_KEY
PUSH_INSTALLATION_ID=YOUR_PUSH_INSTALLATION_ID # CHANGE HERE !!!
PUSH_INSTALLATION_KEY=YOUR_PUSH_INSTALLATION_KEY # CHANGE HERE !!!





# NGROK VARIABLES
NGROK_IMAGE_TAG=ngrok/ngrok:latest
NGROK_CONTAINER_NAME=ngrok
```

</details>

<br>

### init.sh file

`init.sh` is a helper script for you to manage vaultwarden, traefik and ngrok docker container.

The script will START or STOP the container specified in the selected docker compose file based on various condition to avoid configuration or accessibility error.

The script description and usage as shown below:

```text
Description:
      This is a helper script for managing Docker containers.
      This script will START or STOP the container specified in the selected docker compose file
Usage:
      ./init.sh [file] [command]
Options:
     file:  The Docker compose file to use (vaultwarden, ngrok)
                *vaultwarden - Start Vaultwarden container using ./vaultwarden-docker-compose.yml
                *ngrok - Start Ngrok container using ./ngrok-docker-compose.yml
  command:  The command to execute (up, down)
                *up - docker compose -f [file] up --timestamps --wait --detach
                *down - docker compose -f [file] down
       -h:  Display this help message (--help, /?)
```

<span style="color: red; font-weight: bold;">Please note that:</span>

- IN WINDOWS HOST
- I HAVE CREATE DOSKEY AS SHOWN BELOW; SO IT CAN RUN THIS SCRIPT FROM COMMAND PROMPT BY LEVERAGING WSL !!!

  ```doskey
  vaultwarden=wsl bash -c "cd /mnt/YOUR_WINDOWS_C_OR_D_DRIVE/THE_PROJECT_REPO_FOLDER && ./init.sh $*" 
  ```

- <span style="color: red; font-weight: bold;">Note</span> that the `init.sh` file should be in the same directory as  `ngrok-docker-compose.yml` and `vaultwarden-docker-compose.yml`.

<br>

The `init.sh` file can be found [here](./init.sh) or below:

<details>

<summary><span style="padding-left:10px;">Click here to expand for the "init.sh" !!!</span></summary>

```sh
#!/bin/bash

display_help() {
  echo "Description:"
  echo "      This is a helper script for managing Docker containers."
  echo "      This script will START or STOP the container specified in the selected docker compose file"
  echo "Usage:"
  echo "      $0 [file] [command]"
  echo "Options:"
  echo "     file:  The Docker compose file to use (vaultwarden, ngrok)"
  echo "                *vaultwarden - Start Vaultwarden container using $vaultwarden_path"
  echo "                *ngrok - Start Ngrok container using $ngrok_path"
  echo "  command:  The command to execute (up, down)"
  echo "                *up - docker compose -f [file] up --timestamps --wait --detach"
  echo "                *down - docker compose -f [file] down"
  echo "       -h:  Display this help message (--help, /?)"
}

# Define docker compose files
vaultwarden="vaultwarden-docker-compose.yml"
ngrok="ngrok-docker-compose.yml"

# Get the current path of the script
script_path=$(dirname "$0")

# Append the current path to the docker compose files
vaultwarden_path="$script_path/$vaultwarden"
ngrok_path="$script_path/$ngrok"

# Set valid_arg1 to false as default arg1 or $1 is not exist
valid_arg1="no"

# Check for command line arguments
if [ -z "$1" ]; then
  arg1="-h"
else
  arg1="$1"
fi

# Display help message
if [ "$arg1" = "/?" ] || [ "$arg1" = "-h" ] || [ "$arg1" = "--help" ]; then
  display_help
  exit 0
fi

# Capture Ctrl+C and exit
trap "exit 1" INT

# Allow user to select which file to use
case "$arg1" in
  vaultwarden)
    selected_file="$vaultwarden_path"
    valid_arg1="yes"
    ;;
  ngrok)
    selected_file="$ngrok_path"
    valid_arg1="yes"
    ;;
  *)
    echo
    echo "Error: Invalid input. Please select a valid file."
    echo
    display_help
    exit 1
    ;;
esac

# Allow user to select which file to use
# Only proceed if there is a valid first argument!
if [ "$valid_arg1" = "yes" ]; then

  # Check if second argument exists, if not display error and help message
  if [ -z "$2" ]; then
    echo
    echo "Error: Missing second option/argument."
    echo
    display_help
    exit 1
  else
    case "$2" in
      up)
        if [ "$arg1" = "vaultwarden" ]; then
          container_id=$(docker ps -qf "name=^/$arg1$")
          if [ -n "$container_id" ]; then
            echo "The $arg1 container is already running!"
          else
            echo "The $arg1 container is not running."
            docker compose -f "$selected_file" up --timestamps --wait --detach 
          fi 
        elif [ "$arg1" = "ngrok" ]; then 
          container_id=$(docker ps -qf "name=^/$arg1$")
          if [ -n "$container_id" ]; then 
            echo "The $arg1 container is already running!"
          else 
            echo "The $arg1 container is not running."
            # If the first argument is "ngrok".
            # Check if vaultwarden container is runing.
            # Since ngrok need to attach to the same docker 
            # network as vaultwarden container.
            vaultwarden_container_id=$(docker ps -qf "name=vaultwarden")
            if [ -n "$vaultwarden_container_id" ]; then 
              echo "The vaultwarden container is running!"
              docker compose -f "$selected_file" up --timestamps --wait --detach 
            else 
              echo "The vaultwarden container is not running."
              echo "Will not proceed to start ngrok container."
              echo "Please ensure vaultwarden container is running first."
              echo "Since ngrok need to attach to the same docker network as vaultwarden container."
            fi 
          fi 
        fi 
        ;;
      down)
        if [ "$arg1" = "vaultwarden" ]; then 
          ngrok_container_id=$(docker ps -qf "name=ngrok")
          if [ -n "$ngrok_container_id" ]; then 
            echo "The ngrok container is running!"
            echo "Will not proceed to stop vaultwarden container."
            echo "Please ensure ngrok container is not running first."
            echo "Since ngrok is attach to the same docker network as vaultwarden container." 
          else 
            echo "The ngrok container is not running."
            docker compose -f "$selected_file" down 
          fi 
        elif [ "$arg1" = "ngrok" ]; then 
          docker compose -f "$selected_file" down 
        fi 
        ;;
      *)
        echo 
        echo "Error: Invalid option/argument. Please select a valid option/argument."
        echo 
        display_help
        exit 1
        ;;
    esac  
  fi  
fi
```

</details>

<br>

### init.py file

`init.py` is a python helper script for you to manage vaultwarden, traefik and ngrok docker container.

The script will START or STOP the container specified in the selected docker compose file based on various condition to avoid configuration or accessibility error.

The script description and usage as shown below:

```text
Description:
     This is a helper script for managing Docker containers.
     This script will START or STOP the container specified in the selected docker compose file.
Usage:
     ./docker_helper.py [file] [command]
Options:
     file: The Docker compose file to use (vaultwarden, ngrok)
               *vaultwarden - Start Vaultwarden container using
                using {vaultwarden_path}.
               *ngrok - Start Ngrok container using
                {ngrok_path}.
  command: The command to execute (up, down)
               *up - docker-compose -f [file] up --timestamps --wait --detach
               *down - docker-compose -f [file] down
       -h: Display this help message (--help, /?)
```

<span style="color: red; font-weight: bold;">Please note that:</span>

- IN WINDOWS HOST
- I HAVE CREATE DOSKEY AS SHOWN BELOW; SO IT CAN RUN THIS SCRIPT FROM COMMAND PROMPT BY LEVERAGING WSL !!!

  ```doskey
  vaultwarden-python=wsl bash -c "cd /mnt/YOUR_WINDOWS_C_OR_D_DRIVE/THE_PROJECT_REPO_FOLDER && ./test.py $*"
  ```

- <span style="color: red; font-weight: bold;">Note</span> that the `init.py` file should be in the same directory as  `ngrok-docker-compose.yml` and `vaultwarden-docker-compose.yml`.

<br>

The `init.py` file can be found [here](./init.py) or below:

<details>

<summary><span style="padding-left:10px;">Click here to expand for the "init.py" !!!</span></summary>

```python
#! /usr/bin/python3

# OR 
#! /usr/bin/env python3

# Description:
#      This is a helper script for managing Docker containers.
#      This script will START or STOP the container specified in the selected docker compose file.

# Usage:
#      ./docker_helper.py [file] [command]

# Options:
#      file: The Docker compose file to use (vaultwarden, ngrok)
#                *vaultwarden - Start Vaultwarden container using
#                 using {vaultwarden_path}.
#                *ngrok - Start Ngrok container using
#                 {ngrok_path}.
#   command: The command to execute (up, down)
#                *up - docker-compose -f [file] up --timestamps --wait --detach
#                *down - docker-compose -f [file] down
#        -h: Display this help message (--help, /?)


import sys
import os
import subprocess
import signal

# Define docker compose files
vaultwarden = "vaultwarden-docker-compose.yml"
ngrok = "ngrok-docker-compose.yml"

# Get the current path of the script
script_path = os.path.dirname(__file__)

# Append the current path to the docker compose files
vaultwarden_path = os.path.join(script_path, vaultwarden)
ngrok_path = os.path.join(script_path, ngrok)


# Define a function to display help message
def display_help():
    print("Description:")
    print("     This is a helper script for managing Docker containers.")
    print("     This script will START or STOP the container specified in the selected docker compose file.")
    print("Usage:")
    print("     ./docker_helper.py [file] [command]")
    print("Options:")
    print("     file: The Docker compose file to use (vaultwarden, ngrok)")
    print("               *vaultwarden - Start Vaultwarden container using")
    print(f"                using {vaultwarden_path}.")
    print("               *ngrok - Start Ngrok container using")
    print(f"                {ngrok_path}.")
    print("  command: The command to execute (up, down)")
    print("               *up - docker-compose -f [file] up --timestamps --wait --detach")
    print("               *down - docker-compose -f [file] down")
    print("       -h: Display this help message (--help, /?)")
    sys.exit(0)


# Define a function to capture Ctrl+C and exit
def signal_handler(signal, frame):
    sys.exit(1)


# Define a function to check if a container is running
def is_container_running(name):
    container_id = subprocess.check_output(
        ["docker", "ps", "-qf", f"name=^/{name}$"]
    ).decode().strip()
    return bool(container_id)


# Define a function to start a container with a selected file
def start_container(file, name):
    print(f"The {name} container is not running.")
    subprocess.run(
        ["docker-compose", "-f", file, "up", "--timestamps",
         "--wait", "--detach"]
    )


# Define a function to stop a container with a selected file
def stop_container(file, name):
    # print(f"The {name} container is running!")
    subprocess.run(
        ["docker-compose", "-f", file, "down"]
    )


# Define a function to prompt user enter yes or no for confirmation of next action
def yes_or_no():
    while True:
        answer = input("Would you like to continue? ('yes|y|Yes|Y|YES' or 'no|n|No|N|N'): ").lower()
        if answer in ["yes", "y", "Yes", "Y", "YES"]:
            return True
        elif answer in ["no", "n", "No", "N", "NO"]:
            return False
        else:
            print("Invalid input. Please enter 'yes|y|Yes|Y|YES' or 'no|n|No|N|N'.")


# Set valid_arg1 to False as default arg1 or sys.argv[1] is not exist
valid_arg1 = False

# Check for command line arguments
if len(sys.argv) < 2:
    arg1 = "-h"
else:
    arg1 = sys.argv[1]

# Display help message
if arg1 in ["/?", "-h", "--help"]:
    display_help()

# Capture Ctrl+C and exit
signal.signal(signal.SIGINT, signal_handler)

# Allow user to select which file to use
if arg1 == "vaultwarden":
    selected_file = vaultwarden_path
    valid_arg1 = True
elif arg1 == "ngrok":
    selected_file = ngrok_path
    valid_arg1 = True
else:
    print()
    print("Error: Invalid input. Please select a valid file.")
    print()
    display_help()
    sys.exit(1)

# Only proceed if there is a valid first argument!
if valid_arg1:
    # Check if second argument exists, if not display error and help
    # message
    if len(sys.argv) < 3:
        print()
        print("Error: Missing second option/argument.")
        print()
        display_help()
        sys.exit(1)
    else:
        arg2 = sys.argv[2]
        # Execute the command based on the second argument
        if arg2 == "up":
            if arg1 == "vaultwarden":
                # Check if vaultwarden container is already running
                if is_container_running("vaultwarden"):
                    # If yes, do nothing and inform the user
                    print(f"The {arg1} container is already running!")
                else:
                    # If no, start the vaultwarden container with the
                    # selected file
                    start_container(selected_file, arg1)
            elif arg1 == "ngrok":
                # Check if ngrok container is already running
                if is_container_running("ngrok"):
                    # If yes, do nothing and inform the user
                    print(f"The {arg1} container is already running!")
                else:
                    # If no, check if vaultwarden container is running
                    # Since ngrok need to attach to the same docker
                    # network as vaultwarden container
                    if is_container_running("vaultwarden"):
                        # If yes, start the ngrok container with the
                        # selected file
                        print("The vaultwarden container is running!")
                        start_container(selected_file, arg1)
                    else:
                        # If no, do not start the ngrok container and
                        # inform the user
                        print("The vaultwarden container is not running.")
                        print("Will not proceed to start ngrok container.")
                        print("Please ensure vaultwarden container is running first.")
                        print("Since ngrok need to attach to the same docker network as vaultwarden container.")
        elif arg2 == "down":
            if arg1 == "vaultwarden":
                # Check if ngrok container is running
                # Since ngrok is attached to the same docker network as vaultwarden container
                if is_container_running("ngrok"):
                    # If yes, do not stop the vaultwarden container and inform the user
                    print("The ngrok container is running!")
                    print("Will not proceed to stop vaultwarden container.")
                    print("Please ensure ngrok container is not running first.")
                    print("Since ngrok is attached to the same docker network as vaultwarden container.")
                elif is_container_running("vaultwarden"):
                    # If yes, stop the vaultwarden container with the selected file
                    print("The vaultwarden container is running!")
                    if yes_or_no():
                        stop_container(selected_file, arg1)
                else:
                    print("The vaultwarden container is not running!")
            elif arg1 == "ngrok":
                # Check if ngrok container is running
                if is_container_running("ngrok"):
                    # If yes, stop the ngrok container with the selected file and inform the user
                    print("The ngrok container is running!")
                    stop_container(selected_file, arg1)
                else:
                    print("The ngrok container is not running!")
        else:
            # Display error and help message if invalid second argument
            print()
            print("Error: Invalid option/argument. Please select a valid option/argument.")
            print()
            display_help()
            sys.exit(1)
```

</details>

<br>

<br>









