#!/bin/bash

SERVICE_NAME="morphus"
CLI_SCRIPT="morphus"
INSTALL_DIR="$HOME/.${SERVICE_NAME}"
SCRIPT_NAME="Morphus.sh"
CLI_TARGET="/usr/local/bin/$CLI_SCRIPT"
AIRFLOW_DIR="/var/airflow"
APP_DIR="/var/$CLI_SCRIPT"
COMPOSE_FILE="docker-compose.yaml"
AF_DOCKER_FILE="Dockerfile"
#REPO needs to be changed
REPO="Lynette-Pinto/Formula1"
REQUIREMENTS_FILE="requirements.txt"


#Variables for airflow
airflow_db_dialect="postgresql"
airflow_db_connector="psycopg2"
airflow_db_user="postgres"
airflow_db_password="password123"
airflow_db_server="morphus-airflow-postgres"
airflow_db_port=5432
airflow_db_name="postgres"

#airflow_db_name="airflow-postgres"
airflow_img_name="apache/airflow:2.9.2"
airflow_dir="."
redis_port=6379
airflow_webserver_secret="your_secret_key_here"
pip_add_reqr="pandas numpy"
airflow_uid=5000
airflow_user_name="airflow"
airflow_user_password="airflow"
airflow_dag_JSON_DIR="./dag_json_data"

#Variables for UI & Backend
#MySQL

mysql_db_user="root"
mysql_db_password="password"
mysql_db_name="morphus"
mysql_db_port=3306
mysql_db_hostname="morphus-mysql"
ui_port=80

docker_hub_repo="morphus"
airflow_img_ui="3.2"  
airflow_img_be="3.9"



#Functions
function writeto_env_file(){

    #Airflow Variables:
    echo "SERVICE_NAME=$SERVICE_NAME" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo ""
    echo "#Airflow Variables:" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "SERVICE_NAME=$SERVICE_NAME" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_DB_DIALECT=$airflow_db_dialect" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_DB_CONNECTOR=$airflow_db_connector" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_DB_USER=$airflow_db_user" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_DB_PASSWORD=$airflow_db_password" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_DB_SERVER=$airflow_db_server" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_DB_PORT=$airflow_db_port" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_DB_NAME=$airflow_db_name" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_IMG_NAME=$airflow_img_name" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_PROJ_DIR=$airflow_dir" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "REDIS_PORT=$redis_port" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "REDIS_PASSWORD=" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW__WEBSERVER__SECRET_KEY=$airflow_webserver_secret" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_PIP_ADDITIONAL_REQUIREMENTS=\"$pip_add_reqr\""  | sudo tee -a   "$ENV_FILE" > /dev/null
    echo "AIRFLOW_UID=$airflow_uid" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_USER_USERNAME"=$airflow_user_name | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_USER_PASSWORD"=$airflow_user_password | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "AIRFLOW_DAG_JSON_DATA_DIR"=$airflow_dag_JSON_DIR | sudo tee -a  "$ENV_FILE" > /dev/null
    
    #UI & Backend variables
    #MySQL
    echo ""
    echo "#UI & Backend variables" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "MYSQL_DB_NAME=$mysql_db_name" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "MYSQL_DB_HOSTNAME=$mysql_db_hostname" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "MYSQL_DB_PORT=$mysql_db_port" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "MYSQL_DB_USER=$mysql_db_user" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo "MYSQL_DB_PASSWORD=$mysql_db_password" | sudo tee -a  "$ENV_FILE" > /dev/null
    echo ""
    echo "DOCKER_HUB_REPO_UI=$docker_hub_repo-ui"  | sudo tee -a   "$ENV_FILE" > /dev/null
    echo "DOCKER_HUB_REPO_BE=$docker_hub_repo-back-end"  | sudo tee -a   "$ENV_FILE" > /dev/null
    echo "DOCKER_IMAGE_TAG_UI=$airflow_img_ui"  | sudo tee -a   "$ENV_FILE" > /dev/null
    echo "DOCKER_IMAGE_TAG_BE=$airflow_img_be"  | sudo tee -a   "$ENV_FILE" > /dev/null
    echo "UI_PORT=$ui_port"  | sudo tee -a   "$ENV_FILE" > /dev/null
    echo "SPRING_PROFILES_ACTIVE=default"  | sudo tee -a   "$ENV_FILE" > /dev/null
    echo "AIRFLOW_IMAGE_NAME=$airflow_img_name"  | sudo tee -a  "$ENV_FILE" > /dev/null
    
}


#Check OS version
echo ""
echo "Detecting OS..."
$OSTYPE=$(uname -s) > /dev/null 2>&1
if [[ "$(uname -s 2>/dev/null)" == "Linux" ]]; then
    OSTYPE="linux-gnu"
    echo "Linux OS detected."
elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then
    OSTYPE="darwin"
    echo "macOS detected."
else
    OSTYPE="unknown"
    echo "Unsupported OS. This script is supported by Linux, macOS and Linux only."
    exit 1
fi
echo ""


#Check if morphus already installed
if [ -d "$INSTALL_DIR" ]; then
    echo "Morphus is already installed in $INSTALL_DIR"
    echo "If you want to update the installation, please run the 'morphus update' command."
    echo "If you want to uninstall the existing installation, please run the 'Morphus uninstall' command."
    exit 1
fi

#Check if docker is installed
echo "Checking if docker is installed..."
# For Linux and macOS, check if Docker is installed
if ! docker --version >\dev\null ; then
    echo "Docker is not installed. Please follow the instructions to install Docker."
    echo "Docker installation instructions can be found at https://docs.docker.com/get-docker/"
    echo "Once Docker is installed, please run this script again."
    exit 1
else 
    echo "Docker is installed"
    echo ""
fi

#Check if docker is running
echo "Checking if docker is up and running..."
i=0
while true; do
    if ! docker info >\dev\null  2>&1; then
        echo "Docker is not running."
        i=$((i+1))
        echo "Attempt $i to start the daemon"
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo systemctl start docker
            sleep 10
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            open --background -a Docker
            sleep 10
        fi
        if [ "$i" -eq 3 ]; then
                echo "Unable to start the daemon. Please troubleshoot further and run the script when Docker is up and running"  
                exit 1
        fi
    else 
        echo "Docker is currently running"
        echo ""
        break
    fi
done

is_port_in_use() {
  local port=$1
  lsof -i TCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
  return $?
}

check_port() {
  local var_name=$1
  local description=$2
  local port_value=${!var_name}

  echo "Checking if port $port_value is available for $description..."
  while true; do
    if is_port_in_use "$port_value"; then
      echo "Port $port_value is in use."
      read -p "Enter a different port for $description: " port_value
    else
      echo "Port $port_value is available for $description"
      break
    fi
  done

  printf -v "$var_name" '%s' "$port_value"
  echo ""
}

check_port ui_port "UI"
check_port airflow_db_port "Postgres database"
check_port redis_port "Redis"




echo "Installing $SERVICE_NAME..."
mkdir -p "$INSTALL_DIR"
sudo mkdir -p "$APP_DIR"
sudo mkdir -p "$APP_DIR/logs"
sudo mkdir -p "$APP_DIR/logs/ui"
sudo mkdir -p "$APP_DIR/logs/backend"
sudo mkdir -p "$APP_DIR/logs/airflow"
sudo cp "./$COMPOSE_FILE" "$APP_DIR"
# sudo cp "./$AF_DOCKER_FILE" "$APP_DIR"
# sudo cp "./$REQUIREMENTS_FILE" "$APP_DIR"

sudo chmod -R 777 "$APP_DIR"

sudo mkdir -p "$AIRFLOW_DIR"
sudo mkdir -p "$AIRFLOW_DIR/dags"
sudo mkdir -p "$AIRFLOW_DIR/logs"
sudo mkdir -p "$AIRFLOW_DIR/config"
sudo mkdir -p "$AIRFLOW_DIR/plugins"
sudo mkdir -p "$AIRFLOW_DIR/test"
sudo mkdir -p "$AIRFLOW_DIR/scripts"
sudo mkdir -p "$AIRFLOW_DIR/api"
sudo mkdir -p "$AIRFLOW_DIR/dag_json_data"
sudo chmod -R 777 "$AIRFLOW_DIR"


ENV_FILE="$APP_DIR/.env"

sudo touch "$ENV_FILE"
sudo sh -c "> \"$ENV_FILE\""



#Collect Version Info
available_versions=($(curl -s "https://api.github.com/repos/$REPO/tags" | jq -r '.[].name'))
echo "Available versions:"
for i in "${!available_versions[@]}"; do
    echo "$((i+1)). ${available_versions[$i]}"
done

while true; do
    echo "Enter the number corresponding to the Application version you would like to apply" 
    read -r version_number
    if [[ "$version_number" =~ ^[1-9][0-9]*$ ]] && (( version_number >= 1 && version_number <= ${#available_versions[@]} )); then
        version_choice="${available_versions[$((version_number-1))]}"
        echo "VERSION=$version_choice" | sudo tee -a "$ENV_FILE" > /dev/null
        echo "Selected version: $version_choice"
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

count=0
while true; do
    if [[ "$db_option" == "1" ]]; then
        echo ""
        check_port mysql_db_port "MySQL database"
        echo "New databases will be created with the following details:"
        echo "Database Hostname: $mysql_db_hostname"  
        echo "Database Port: $mysql_db_port"
        echo "Database Username: $mysql_db_user"
        echo "Database Password: $mysql_db_password"
        echo "Airflow Database Name: $airflow_db_name"
        echo "Backend Database Name: $mysql_db_name"
        echo "You can change the password later if needed."
        echo ""
        writeto_env_file
        break

    elif [[ "$db_option" == "2" ]]; then
        count=$((count+1))
        echo ""
        echo "Please enter the hostname of the database:"
        read -r db_hostname
        echo "Please enter the port number of the database:"
        read -r db_port
        echo "Please enter the username for the database:"
        read -r db_username
        echo "Please enter the password for the database:"
        read -s db_password
        echo "Please enter the name of the backend database:"
        read -r mysql_db_name

        echo "Checking database connection..."
        if [[ "$(mysql -h $mysql_db_hostname -P $mysql_db_port -u $mysql_db_user -p$mysql_db_password -sse "SHOW DATABASES LIKE '$mysql_db_name';" 2>/dev/null)" == "$mysql_db_name" ]]; then
                echo "Connection to database '$mysql_db_name' successful"
                writeto_env_file
                break
        else
            echo "Unable to connect to the databse Please Enter the details again"
        fi
        echo ""
        if [[ $count -gt 2 ]]; then
                echo "Not able to connect to DB. Please try again later"
                exit 1
        fi
    else
        echo "Invalid choice. Please select between 1 & 2"
        read -r db_option
    fi
done


#Validating docker-compose file
docker_validation=$(docker compose -f "$APP_DIR/docker-compose.yaml" config 2>&1 > /dev/null)
if [ $? -ne 0 ]; then
    NON_WARN_LINES=$(echo "$docker_validation" | grep -v '^\[WARN\]' || true)
    if [ -n "$NON_WARN_LINES" ]; then
        echo "Docker-compose configuration has errors:"
        echo "$NON_WARN_LINES"
        exit 1
    fi
else
    echo "Docker-compose config is valid."
fi


echo "Installing CLI command: morphus"
cat <<'EOF' | sudo tee "$CLI_TARGET" > /dev/null
#!/bin/bash
 
SERVICE_NAME="morphus"
CLI_SCRIPT="morphus"
INSTALL_DIR="$HOME/.${SERVICE_NAME}"
PLATFORM=$(uname)
#SCRIPT_NAME="MorphusInstaller.sh"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
APP_DIR="/var/$CLI_SCRIPT"
REPO="Lynette-Pinto/Formula1"
ENV_FILE="$APP_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "ERROR: Environment file $ENV_FILE not found at $ENV_FILE"
    exit 1
fi

#Check OS version
echo ""
echo "Detecting OS..."
$OSTYPE=$(uname -s) > /dev/null 2>&1
if [[ "$(uname -s 2>/dev/null)" == "Linux" ]]; then
    OSTYPE="linux-gnu"
    echo "Linux OS detected."
elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then
    OSTYPE="darwin"
    echo "macOS detected."
else
    OSTYPE="unknown"
    echo "Unsupported OS. This script is supported by Linux, macOS and Linux only."
    exit 1
fi
echo ""


case "$1" in
  
  start)
    echo "Starting Docker Containers..."
    cd "$APP_DIR" || exit 1
    docker compose up -d
    if [ -$? -eq 0 ]; then
        echo "Docker containers started successfully"
    else
        echo "Failed to start Docker containers"
        exit 1
    fi
    # Check if this is the first time starting the containers by checking for a marker file
    ORG_MARKER="$APP_DIR/.org_created"
    USER_MARKER="$APP_DIR/.user_created"


    echo "First time start detected. Creating organizations in the database..."
    # Wait for MySQL to be ready
    echo "Waiting for MySQL to be ready..."
    for i in {1..30}; do
        if docker exec morphus-mysql mysqladmin ping -u"$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" --silent 2>/dev/null; then
            echo "MySQL is up."
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
        echo ""
        echo "We need to register your organization with the application"
        echo "Your organization name will be used to create a unique identifier for your organization in the database."

        echo "Please enter your organization name(domain name):"
        read -r org_name
        echo "Can you confirm that the organization name is $org_name? (y/n)"
        read -r confirm_org_name
        while [[ "$confirm_org_name" != "y" ]]; do
            echo "Please re-enter the organization name:"
            read -r org_name
            echo "Can you confirm that the organization name is $org_name? (y/n)"
            read -r confirm_org_name
        done
        # Check if organization already exists
        org_exists_query="SELECT COUNT(*) FROM morphus.organizations WHERE id='$org_name';"
        org_exists=$(docker exec morphus-mysql mysql -u$MYSQL_DB_USER -p$MYSQL_DB_PASSWORD -N -e "$org_exists_query")
        if [ "$org_exists" -eq 0 ]; then
            echo "Registering organization in the database..."
            register_org_query="INSERT INTO morphus.organizations (id, name, active) VALUES ('$org_name', '$org_name', b'1');"
            if docker exec morphus-mysql mysql -u$MYSQL_DB_USER -p$MYSQL_DB_PASSWORD -e "$register_org_query"; then
                echo "Organization registered successfully."
                touch "$ORG_MARKER"
                echo "$org_name" > "$ORG_MARKER"
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

    
    if [ ! -f "$USER_MARKER" ]; then
        #Colect information to create user for the UI
        echo ""
        echo "To access the UI, we need to create a new user account."
        echo "Please provide the following details:"
        echo "You will be able to change the password later if needed." 
        echo ""
        echo "Please enter your First Name:"
        read -r first_name
        echo "Please enter your Last Name:"
        read -r last_name
        echo "Please enter your Company Email Address:"
        read -r email_address

        email_domain=$(echo "$email_address" | awk -F'@' '{print $2}' | awk -F'.' '{print $1}' | tr '[:upper:]' '[:lower:]')
        org_name_clean=$(echo "$org_name" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')

        if [[ "$email_domain" != "$org_name_clean" ]]; then
            echo "Warning: The domain of the email address ($email_domain) does not match the organization name ($org_name_clean)."
            echo "Please enter an email address with a domain matching your organization name."
            while true; do
                echo "Please enter your Company Email Address:"
                read -r email_address
                email_domain=$(echo "$email_address" | awk -F'@' '{print $2}' | awk -F'.' '{print $1}' | tr '[:upper:]' '[:lower:]')
                if [[ "$email_domain" == "$org_name_clean" ]]; then
                    break
                else
                    echo "The domain of the email address ($email_domain) does not match the organization name ($org_name_clean). Please try again."
                fi
            done
        fi

        echo "Registering user in the database..."
        register_user_query="INSERT INTO morphus.users (id, first_name, last_name, username, email, organization_id, password, active, deleted, is_new_user, is_owner) VALUES ('demo-id-1', '$first_name', '$last_name', '$email_address', '$email_address', '$org_name', '\$2a\$12\$GTDgS7SlX1j6v8cC6q/o7uUAZqhrNb1i5wKKXDFCkTEwJTTZscoTu', b'1', b'0', b'1', b'1');"
        if docker exec morphus-mysql mysql -u$MYSQL_DB_USER -p$MYSQL_DB_PASSWORD -e "$register_user_query"; then
            echo "User '$email_address' registered successfully with default password 'Welcome@123'.You can change the password later if needed."
        else
            echo "Failed to register user '$email'. Please check your database connection and permissions."
            exit 1
        fi

        touch "$USER_MARKER"
        echo "User created successfully."
    else
        echo "User already created. Skipping user creation."
    fi
    echo "Docker containers started successfully."
    ;;
 
  stop)
    echo "Stopping Docker Containers..."
    cd "$APP_DIR" || exit 1
    if docker compose down; then
        echo "Docker contaners stopped succesfully"
    else
        echo Failed to stop docker containers 
        exit 1
    fi
    ;;

  update)
    
    sudo touch "$ENV_FILE"
    #Stopping Docker containers
    
    echo "Stopping Docker Containers..."
    cd "$APP_DIR" || exit 1
    if docker compose down; then
        echo "Docker contaners stopped succesfully"
    else
        echo Failed to stop docker containers 
        exit 1
    fi

    available_versions=($(curl -s "https://api.github.com/repos/$REPO/tags" | jq -r '.[].name'))
    echo "Available versions:"
    for i in "${!available_versions[@]}"; do
        echo "$((i+1)). ${available_versions[$i]}"
    done

    while true; do
        echo "Enter the number corresponding to the Application version you would like to apply" 
        read -r version_number
        if [[ "$version_number" =~ ^[1-9][0-9]*$ ]] && (( version_number >= 1 && version_number <= ${#available_versions[@]} )); then
            version_choice="${available_versions[$((version_number-1))]}"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sudo sed -i '' "/^[[:space:]]*VERSION[[:space:]]*=.*/d" "$ENV_FILE"
            else
                sudo sed -i "/^[[:space:]]*VERSION[[:space:]]*=.*/d" "$ENV_FILE"
            fi
            echo "VERSION=${version_choice}" | sudo tee -a "$ENV_FILE" > /dev/null
            echo "Selected version: $version_choice"
            break            
        else
            echo "Invalid selection, Please enter a valid number from the list"
        fi 
    done

    echo "Validating docker-compose..."
    #Validating docker-compose file
    docker_validation=$(docker compose -f "$APP_DIR/docker-compose.yaml" config 2>&1 > /dev/null)
    if [ $? -ne 0 ]; then
        NON_WARN_LINES=$(echo "$docker_validation" | grep -v '^\[WARN\]' || true)
        if [ -n "$NON_WARN_LINES" ]; then
            echo "Docker-compose configuration has errors:"
            echo "$NON_WARN_LINES"
            exit 1
        fi
    else
        echo "Docker-compose config is valid."
    fi

    echo "Starting docker-compose..."
    cd "$APP_DIR" || exit 1
    docker compose up -d

    if [ -$? -eq 0 ]; then
        echo "Docker containers started successfully"
    else
        echo "Failed to start Docker containers"
    fi


    ;;
 
  uninstall)
    echo "Uninstalling $SERVICE_NAME..."
    echo "Stopping and Removing docker containers..."
    cd "$APP_DIR" || exit 1
    docker compose down

    docker ps -a --format "{{.Names}}" | grep '^morphus-' | xargs -r docker stop
    docker ps -a --format "{{.Names}}" | grep '^morphus-' | xargs -r docker rm

    # Remove volumes
    docker volume rm $(docker volume ls -q | grep "^${CLI_SCRIPT}_morphus-") || true

    # Remove networks
    docker network ls --format "{{.Name}}" | grep '^morphus' | xargs -r docker network rm

    # Remove images
    #docker rmi $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E '^(morphus-|mysql|redis|postgres|apache/airflow)') || true

    sudo rm -rf "$APP_DIR"
    sudo rm -rf "$INSTALL_DIR"
    sudo rm -rf "$AIRFLOW_DIR"
    sudo rm -f /usr/local/bin/morphus
    echo "$SERVICE_NAME has been uninstalled."
    ;;
 
  *)
    echo "Usage: morphus {start|stop|update|uninstall}"
    exit 1
    ;;
esac
EOF
 
sudo chmod +x "$CLI_TARGET"
echo "$SERVICE_NAME installed successfully."
echo "'$SERVICE_NAME' command is now available globally."


cat <<EOF 

Usage:          morphus {start|stop|update|uninstall}

Commands:
    start       Start the docker containers
    stop        Stop the docker containers
    update      Update docker containers to other versions 
    uninstall   Stop and remove the service and associated files

EOF
