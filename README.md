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

## Setup Instructions
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/bahram-khakbaz/AI-Project-LLM.git
   cd AI-Project-LLM

Configure Environment:

Copy .env.example to .env and fill in your LDAP and domain details.
Adjust paths in docker-compose.yml to match your server’s volume locations.


Set Permissions:
bash
mkdir -p /volumes/ai-project_{open-webui-storage,open-webui-data,qdrant,ollama,caddy_data,caddy_config}/_data
chown -R 1000:1000 /volumes/ai-project_{open-webui-storage,open-webui-data}/_data
chown -R root:root /volumes/ai-project_{qdrant,ollama,caddy_data,caddy_config}/_data
chmod -R 750 /volumes

Deploy:
bash
docker compose pull
docker compose up -d

Verify Services:
bash
docker ps
curl http://127.0.0.1:8080/

Enable Backups:
bash
cp systemd/* /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now ai-project-backup.timer

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
