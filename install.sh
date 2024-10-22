#!/bin/bash

# ASCII Art for "OctaByte"
cat <<'EOF'
  ___       _        ____        _       
 / _ \  ___| |_ __ _| __ ) _   _| |_ ___ 
| | | |/ __| __/ _` |  _ \| | | | __/ _ \
| |_| | (__| || (_| | |_) | |_| | ||  __/
 \___/ \___|\__\__,_|____/ \__, |\__\___|
                           |___/         
EOF

# Set environment variables
DOMAIN="vm.octabyte.io"
CDN="https://github.com/octabytes/app-templates/blob/main"

# Get user input for service configuration
read -p "Enter Service Name: " SERVICE_NAME
read -p "Enter Service Domain (prefix for $DOMAIN): " SERVICE_SUBDOMAIN
read -p "Enter Service Admin Email: " SERVICE_EMAIL

# Create the full service domain
SERVICE_DOMAIN="$SERVICE_SUBDOMAIN.$DOMAIN"

# Detect the OS (Ubuntu or Debian)
OS=$(lsb_release -is 2>/dev/null || grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

# Docker installation function for Ubuntu
install_docker_ubuntu() {
    echo "Detected OS: Ubuntu. Installing Docker for Ubuntu..."
    
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

# Docker installation function for Debian
install_docker_debian() {
    echo "Detected OS: Debian. Installing Docker for Debian..."

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
}

# Check for Docker installation and install based on OS
if ! command -v docker &> /dev/null
then
    echo "Docker not found. Installing Docker..."

    if [[ "$OS" == "Ubuntu" ]]; then
        install_docker_ubuntu
    elif [[ "$OS" == "Debian" ]]; then
        install_docker_debian
    else
        echo "Unsupported OS: $OS. Exiting."
        exit 1
    fi

    # Configure Docker to limit log size
    echo "Configuring Docker log limits..."
    sudo mkdir -p /etc/docker
    # cat <<EOF | sudo tee /etc/docker/daemon.json
    # {
    #     "log-driver": "json-file",
    #     "log-opts": {
    #         "max-size": "10m",
    #         "max-file": "3"
    #     },
    #     "storage-driver": "overlay2"
    # }
    # EOF

    # Restart Docker to apply configurations
    sudo systemctl restart docker

    echo "Docker setup complete."

else
    echo "Docker is already installed."
fi

# Check if Git is installed, if not, install it
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing Git..."
    sudo apt update
    sudo apt install -y git
else
    echo "Git is already installed. Skipping installation."
fi

# Clone the repository
echo "Cloning repository..."
git clone https://github.com/octabytes/app-templates.git /tmp/app-templates

# Copy the selected service folder to /opt/app
SERVICE_FOLDER="/tmp/app-templates/$SERVICE_NAME"
if [ ! -d "$SERVICE_FOLDER" ]; then
    echo "Error: Service folder for $SERVICE_NAME not found!"
    exit 1
fi

echo "Setting up service..."
sudo mkdir -p /opt/app
sudo cp -r "$SERVICE_FOLDER/." /opt/app/
rm -rf /tmp/app-templates  # Clean up the cloned repo

# Generate .env file based on the "environments" key in config.yml
CONFIG_FILE="/opt/app/config.yml"
ENV_FILE="/opt/app/.env"

echo "Creating .env file from config.yml..."

# Create or clear the .env file with sudo
sudo sh -c "echo '' > $ENV_FILE"

# Function to generate random password
generate_random_password() {
    echo $(openssl rand -base64 12)
}

# Parse YAML environments section and generate the .env file
YAML_KEY="environments"
parse_env_file() {
    while IFS= read -r line; do
        if [[ "$line" =~ "-" ]]; then
            key=$(echo "$line" | awk -F: '{gsub(/ /, "", $1); print $1}')
            value=$(echo "$line" | awk -F: '{gsub(/ /, "", $2); print $2}')
            # If value is "random_password", generate a random one
            if [ "$value" == "random_password" ]; then
                value=$(generate_random_password)
            fi
            # Replace placeholders with real values
            case $value in
                "[SERVICE_EMAIL]")
                    value="$SERVICE_EMAIL"
                    ;;
                "[SERVICE_DOMAIN]")
                    value="$SERVICE_DOMAIN"
                    ;;
                "[DOMAIN]")
                    value="$SERVICE_SUBDOMAIN"
                    ;;
            esac
            # Write to .env file
            echo "$key=$value" | sudo tee -a $ENV_FILE > /dev/null
        fi
    done < $CONFIG_FILE
}

parse_env_file

# Execute the pre-install script
PRE_INSTALL_SCRIPT="/opt/app/scripts/preInstall.sh"
if [ -f "$PRE_INSTALL_SCRIPT" ]; then
    echo "Running pre-install script..."
    bash "$PRE_INSTALL_SCRIPT"
else
    echo "Warning: preInstall.sh script not found!"
fi

# Run docker-compose.yml
DOCKER_COMPOSE_FILE="/opt/app/docker-compose.yml"
if [ -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "Running Docker Compose..."
    sudo docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
else
    echo "Warning: docker-compose.yml not found!"
fi

# Read the "webUI" key from config.yml and display relevant information in table format
echo "Fetching service setup information..."

show_web_ui_info() {
    local key value inside_webui_section=false

    # Output header for the table
    echo "---------------------------------------------"

    # Iterate through the config.yml file
    while IFS= read -r line; do
        # Detect the start of the webUI section
        if [[ "$line" =~ "webUI:" ]]; then
            inside_webui_section=true
            continue
        fi

        # Stop processing once out of the webUI section
        if [[ $inside_webui_section == true && ! "$line" =~ "-" ]]; then
            break
        fi

        # Process each key-value pair in the webUI section
        if [[ "$inside_webui_section" == true && "$line" =~ "-" ]]; then
            key=$(echo "$line" | awk -F: '{gsub(/ /, "", $1); print $1}')
            value=$(echo "$line" | awk -F: '{gsub(/ /, "", $2); print $2}')

            # Replace placeholders with actual values
            case $value in
                "[SERVICE_DOMAIN]")
                    value="$SERVICE_DOMAIN"
                    ;;
                "[SERVICE_EMAIL]")
                    value="$SERVICE_EMAIL"
                    ;;
                "[ADMIN_PASSWORD]")
                    value=$(grep 'ADMIN_PASSWORD' $ENV_FILE | cut -d '=' -f 2)
                    ;;
            esac

            # Dynamically display each available field
            case $key in
                "label")
                    echo "| Service         | $value"
                    ;;
                "url")
                    echo "| URL             | $value"
                    ;;
                "login")
                    echo "| Login           | $value"
                    ;;
                "email")
                    echo "| Email           | $value"
                    ;;
                "password")
                    echo "| Password        | $value"
                    ;;
            esac
        fi
    done < $CONFIG_FILE

    # Output footer for the table
    echo "---------------------------------------------"
    echo
}

show_web_ui_info

# ASCII Art for "Congratulations"
cat <<'EOF'
  ____                            _         _       _   _                 
 / ___|___  _ __   __ _ _ __ __ _| |_ _   _| | __ _| |_(_) ___  _ __  ___ 
| |   / _ \| '_ \ / _` | '__/ _` | __| | | | |/ _` | __| |/ _ \| '_ \/ __|
| |__| (_) | | | | (_| | | | (_| | |_| |_| | | (_| | |_| | (_) | | | \__ \
 \____\___/|_| |_|\__, |_|  \__,_|\__|\__,_|_|\__,_|\__|_|\___/|_| |_|___/
                  |___/                                                   
EOF

# End of script