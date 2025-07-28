# Morphus


The **Morphus** is a secure, scalable application designed to automate and manage data transfers between various sources and destinations using configurable pipelines. The `MorphusInstaller.sh`  simplifies deployment and management of the Morphus application using Docker and Docker Compose. It offers guided setup and CLI-based lifecycle control.

---

##  Tech Stack

- **Frontend:** Angular
- **Backend:** Java-Springboot 
- **Workflow Orchestration:** Apache Airflow
- **Databases:** MySQL (backend) & PostgreSQL (Airflow)
- **Containerization:** Docker + Docker Compose

---

##  Prerequisites

- **Operating System:** Linux
- **RAM:** 8 GB
- **Storage:** 30 GB  

### Required Tools

| Tool             | Install Commands (Ubuntu/Debian)                                    | Confirm Installation         |
|------------------|---------------------------------------------------------------------|------------------------------|
| Docker           | `sudo apt install docker.io`                                        | `docker --version`           |
| Docker Compose V2| `sudo apt install docker-compose-plugin`                            | `docker compose version`     |
| lsof             | `sudo apt install lsof`                                             |                              |
| jq               | `sudo apt install jq`                                               |                              |
| mysql-client     | `sudo apt install mysql-client`                                     |                              |

**Note:** Script execution may prompt for password to run certain commands with `sudo` priveleges when necessary.

---

##  Installation

### 1. Clone the repository

```bash



git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>
chmod +x MorphusInstaller.sh
```

### 2. Run the Installer

```bash
./MorphusInstaller.sh
```

You will be prompted for:

- Confirmation of Docker availability 
- Port numbers (UI, Redis, Backend, Airflow)
- Application version (fetched from GitHub releases)
- MySQL database setup (new or existing)
- Docker Compose validation

### 3. Start the Service

```bash
morphus start
```

During the first launch, you'll be asked to:

1. Enter your organization’s domain name
2. Confirm it 
3. Provide your first name, last name, and company email
4. A user account is created with default password: `Welcome@123`

---

##  Directory Structure

```
/var/morphus/
├── logs/
│   ├── ui/
│   ├── backend/
│   └── airflow/
├── docker-compose.yaml
├── .env
```

---

##  CLI Utility

After installation, a global CLI command `morphus` is registered with the following subcommands:

```bash
morphus start       # Launch containers
morphus stop        # Stop containers
morphus update      # Upgrade to another version
morphus uninstall   # Remove all containers and files
```

---

##  Updating to a Newer Version

```bash
morphus update
```

- Fetches available versions from GitHub
- Allows selection and updates `.env`
- Restarts containers with new version

---

##  Troubleshooting

| Issue                         | Solution                                                                 |
|------------------------------|--------------------------------------------------------------------------|
| Docker Not Installed          | [Install Docker](https://docs.docker.com/get-docker/)                    |
| Docker Not Running            | `sudo systemctl start docker`                                           |
| Port Conflicts                | Script prompts for alternate ports if in use                            |
| DB Connection Fails           | Ensure MySQL credentials and host/port are correct                      |
| Permissions Issues            | Run with sudo where prompted                                            |
| Docker Compose Validation     | YAML errors block deployment—check `docker-compose.yaml` structure      |

---

## Uninstall

```bash
morphus uninstall
```

- Stops all containers
- Removes volumes, networks, and logs
- Deletes all installed files and CLI shortcut

---

##  Log Files

Log files are stored in:

- `/var/morphus/logs/ui/`
- `/var/morphus/logs/backend/`
- `/var/morphus/logs/airflow/`

---

##  Notes

- Supports Linux and macOS (some features like service detection differ)
- Docker images must be compatible with version mappings set in `.env`
- First-time start performs DB insertions for organization and user creation

---

##  Contact

For questions or access to the repository, contact: `<add maintainer contact>`
