<<<<<<< HEAD
# AI Project: LLM-Based System

This repository contains the configuration and setup for an AI system powered by a Large Language Model (LLM). The project uses Docker Compose and integrates Open-WebUI for the user interface, Qdrant for vector storage, Ollama for LLM execution, and Caddy as a reverse proxy. It also supports LDAP authentication, automated backups, and concurrency management for 50–60 simultaneous users.

## Features
- **Web Interface**: Open-WebUI for a user-friendly interaction with LLM
- **Vector Database**: Qdrant for efficient RAG (Retrieval-Augmented Generation)
- **LLM Engine**: Ollama with configurable concurrency
- **Reverse Proxy**: Caddy for HTTPS management
- **Authentication**: LDAP integration with Active Directory
- **Backups**: Automated daily backups with systemd
- **Scalability**: Nginx load balancer and optimized settings for high traffic
----------------------------------------------------------------------
## Setup Instructions
1.Server Preparation and Docker Installation
Update your Ubuntu server and install essential tools:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git software-properties-common
----------------------------------------------------------------------
2.Install Docker and Docker Compose:
 # Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
----------------------------------------------------------------------
# Install Docker Compose
DOCKER_COMPOSE_VERSION=2.18.1
sudo curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

 ----------------------------------------------------------------------
Notes:

    Ensure your server has at least 16GB RAM and 50GB free disk space for smooth operation.
   After installation, log out and log back in to apply Docker group changes.
 
 3.Directory Structure and Permissions

Create dedicated directories for each service under `/mnt/docker-data/volumes/`.  
This ensures data persistence across container restarts and avoids permission issues.

Run the following commands as **root**:
----------------------------------------------------------------------
```bash
# Create directories for all services
sudo mkdir -p /mnt/docker-data/volumes/deepseek-rag_open-webui-storage/_data
sudo mkdir -p /mnt/docker-data/volumes/deepseek-rag_open-webui-data/_data
sudo mkdir -p /mnt/docker-data/volumes/deepseek-rag_qdrant/_data
sudo mkdir -p /mnt/docker-data/volumes/deepseek-rag_ollama/_data
sudo mkdir -p /mnt/docker-data/volumes/deepseek-rag_caddy_data/_data
sudo mkdir -p /mnt/docker-data/volumes/deepseek-rag_caddy_config/_data
----------------------------------------------------------------------
# Set ownership: Open-WebUI runs inside the container with uid=1000
sudo chown -R 1000:1000 /mnt/docker-data/volumes/deepseek-rag_open-webui-storage/_data
sudo chown -R 1000:1000 /mnt/docker-data/volumes/deepseek-rag_open-webui-data/_data
----------------------------------------------------------------------
# Other volumes default to root ownership
sudo chown -R root:root /mnt/docker-data/volumes/deepseek-rag_qdrant/_data
sudo chown -R root:root /mnt/docker-data/volumes/deepseek-rag_ollama/_data
sudo chown -R root:root /mnt/docker-data/volumes/deepseek-rag_caddy_data/_data
sudo chown -R root:root /mnt/docker-data/volumes/deepseek-rag_caddy_config/_data

# Apply secure permissions
sudo chmod -R 750 /mnt/docker-data/volumes
----------------------------------------------------------------------
Notes:

Open-WebUI runs with uid=1000 inside the container, so its volumes are owned by 1000:1000 to prevent write permission errors.

Qdrant, Ollama, and Caddy volumes are set to root:root. If any of these services require a different UID later, adjust ownership with chown accordingly.
----------------------------------------------------------------------
4.Project Directory and Configuration Files

Create the main project directory under `/root` and move into it:

```bash
cd /root
mkdir -p /root/deepseek-rag
cd /root/deepseek-rag
----------------------------------------------------------------------
Notes:Inside this folder, you will place all configuration files, including:

.env → environment variables (LDAP, domain, ports, etc.)

docker-compose.yml → container definitions and volume mappings

systemd/ → backup and timer units

Any additional config files required by Open-WebUI, Qdrant, or Caddy
----------------------------------------------------------------------
5.Docker Compose Configuration

Create the file `/root/deepseek-rag/docker-compose.yml` with the following content:

```yaml
version: "3.8"

services:

  caddy:
    image: caddy:2.10.2
    container_name: deepseek-rag-caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - deepseek-rag_caddy_data:/data
      - deepseek-rag_caddy_config:/config
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
    networks:
      - ai-net

  ollama:
    image: ollama/ollama:latest
    container_name: deepseek-rag-ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - deepseek-rag_ollama:/root/.ollama
    networks:
      - ai-net

  ollama-lb:
    image: nginx:alpine
    container_name: deepseek-rag-ollama-lb
    restart: unless-stopped
    depends_on:
      - ollama
    volumes:
      - ./ollama-lb.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - ai-net

  qdrant:
    image: qdrant/qdrant:v1.11.0
    container_name: deepseek-rag-qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - deepseek-rag_qdrant:/qdrant/storage
    networks:
      - ai-net

  open-webui:
    image: ghcr.io/open-webui/open-webui:latest
    container_name: open-webui
    restart: unless-stopped
    depends_on:
      - ollama-lb
      - qdrant
    ports:
      - "8080:8080"
    environment:
      - TZ=Asia/Tehran
      - WEB_DOMAIN=${WEB_DOMAIN}
      - WEBUI_URL=${WEBUI_URL}
      - ENABLE_PERSISTENT_CONFIG=True
      - ENABLE_LOGIN_FORM=False
      - ENABLE_LDAP=true
      - LDAP_SERVER_LABEL=ActiveDirectory
      - LDAP_SERVER_HOST=${LDAP_SERVER_HOST}
      - LDAP_SERVER_PORT=${LDAP_SERVER_PORT}
      - LDAP_USE_TLS=${LDAP_USE_TLS}
      - LDAP_VALIDATE_CERT=${LDAP_VALIDATE_CERT}
      - LDAP_APP_DN=${LDAP_APP_DN}
      - LDAP_APP_PASSWORD=${LDAP_APP_PASSWORD}
      - LDAP_SEARCH_BASE=${LDAP_SEARCH_BASE}
      - LDAP_ATTRIBUTE_FOR_USERNAME=${LDAP_ATTRIBUTE_FOR_USERNAME}
      - LDAP_ATTRIBUTE_FOR_MAIL=${LDAP_ATTRIBUTE_FOR_MAIL}
      - LDAP_SEARCH_FILTER=${LDAP_SEARCH_FILTER}
      - OLLAMA_BASE_URL=http://ollama-lb:11434
      - QDRANT_URI=http://qdrant:6333
      - QDRANT_COLLECTION=webui_rag
      - OLLAMA_NUM_PARALLEL=1
      - THREAD_POOL_SIZE=80
      - ENABLE_PERSISTENT_CONFIG=True
    volumes:
      - deepseek-rag_open-webui-storage:/app/backend/storage
      - deepseek-rag_open-webui-data:/app/backend/data
    networks:
      - ai-net

networks:
  ai-net:
    driver: bridge

volumes:
  deepseek-rag_open-webui-storage:
    driver: local
    driver_opts:
      type: none
      device: /mnt/docker-data/volumes/deepseek-rag_open-webui-storage/_data
      o: bind
  deepseek-rag_open-webui-data:
    driver: local
    driver_opts:
      type: none
      device: /mnt/docker-data/volumes/deepseek-rag_open-webui-data/_data
      o: bind
  deepseek-rag_qdrant:
    driver: local
    driver_opts:
      type: none
      device: /mnt/docker-data/volumes/deepseek-rag_qdrant/_data
      o: bind
  deepseek-rag_ollama:
    driver: local
    driver_opts:
      type: none
      device: /mnt/docker-data/volumes/deepseek-rag_ollama/_data
      o: bind
  deepseek-rag_caddy_data:
    driver: local
    driver_opts:
      type: none
      device: /mnt/docker-data/volumes/deepseek-rag_caddy_data/_data
      o: bind
  deepseek-rag_caddy_config:
    driver: local
    driver_opts:
      type: none
      device: /mnt/docker-data/volumes/deepseek-rag_caddy_config/_data
      o: bind

Notes:

    We separated two volumes for Open-WebUI:

        open-webui-storage → stores .webui_secret_key and persistent config files

        open-webui-data → stores webui.db, cache, uploads, and vector database

    All sensitive values (WEB_DOMAIN, LDAP credentials, etc.) are now referenced from .env.

----------------------------------------------------------------------
6.Caddy Configuration (HTTPS for Internal Network)

Create the file `/root/deepseek-rag/Caddyfile` with the following content:

```caddy
# Caddy: internal CA -> suitable for internal network usage
${WEB_DOMAIN} {
    encode gzip

    reverse_proxy /ollama/* ollama:11434 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
    }

    reverse_proxy /* open-webui:8080 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
    }

    tls internal
}
----------------------------------------------------------------------
Notes:

    ${WEB_DOMAIN} should match your internal domain (e.g. ai.example.local).

    tls internal makes Caddy generate a local CA and issue certificates automatically.

    To avoid browser warnings, add Caddy’s CA certificate to your organization’s trust store (or to each client machine).

    If your organization already has its own internal CA, replace the last line with:

    tls /path/to/your-cert.crt /path/to/your-cert.key
----------------------------------------------------------------------
7.Ollama Load Balancer Configuration (Nginx + Rate Limit)

Create the file at:
/root/deepseek-rag/ollama-lb.conf

File Content
server {
    listen 11434;
    server_name ollama-lb;

    # Simple connection limiting - adjust limits for production
    limit_conn_zone $binary_remote_addr zone=addr:10m;
    limit_conn addr 50;

    location / {
        proxy_pass http://ollama:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_buffering off;
    }
}
----------------------------------------------------------------------
Notes:

listen 11434; → Nginx listens on port 11434, same as the Ollama service.

limit_conn_zone and limit_conn → restrict each client IP to 50 simultaneous connections to prevent overload.

proxy_pass http://ollama:11434; → forwards requests to the Ollama container defined in Docker Compose.

Currently, this LB is simple with a single upstream.

If you want to run multiple Ollama instances in the future, you can define an upstream block and distribute load across them.

----------------------------------------------------------------------
8.Environment Variables (.env)

Create the file at:
/root/deepseek-rag/.env

Confhguration .env

# Open WebUI
WEB_DOMAIN=your.internal.domain           # e.g., ai.example.local
WEBUI_URL=https://your.internal.domain
ENABLE_PERSISTENT_CONFIG=True
ENABLE_LOGIN_FORM=False
THREAD_POOL_SIZE=80
OLLAMA_BASE_URL=http://ollama-lb:11434
ENABLE_LDAP=true

# LDAP Configuration (replace placeholders with your real values)
LDAP_SERVER_HOST=your.ldap.server.local
LDAP_SERVER_PORT=389
LDAP_USE_TLS=false
LDAP_VALIDATE_CERT=false
LDAP_APP_DN="CN=YourBindUser,OU=Users,DC=example,DC=com"
LDAP_APP_PASSWORD="ChangeMeNow!"
LDAP_SEARCH_BASE="DC=example,DC=com"
LDAP_ATTRIBUTE_FOR_USERNAME=sAMAccountName
LDAP_ATTRIBUTE_FOR_MAIL=mail
LDAP_SEARCH_FILTER='(&(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'

# Qdrant
QDRANT_URI=http://qdrant:6333
QDRANT_COLLECTION=webui_rag
QDRANT_TIMEOUT=10

# Ollama concurrency
OLLAMA_NUM_PARALLEL=1

----------------------------------------------------------------------
Notes:

All sensitive info (domain, LDAP bind user, password) replaced with placeholders.

Users must replace the placeholders with real values for their environment.

This keeps the repository safe to publish without exposing internal credentials.

----------------------------------------------------------------------
9.Starting and Initial Verification
  1. Navigate to the project folder and start containers
cd /root/deepseek-rag
sudo docker compose pull
sudo docker compose up -d
----------------------------------------------------------------------
  2. Check container status
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
sudo docker logs -f deepseek-rag-caddy
sudo docker logs -f open-webui
sudo docker logs -f deepseek-rag-qdrant
sudo docker logs -f deepseek-rag-ollama
----------------------------------------------------------------------
  3. Verify services locally on the server
# Open-WebUI (HTTP)
curl -v http://127.0.0.1:8080/

# Caddy (HTTPS)
curl -vk https://your.internal.domain/   # Note: internal CA may not yet be trusted

# Qdrant health
curl http://127.0.0.1:6333/collections || true

# Ollama (via Load Balancer)
curl http://127.0.0.1:11434/api/version || true
----------------------------------------------------------------------
Notes:

If all services are running successfully, you can proceed to LDAP integration and admin setup.

Internal HTTPS (tls internal) may return a certificate warning until the internal CA is trusted

----------------------------------------------------------------------
10.LDAP / Active Directory — Testing and Correcting DNs

Before connecting the system to LDAP, make sure your DN paths are correct. Run the following tests from the server:
   1. Install LDAP utilities (if not already installed)
sudo apt update
sudo apt install -y ldap-utils
----------------------------------------------------------------------
   2. Find namingContexts (verify your LDAP_SEARCH_BASE)
ldapsearch -x -H ldap://your.ldap.server.local -s base -b "" "(objectclass=*)" namingContexts
Attention : Replace your.ldap.server.local with your LDAP server address.
----------------------------------------------------------------------
   3. Test binding with the LDAP application user (LDAP_APP_DN)
ldapwhoami -x -H ldap://your.ldap.server.local \
-D "CN=YourBindUser,OU=Users,DC=example,DC=com" \
-W

Attention :
Enter the LDAP password when prompted.
This confirms the user can bind successfully.
----------------------------------------------------------------------
   4.Optional: Use LDAPS (port 636)

Use ldaps:// in place of ldap://.

Set:
LDAP_USE_TLS=true
LDAP_VALIDATE_CERT=true   # or false temporarily for testing

Notes:

Make sure LDAP_SEARCH_BASE matches one of the namingContexts returned by step 2.

Correct DN paths are critical for LDAP authentication to work with Open-WebUI.


11.Importing Models (Deepseek 7B / 8B)

There are two main ways to add models to the offline server environment.
----------------------------------------------------------------------
Option 1 — Using Ollama (if the server has internet access)

     1.Enter the Ollama container:
sudo docker exec -it deepseek-rag-ollama /bin/sh
----------------------------------------------------------------------
     2.Inside the container, pull a model from Ollama registry:
ollama pull <model-name>
Example : ollama pull deepseek-r1:7b
----------------------------------------------------------------------
     3.Alternatively, if you have a local model archive:
ollama import <local-model.tar>
----------------------------------------------------------------------
Notes:

Replace <model-name> with the official Ollama model name.

Local imports must follow Ollama’s documentation for archive format.

Some models (like Deepseek) may require a license or token. Obtain the proper access if the model is not publicly available.
----------------------------------------------------------------------

12.Traffic, Queueing, and Concurrency Settings (50–60 Concurrent Users)
      1. Open-WebUI

Control the number of workers via the environment variable:
THREAD_POOL_SIZE=80
Adjust this based on your CPU cores and expected load.
----------------------------------------------------------------------
       2. Ollama
Concurrency is controlled using:
OLLAMA_NUM_PARALLEL=1
For heavy models, keep this number low (1–2) to prevent excessive CPU/memory usage.
----------------------------------------------------------------------
       3. Ollama Load Balancer
If you plan to run multiple Ollama instances:
Use separate volumes or share the same model folder.
Update ollama-lb.conf with multiple upstream entries to distribute load.
----------------------------------------------------------------------
       4. Nginx Rate Limiting
The current ollama-lb.conf uses limit_conn to limit concurrent connections per IP.
Optionally, you can add:
limit_req_zone $binary_remote_addr zone=req_zone:10m rate=10r/s;
limit_req zone=req_zone burst=20 nodelay;
This limits X requests per second per IP.
----------------------------------------------------------------------
       5. Application-level Queueing
If load spikes occur, consider a simple task queue (e.g., Redis) in Open-WebUI:
Requests are queued
Workers process them sequentially
Quick alternatives for high load:
Reduce concurrency
Use the LB for distributing requests evenly
----------------------------------------------------------------------
13.Automated Backups (systemd Timer)
       1. Create the backup script
File: /usr/local/bin/deepseek-backup.sh

sudo tee /usr/local/bin/deepseek-backup.sh > /dev/null <<'EOF'
#!/bin/bash
OUTDIR=/root/backup-deepseek/$(date +%F)
mkdir -p "$OUTDIR"

# Volumes to backup
docker run --rm -v deepseek-rag_open-webui-data:/data -v "$OUTDIR":/backup busybox \
  sh -c "tar czf /backup/openwebui-data.tgz -C /data ."

docker run --rm -v deepseek-rag_open-webui-storage:/data -v "$OUTDIR":/backup busybox \
  sh -c "tar czf /backup/openwebui-storage.tgz -C /data ."

docker run --rm -v deepseek-rag_qdrant:/data -v "$OUTDIR":/backup busybox \
  sh -c "tar czf /backup/qdrant.tgz -C /data ."

docker run --rm -v deepseek-rag_ollama:/data -v "$OUTDIR":/backup busybox \
  sh -c "tar czf /backup/ollama.tgz -C /data ."
EOF

sudo chmod +x /usr/local/bin/deepseek-backup.sh
----------------------------------------------------------------------
       2. Create systemd service
File: /etc/systemd/system/deepseek-backup.service

[Unit]
Description=Deepseek daily backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/deepseek-backup.sh

-----------------------------------------------------------------------
       3. Create systemd timer
File: /etc/systemd/system/deepseek-backup.timer

[Unit]
Description=Run Deepseek backup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target

------------------------------------------------------------------------
       4. Enable and start the timer

sudo systemctl daemon-reload
sudo systemctl enable --now deepseek-backup.timer
sudo systemctl start deepseek-backup.service   # run backup immediately

----------------------------------------------------------------------
Notes:
Backups are stored in /root/backup-deepseek/YYYY-MM-DD/.
Each volume is saved as a separate .tgz file.
Persistent=true ensures missed runs (e.g., server down) are executed when the system comes back online.

----------------------------------------------------------------------
14.Checks & Useful Commands

Docker / Service Commands
Command	Description
docker restart open-webui :	Restart the Open-WebUI container.
docker compose down -d :	Stop all containers in the Compose project.
docker compose up -d open-webui :	Start only the Open-WebUI container in detached mode.
docker logs -f open-webui :	Follow live logs of Open-WebUI.
docker logs open-webui :	Show the latest logs of Open-WebUI (non-live).
docker ps : 	List all running containers.
docker compose ps :  	Show Compose-managed containers and their status.
docker exec -it open-webui sh :	Enter an interactive shell inside the Open-WebUI container.
cd /app :	Navigate to the application folder inside the container.

----------------------------------------------------------------------
Server Resource Checks
Command	Description
htop :	Interactive process & resource viewer.
top : 	Show running processes and resource usage.
free -h :	Display memory usage in human-readable format.
df -h :	Check disk space usage for all mounted filesystems.
lscpu :	Display detailed CPU information.
sudo lshw -short :	grep -E "memory
----------------------------------------------------------------------
LDAP / Open-WebUI Admin Settings
In the LDAP Admin / Open-WebUI settings, do not use quotes " around any values. Using quotes can prevent proper binding and login.
Example (correct):

LDAP_SERVER_HOST=ldap.example.com
LDAP_SERVER_PORT=389
LDAP_USE_TLS=false
LDAP_APP_DN=CN=admin,DC=example,DC=com
LDAP_APP_PASSWORD=YourPassword
----------------------------------------------------------------------
This section 14 ensures that admins can safely check, troubleshoot, and manage the system.
----------------------------------------------------------------------
## Security Notes

- Never commit real credentials, passwords, or internal server IPs into the repository.
- Always use `.env` files to store sensitive information like LDAP passwords or API keys.
- When sharing the README or repository, ensure that placeholders or templates are used instead of real data.
----------------------------------------------------------------------
## Applying Configuration Changes

- Whenever you modify configuration files (e.g., `docker-compose.yml`, `Caddyfile`, `ollama-lb.conf`, or `.env`), you must restart the affected containers for changes to take effect.
- Recommended commands:

```bash
# Stop all containers
docker compose down

# Start containers with updated configuration
docker compose up -d

# Optional: follow logs to ensure services start correctly
docker logs -f <container-name>
----------------------------------------------------------------------
Always take backups before applying major configuration changes.
This helps users **avoid permission, connection, or service errors** when updating configs.  
Once you add this, we can go to **Step 3 — Add final checklist for post-deployment verification**. Do you want me to write that next?
----------------------------------------------------------------------
1.Final Checklist After Deployment
## Post-Deployment Checklist
After setting up the system, verify the following:
1. **Containers are running**  
```bash
docker ps
docker compose ps
----------------------------------------------------------------------
2.Open-WebUI is accessible
curl -v http://127.0.0.1:8080/
curl -vk https://ai.example.com/   # replace with your domain
----------------------------------------------------------------------
3.LDAP login works
Test logging in using a valid LDAP user account.
----------------------------------------------------------------------
4.Models are imported in Ollama
docker exec -it deepseek-rag-ollama ollama list
----------------------------------------------------------------------
5.Concurrency / thread pool settings are applied
Check THREAD_POOL_SIZE in .env
Check OLLAMA_NUM_PARALLEL in .env
----------------------------------------------------------------------
6.Backup timer is active
systemctl status deepseek-backup.timer
systemctl list-timers | grep deepseek-backup
----------------------------------------------------------------------
✅ Make sure all checks pass before considering the deployment complete.
This gives users a **clear set of steps to confirm everything is running correctly**.  
After adding this, the README will be much cleaner, safe, and fully instructional without including sensitive info.  
Do you want me to **rewrite the README fully in English** now, combining all the steps and sections we did?
----------------------------------------------------------------------
Technologies Used

Docker, Docker Compose
Open-WebUI, Qdrant, Ollama, Caddy, Nginx
LDAP/Active Directory
Bash, Python, SQLite, systemd

Contributions
This project was designed and implemented by Bahram khakbaz.
 Contributions and feedback are welcome!


=======
# AI-Project-LLM
A scalable AI system based on LLM with Docker and LDAP integration
>>>>>>> 4aeec39b465e1b32066f002dbc129f0bd055a2f0

