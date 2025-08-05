#!/bin/bash

##########################################
#          CONFIGURATION VARIABLES       #
##########################################

SERVICE_NAME="morphus"
CLI_SCRIPT="morphus"
USER_HOME=$(eval echo ~$SUDO_USER)
INSTALL_DIR="$USER_HOME/.${SERVICE_NAME}"
CLI_TARGET="/usr/local/bin/$CLI_SCRIPT"
APP_DIR="/var/$CLI_SCRIPT"
AIRFLOW_DIR="/var/airflow"
SCRIPT_NAME="Morphus.sh"
REPO="Lynette-Pinto/Advanced-File-Transfer-and-Data-Processing-System"
ENV_FILE="$APP_DIR/.env"

# Docker Image Tags
DOCKER_HUB_REPO="infodatinc/morphus"
DOCKER_CONTAINER_NAME="morphus"
DOCKER_CONTAINER_NAME_BE="morphus-back-end"
DOCKER_CONTAINER_NAME_UI="morphus-ui"
DOCKER_CONTAINER_NAME_AF="morphus-airflow"
DOCKER_IMAGE_TAG_BE="1.0"
DOCKER_IMAGE_TAG_UI="1.0"
DOCKER_IMAGE_TAG_AIRFLOW="1.0"
AIRFLOW_IMG_NAME="apache/airflow:2.9.2"

# Database Variables
MYSQL_DB_USER="root"
MYSQL_DB_PASSWORD="password"
MYSQL_DB_NAME="morphus"
MYSQL_DB_PORT=3306
MYSQL_DB_HOSTNAME="morphus-mysql"

# Airflow Variables
AIRFLOW_DB_DIALECT="postgresql"
AIRFLOW_DB_CONNECTOR="psycopg2"
AIRFLOW_DB_USER="postgres"
AIRFLOW_DB_PASSWORD="password123"
AIRFLOW_DB_SERVER="morphus-airflow-postgres"
AIRFLOW_DB_PORT=5432
AIRFLOW_DB_NAME="postgres"
REDIS_PORT=6379
AIRFLOW_UID=5000
AIRFLOW_WEB_SECRET="your_secret_key_here"
PIP_ADDITIONAL_REQ="pandas numpy"   
AIRFLOW_USER_USERNAME="airflow"
AIRFLOW_USER_PASSWORD="airflow"
AIRFLOW_DAG_JSON_DATA_DIR="./dag_json_data"
UI_PORT=80

##########################################
#              HELPER FUNCTIONS          #
##########################################
# Function to write environment variables to the .env file
write_env_file() {
    cat <<EOF | sudo tee "$ENV_FILE" > /dev/null
SERVICE_NAME=$SERVICE_NAME
AIRFLOW_DB_DIALECT=$AIRFLOW_DB_DIALECT
AIRFLOW_DB_CONNECTOR=$AIRFLOW_DB_CONNECTOR
AIRFLOW_DB_USER=$AIRFLOW_DB_USER
AIRFLOW_DB_PASSWORD=$AIRFLOW_DB_PASSWORD
AIRFLOW_DB_SERVER=$AIRFLOW_DB_SERVER
AIRFLOW_DB_PORT=$AIRFLOW_DB_PORT
AIRFLOW_DB_NAME=$AIRFLOW_DB_NAME
AIRFLOW_IMG_NAME=$AIRFLOW_IMG_NAME
AIRFLOW_PROJ_DIR=$AIRFLOW_DIR
REDIS_PORT=$REDIS_PORT
REDIS_PASSWORD=
AIRFLOW__WEBSERVER__SECRET_KEY=$AIRFLOW_WEB_SECRET
AIRFLOW_PIP_ADDITIONAL_REQUIREMENTS="$PIP_ADDITIONAL_REQ"
AIRFLOW_UID=$AIRFLOW_UID
AIRFLOW_USER_USERNAME=$AIRFLOW_USER_USERNAME
AIRFLOW_USER_PASSWORD=$AIRFLOW_USER_PASSWORD
AIRFLOW_DAG_JSON_DATA_DIR=$AIRFLOW_DAG_JSON_DATA_DIR
MYSQL_DB_NAME=$MYSQL_DB_NAME
MYSQL_DB_HOSTNAME=$MYSQL_DB_HOSTNAME
MYSQL_DB_PORT=$MYSQL_DB_PORT
MYSQL_DB_USER=$MYSQL_DB_USER
MYSQL_DB_PASSWORD=$MYSQL_DB_PASSWORD
DOCKER_HUB_REPO_UI=$DOCKER_HUB_REPO-ui
DOCKER_HUB_REPO_BE=$DOCKER_HUB_REPO-back-end
DOCKER_HUB_REPO_AIRFLOW=$DOCKER_HUB_REPO-airflow
DOCKER_IMAGE_TAG_UI=$DOCKER_IMAGE_TAG_UI
DOCKER_IMAGE_TAG_BE=$DOCKER_IMAGE_TAG_BE
DOCKER_IMAGE_TAG_AIRFLOW=$DOCKER_IMAGE_TAG_AIRFLOW
DOCKER_CONTAINER_NAME=$DOCKER_CONTAINER_NAME
DOCKER_CONTAINER_NAME_BE=$DOCKER_CONTAINER_NAME_BE
DOCKER_CONTAINER_NAME_UI=$DOCKER_CONTAINER_NAME_UI
DOCKER_CONTAINER_NAME_AF=$DOCKER_CONTAINER_NAME_AF
UI_PORT=$UI_PORT
SPRING_PROFILES_ACTIVE=default
AIRFLOW_IMAGE_NAME=$AIRFLOW_IMG_NAME
EOF
}

#Check OS version
check_os() {
    case "$(uname -s)" in
        Linux*) OSTYPE="linux-gnu"; echo "Linux detected";;
        Darwin*) OSTYPE="darwin"; echo "macOS detected";;
        *) echo "Unsupported OS"; exit 1;;
    esac
}

#Cleanup on failure
cleanup_on_failure() {
    echo "Installation failed. Cleaning up..."
    sudo rm -rf "$INSTALL_DIR" "$APP_DIR" "$AIRFLOW_DIR"
    exit 1
}

#To check if a port availability
check_port() {
    local var_name=$1
    local description=$2
    local port_value
    eval "port_value=\$$var_name"

    while lsof -i TCP:"$port_value" -sTCP:LISTEN >/dev/null 2>&1; do
        echo "Port $port_value is in use for $description"
        read -p "Enter a different port for $description: " port_value
    done

    eval "$var_name=$port_value"
    echo "Port $port_value is available for $description"
}

# Fetch available versions from GitHub
fetch_versions() {
    local latest_release=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
    local asset_url=$(echo "$latest_release" | jq -r '.assets[] | select(.name=="version-mapping.json") | .browser_download_url')
    VERSION_MAPPING_URL=${asset_url:-"https://raw.githubusercontent.com/$REPO/main/version-mapping.json"}
    available_versions=$(curl -sL "$VERSION_MAPPING_URL" | jq -r 'keys[]')
    available_versions=($available_versions)
}

prompt_db_details() {
    read -rp "Database Hostname: " MYSQL_DB_HOSTNAME
    read -rp "Database Port: " MYSQL_DB_PORT
    read -rp "Database Username: " MYSQL_DB_USER
    read -rsp "Database Password: " MYSQL_DB_PASSWORD; echo
    read -rp "Backend Database Name: " MYSQL_DB_NAME
}


# Ensure Docker is running
ensure_docker_running() {
    attempt=0
    while ! sudo docker info &>/dev/null; do
        ((attempt++))
        echo "Docker not running. Attempt $attempt to start..."
        if [[ "$OSTYPE" == "linux-gnu" ]]; then
            sudo systemctl start docker
        else
            open --background -a Docker
        fi
        sleep 10
        ((attempt == 3)) && { echo "Docker daemon could not be started"; exit 1; }
    done
}


##########################################
#                 MAIN                   #
##########################################
echo ""
echo "Checking prerequisites..."
echo ""
check_os
echo ""

# Check for existing installation
if [ -d "$INSTALL_DIR" ]; then
    echo "Morphus is already installed in $INSTALL_DIR"
    echo "Run 'morphus update' to update or 'morphus uninstall' to remove it."
    exit 1
fi

# Check if Docker is installed
echo "Checking for Docker..."
if ! command -v docker &>/dev/null; then
    echo "Docker is not installed. Install it from https://docs.docker.com/get-docker/ and rerun this script."
    exit 1
fi
echo "Docker is installed."


ensure_docker_running
check_port UI_PORT "UI"
check_port AIRFLOW_DB_PORT "Postgres database"


echo "Installing $SERVICE_NAME..."

# Create installation and logs directories
mkdir -p "$INSTALL_DIR"
sudo mkdir -p \
  "$APP_DIR/logs/ui" \
  "$APP_DIR/logs/backend/api-gateway" \
  "$APP_DIR/logs/backend/auth" \
  "$APP_DIR/logs/backend/user-access-management" \
  "$APP_DIR/logs/backend/metadata" \
  "$APP_DIR/logs/backend/email-notification" \
  "$APP_DIR/database/mysql"
sudo chmod -R 777 "$APP_DIR"

# Create Airflow directories
sudo mkdir -p \
  "$AIRFLOW_DIR/dags" \
  "$AIRFLOW_DIR/logs" \
  "$AIRFLOW_DIR/config" \
  "$AIRFLOW_DIR/plugins" \
  "$AIRFLOW_DIR/test" \
  "$AIRFLOW_DIR/scripts" \
  "$AIRFLOW_DIR/api" \
  "$AIRFLOW_DIR/dag_json_data"
sudo chmod -R 777 "$AIRFLOW_DIR"

# Initialize env file
sudo sh -c "> \"$ENV_FILE\""


#Collect Version Info
fetch_versions
VERSION_FILE="$APP_DIR/.ver"

echo "Available versions:"
for i in "${!available_versions[@]}"; do
    echo "$((i+1)). ${available_versions[$i]}"
done

while true; do
    read -rp "Enter the number for the Application version to apply: " version_number
    if [[ "$version_number" =~ ^[1-9][0-9]*$ ]] && (( version_number >= 1 && version_number <= ${#available_versions[@]} )); then
        version_choice="${available_versions[$((version_number-1))]}"
        echo "VERSION=$version_choice" | sudo tee -a "$ENV_FILE" > /dev/null
        echo "Selected version: $version_choice"

        if [ ! -f "$VERSION_FILE" ]; then
            sudo tee "$VERSION_FILE" >/dev/null <<EOF
CURRENT_VERSION=$version_choice
PREVIOUS_VERSION=
EOF
        elif ! grep -q "CURRENT_VERSION=" "$VERSION_FILE"; then
            echo "CURRENT_VERSION=$version_choice" | sudo tee -a "$VERSION_FILE" > /dev/null
        fi

        # Extract component versions
        docker_image_tag_ui=$(curl -sL "$VERSION_MAPPING_URL" | jq -r --arg v "$version_choice" '.[$v].ui')
        docker_image_tag_be=$(curl -sL "$VERSION_MAPPING_URL" | jq -r --arg v "$version_choice" '.[$v].backend')
        docker_image_tag_airflow=$(curl -sL "$VERSION_MAPPING_URL" | jq -r --arg v "$version_choice" '.[$v].airflow')

        DOCKER_COMPOSE_URL="https://raw.githubusercontent.com/$REPO/main/docker-compose.yaml"
        TARGET_FILE="$APP_DIR/docker-compose.yaml"

        echo "Downloading the latest docker-compose.yaml..."
        if ! curl -fsSL "$DOCKER_COMPOSE_URL" -o "$TARGET_FILE"; then
            echo "Failed to download docker-compose.yaml. Please check the URL or network connection."
            cleanup_on_failure
            exit 1
        fi
        break
    else
        echo "Invalid selection, Please enter a valid number from the list"
    fi
done

# Collect database configuration for Airflow Setup

echo "We need to set MySQL Databases for setting up backend, Please select one of the following options"
echo "1. Create New MySQL Database"
echo "2. Use Existing MySQL Database"
read -r db_option

MAX_RETRIES=3
for attempt in $(seq 1 $MAX_RETRIES); do
    if [[ "$db_option" == "1" ]]; then
        echo
        check_port MYSQL_DB_PORT "MySQL database"
        echo "New databases will be created with:"
        echo "Host: $MYSQL_DB_HOSTNAME  Port: $MYSQL_DB_PORT"
        echo "User: $MYSQL_DB_USER      Backend DB: $MYSQL_DB_NAME"
        echo "Password can be changed later."
        echo ""
        write_env_file
        break

    elif [[ "$db_option" == "2" ]]; then
        echo
        prompt_db_details
        
        echo "Attempt $attempt/$MAX_RETRIES: Checking database connection..."
        if mysqladmin ping -h"$MYSQL_DB_HOSTNAME" -P"$MYSQL_DB_PORT" -u"$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD"  --silent 2>/dev/null; then
            echo "Connection successful to database host."
            write_env_file
            break
        else
            echo "Connection failed. Retrying..."
            if [[ $attempt -eq $MAX_RETRIES ]]; then
                echo "Failed to connect after $MAX_RETRIES attempts."
                cleanup_on_failure
                exit 1
            fi
        fi

    else
        echo "Invalid choice. Select 1 or 2."
        read -r db_option
    fi
done

#Validating docker-compose file
if ! output=$(docker compose -f "$APP_DIR/docker-compose.yaml" config 2>&1); then
    errors=$(echo "$output" | grep -v '^\[WARN\]')
    if [[ -n "$errors" ]]; then
        echo "Docker Compose configuration errors detected:"
        echo "$errors"
        cleanup_on_failure
        exit 1
    fi
else
    echo "Docker Compose config is valid."
fi


echo "Installing CLI command: morphus"
cat <<'EOF' | sudo tee "$CLI_TARGET" > /dev/null
#!/bin/bash

SERVICE_NAME="morphus"
CLI_SCRIPT="morphus"
USER_HOME=$(eval echo ~$SUDO_USER)
INSTALL_DIR="$USER_HOME/.${SERVICE_NAME}"
APP_DIR="/var/$CLI_SCRIPT"
REPO="Lynette-Pinto/Advanced-File-Transfer-and-Data-Processing-System"
ENV_FILE="$APP_DIR/.env"
ORG_MARKER="$APP_DIR/.org_created"
USER_MARKER="$APP_DIR/.user_created"
BACKUP_BASE="/var/morphus_backup"
VERSION_FILE="$APP_DIR/.ver"
TARGET_FILE="$APP_DIR/docker-compose.yaml"
AIRFLOW_DIR="/var/airflow"

# Determine version mapping URL
VERSION_MAPPING_URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" \
    | jq -r '.assets[]? | select(.name=="version-mapping.json") | .browser_download_url')
VERSION_MAPPING_URL="${VERSION_MAPPING_URL:-https://raw.githubusercontent.com/$REPO/main/version-mapping.json}"

# Ensure environment file exists
[[ -f "$ENV_FILE" ]] || { echo "ERROR: Environment file $ENV_FILE not found"; exit 1; }
set -a; source "$ENV_FILE"; set +a

# Detect OS
case "$(uname -s)" in
    Linux*)  OSTYPE="linux-gnu" ;;
    Darwin*) OSTYPE="darwin" ;;
    *) echo "Unsupported OS. Supported: Linux, macOS." && exit 1 ;;
esac


case "$1" in

################################
##### Version Information #####
################################
version)
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(sudo awk -F'=' '/CURRENT_VERSION/{print $2}' "$VERSION_FILE")
    echo "Current Version: ${CURRENT_VERSION:-Not Set}"
else
    echo "Version file not found. No version information available."
fi
;;


################################
####### Start Containers #######
################################

start)
echo "Starting Docker Containers..."
cd "$APP_DIR" || exit 1
#if docker compose up -d >/dev/null 2>&1; then
if docker compose up -d; then
    echo "Docker containers started successfully."
else
    echo "Failed to start Docker containers."
    exit 1
fi
echo "First time start detected. Creating organization in the database..."
# Wait for MySQL to be ready
for i in {1..30}; do
if docker exec morphus-mysql mysqladmin ping -u"$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" --silent 2>/dev/null; then
break
else
sleep 2
fi
if [ "$i" -eq 30 ]; then
echo "MySQL did not become ready in time."
exit 1
fi
done

if [ ! -f "$ORG_MARKER" ]; then
 echo -e "\nFirst time start detected. Creating organization in the database..."


while true; do
read -rp "Enter your organization name (domain name): " org_name
read -rp "Confirm organization name is '$org_name'? (y/n): " confirm_org_name
[[ "$confirm_org_name" == "y" ]] && break
echo "Please re-enter the details."
done

# Check if organization already exists
org_exists_query="SELECT COUNT(*) FROM morphus.organizations WHERE id='$org_name';"
org_exists=$(docker exec morphus-mysql mysql -u"$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" -N -e "$org_exists_query" 2>/dev/null)
if [ "$org_exists" -eq 0 ]; then
echo "Registering organization in the database..."
register_org_query="INSERT INTO morphus.organizations (id, name, active) VALUES ('$org_name', '$org_name', b'1');"
if docker exec morphus-mysql mysql -u"$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" -e "$register_org_query" 2>/dev/null; then
echo "Organization registered successfully."
echo "$org_name" | sudo tee "$ORG_MARKER" >/dev/null
else
echo "Failed to register organization '$org_name'. Please check your database connection details."
exit 1
fi
else
echo "Organization '$org_name' already exists. Skipping registration."
fi
else
echo "Organization already created. Skipping organization creation."
org_name=$(cat "$ORG_MARKER")
fi





docker compose -f "$APP_DIR/docker-compose.yaml" restart \
    morphus-mysql \
    morphus-back-end-api-gateway \
    morphus-back-end-auth \
    morphus-back-end-user-access-management \
    morphus-back-end-metadata \
    morphus-back-end-email-notification







if [[ ! -f "$USER_MARKER" ]]; then
echo -e "\nTo access the UI, we need to create a new user account."
echo "You can change the password later if needed."
read -rp "First Name: " first_name
read -rp "Last Name: " last_name
org_name_clean=$(echo "$org_name" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')
while true; do
read -rp "Company Email Address: " email_address
email_domain=$(echo "$email_address" | awk -F'@' '{print $2}' | awk -F'.' '{print $1}' | tr '[:upper:]' '[:lower:]')
if [[ "$email_domain" == "$org_name_clean" ]]; then
break
else
echo "Warning: Email domain ($email_domain) does not match organization name ($org_name_clean)."
echo "Please try again."
fi
done
fi

echo "Registering user in the database..."
register_user_query="INSERT INTO morphus.users (id, first_name, last_name, username, email, organization_id, password, active, deleted, is_new_user, is_owner) VALUES ('demo-id-1', '$first_name', '$last_name', '$email_address', '$email_address', '$org_name', '\$2a\$12\$GTDgS7SlX1j6v8cC6q/o7uUAZqhrNb1i5wKKXDFCkTEwJTTZscoTu', b'1', b'0', b'1', b'1');"


if docker exec morphus-mysql mysql -u"$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" -e "$register_user_query"; then
    echo "User '$email_address' registered successfully with default password 'Welcome@123'."
    echo "You can change the password later if needed."
    echo "$email_address" | sudo tee "$USER_MARKER" >/dev/null
    echo "User marker created."
else
    echo "Failed to register user '$email_address'. Please check your database connection and permissions."
    exit 1
fi
echo "Docker containers started successfully."
;;

################################
####### Stop Containers #######
################################
stop)
echo "Stopping Docker Containers..."
cd "$APP_DIR" || exit 1
if docker compose down >/dev/null 2>&1; then
    echo "Docker containers stopped successfully."
else
    echo "Failed to stop Docker containers."
    exit 1
fi
;;

################################
###### Update Containers #######
################################
update)

sudo touch "$ENV_FILE"

if [ ! -f "$ORG_MARKER" ] || [ ! -f "$USER_MARKER" ]; then
    echo "Morphus is not installed or not initialized. Please run 'morphus start' first to initialize the application."
    exit 1
fi


# Get current version
CURRENT_VERSION=$(sudo awk -F'=' '/CURRENT_VERSION/{print $2}' "$VERSION_FILE" 2>/dev/null)
[[ -z "$CURRENT_VERSION" ]] && echo "No version file found (.ver). Assuming fresh install."

all_versions=($(curl -sL "$VERSION_MAPPING_URL" | jq -r 'keys[]' | sort -V))

# Check if we got versions
if [ ${#all_versions[@]} -eq 0 ]; then
    echo "No versions found in mapping file."
    exit 1
fi

# Safely get the last element
last_index=$((${#all_versions[@]} - 1))
latest_version="${all_versions[$last_index]}"
echo "Latest version: $latest_version"

# Check if already up-to-date
if [[ "$CURRENT_VERSION" == "$latest_version" ]]; then
    echo "Morphus is already up-to-date (Current: $CURRENT_VERSION, Latest: $latest_version)."
    exit 0
fi
available_versions=() 
for ver in "${all_versions[@]}"; do
    if [[ -z "$CURRENT_VERSION" ]] || [[ "$(printf "%s\n%s" "$CURRENT_VERSION" "$ver" | sort -V | head -n1)" != "$ver" ]]; then
        available_versions+=("$ver")
    fi
done
if [[ ${#available_versions[@]} -eq 0 ]]; then
    echo "No newer versions available. Current version: $CURRENT_VERSION"
    exit 0
fi
# Show available future versions and get user selection
echo "Available newer versions:"
for i in "${!available_versions[@]}"; do
    echo "$((i+1)). ${available_versions[$i]}"
done

while true; do
    echo "Enter the number corresponding to the Application version you would like to apply:" 
    read -r version_number
    if [[ "$version_number" =~ ^[1-9][0-9]*$ ]] && (( version_number >= 1 && version_number <= ${#available_versions[@]} )); then
        version_choice="${available_versions[$((version_number-1))]}"
        break
    else
        echo "Invalid selection, please enter a valid number."
    fi 
done

#  Stop containers only if update confirmed
echo "Stopping Docker Containers..."
cd "$APP_DIR" || exit 1
docker compose down >/dev/null 2>&1 \
    && echo "Docker containers stopped successfully." \
    || { echo "Failed to stop Docker containers."; exit 1; }


# Backup previous version
BACKUP_DIR="$BACKUP_BASE/$CURRENT_VERSION"
sudo mkdir -p "$BACKUP_BASE"
sudo rm -rf "$BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"

sudo cp -r /var/morphus "$BACKUP_DIR/morphus"
sudo cp -r /var/airflow "$BACKUP_DIR/airflow"




#  Update ENV and version file before backup
grep -q '^VERSION=' "$ENV_FILE" && \
    sudo sed -i "s/^VERSION=.*/VERSION=$version_choice/" "$ENV_FILE" || \
    echo "VERSION=$version_choice" | sudo tee -a "$ENV_FILE" > /dev/null

sudo tee "$VERSION_FILE" > /dev/null <<EOL
PREVIOUS_VERSION=$CURRENT_VERSION
CURRENT_VERSION=$version_choice
EOL



docker_image_tag_ui=$(curl -sL "$VERSION_MAPPING_URL" | jq -r --arg v "$version_choice" '.[$v].ui')
docker_image_tag_be=$(curl -sL "$VERSION_MAPPING_URL" | jq -r --arg v "$version_choice" '.[$v].backend')
docker_image_tag_airflow=$(curl -sL "$VERSION_MAPPING_URL" | jq -r --arg v "$version_choice" '.[$v].airflow')

grep -q '^DOCKER_IMAGE_TAG_UI=' "$ENV_FILE" && sudo sed -i "s/^DOCKER_IMAGE_TAG_UI=.*/DOCKER_IMAGE_TAG_UI=$docker_image_tag_ui/" "$ENV_FILE" || echo "DOCKER_IMAGE_TAG_UI=$docker_image_tag_ui" | sudo tee -a "$ENV_FILE" > /dev/null
grep -q '^DOCKER_IMAGE_TAG_BE=' "$ENV_FILE" && sudo  sed -i "s/^DOCKER_IMAGE_TAG_BE=.*/DOCKER_IMAGE_TAG_BE=$docker_image_tag_be/" "$ENV_FILE" || echo "DOCKER_IMAGE_TAG_BE=$docker_image_tag_be" | sudo tee -a "$ENV_FILE" > /dev/null
grep -q '^DOCKER_IMAGE_TAG_AIRFLOW=' "$ENV_FILE" && sudo  sed -i "s/^DOCKER_IMAGE_TAG_AIRFLOW=.*/DOCKER_IMAGE_TAG_AIRFLOW=$docker_image_tag_airflow/" "$ENV_FILE" || echo "DOCKER_IMAGE_TAG_AIRFLOW=$docker_image_tag_airflow" | sudo tee -a "$ENV_FILE" > /dev/null

set -a; source "$ENV_FILE"; set +a

DOCKER_COMPOSE_URL="https://raw.githubusercontent.com/$REPO/main/docker-compose.yaml"
echo "Downloading the latest docker-compose.yaml..."
if ! curl -fsSL "$DOCKER_COMPOSE_URL" -o "$TARGET_FILE"; then
    echo "Failed to download docker-compose.yaml. Please check the URL or network connection."
    exit 1
fi


# Validate docker-compose config
if ! output=$(docker compose -f "$APP_DIR/docker-compose.yaml" config 2>&1); then
    errors=$(echo "$output" | grep -v '^\[WARN\]' || true)
    if [[ -n "$errors" ]]; then
        echo "Docker Compose configuration has errors:"
        echo "$errors"
        exit 1
    fi
else
    echo "Docker Compose config is valid."
fi


echo "Starting Docker containers..."
cd "$APP_DIR" || exit 1

if docker compose -f "$APP_DIR/docker-compose.yaml" up -d >/dev/null 2>&1; then
    echo "Update completed. Docker containers started successfully."
else
    echo "Failed to start Docker containers."
    exit 1
fi

;;



################################
##### Rollback Containers ######
################################



rollback)

sudo touch "$ENV_FILE"
if [ ! -f "$ORG_MARKER" ] || [ ! -f "$USER_MARKER" ]; then
echo "Morphus is not installed or not initialized. Please run 'morphus start' first to initialize the application."
exit 1
fi


echo "Starting rollback..."
if [ ! -f "$VERSION_FILE" ]; then
echo "No version file found. Cannot determine backup."
exit 1
fi

PREVIOUS_VERSION=$(sudo awk -F'=' '/PREVIOUS_VERSION/{print $2}' "$VERSION_FILE")
if [ -z "$PREVIOUS_VERSION" ]; then
echo "No previous version found."
exit 1
fi

BACKUP_PATH="$BACKUP_BASE/$PREVIOUS_VERSION"
if [ ! -d "$BACKUP_PATH" ]; then
echo "No backup found for $PREVIOUS_VERSION"
exit 1
fi

echo "Rolling back to $PREVIOUS_VERSION"

# Stop containers
cd "$APP_DIR" || exit 1
 docker compose down >/dev/null 2>&1 || { echo "Failed to stop containers."; exit 1; }

# Restore Morphus directory
sudo rsync -a --exclude='backup/' "$BACKUP_PATH/morphus/" /var/morphus/ > /dev/null


# Restore Airflow directory
sudo rm -rf /var/airflow
sudo cp -r "$BACKUP_PATH/airflow" /var/airflow
sudo chmod -R 777 /var/morphus /var/airflow


set -a; source "$ENV_FILE"; set +a


# Restart containers
echo "Restarting containers..."
cd "$APP_DIR" || exit 1
if docker compose -f "$APP_DIR/docker-compose.yaml" up -d >/dev/null 2>&1; then
    echo "Rollback to version $PREVIOUS_VERSION completed successfully."
else
    echo "Rollback failed to start containers."
    exit 1
fi
;;

################################
##### Uninstall Containers #####
################################

uninstall)
echo "Uninstalling $SERVICE_NAME..."
echo "Stopping and Removing docker containers..."

# Stop containers (no exit if cd fails)
if [ -d "$APP_DIR" ]; then
    (cd "$APP_DIR" && docker compose down >/dev/null 2>&1 || true)
fi

docker ps -a --format "{{.Names}}" | grep '^morphus-' | xargs -r docker stop >/dev/null 2>&1
docker ps -a --format "{{.Names}}" | grep '^morphus-' | xargs -r docker rm >/dev/null 2>&1

# Remove volumes, networks, images
docker volume rm $(docker volume ls -q | grep "^morphus") >/dev/null 2>&1
docker network ls --format "{{.Name}}" | grep '^morphus' | xargs -r docker network rm >/dev/null 2>&1
docker system prune -af --volumes
docker rmi $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E '^(morphus-|mysql|redis|postgres|apache/airflow)') >/dev/null 2>&1 || true

# Remove directories
sudo chown -R $(whoami):$(whoami) "$APP_DIR" "$INSTALL_DIR" "$AIRFLOW_DIR" 2>/dev/null || true
sudo rm -rf "$APP_DIR" "$INSTALL_DIR" "$AIRFLOW_DIR" "$BACKUP_BASE" /usr/local/bin/morphus || true

echo "$SERVICE_NAME has been uninstalled."
;;


#################################z
###  Show Usage Information #####
#################################

help|*)
echo "Usage: morphus {version|start|stop|update|rollback|uninstall}"
exit 1
;;
esac
EOF
 
sudo chmod +x "$CLI_TARGET"
echo "$SERVICE_NAME installed successfully."
echo "'$SERVICE_NAME' command is now available globally."


cat <<EOF 

Usage:          morphus {version|start|stop|update|rollback|uninstall}

Commands:
    version     Show the current version of the application
    start       Start the docker containers
    stop        Stop the docker containers
    update      Update docker containers to other versions 
    rollback    Rollback to the previous version of the application
    uninstall   Stop and remove the service and associated files

EOF
