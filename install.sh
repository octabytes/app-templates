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

echo "VERSION 1.2"

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

echo "Creating .env file from env.txt..."

# Define env.txt and .env file paths
ENV_FILE="/opt/app/.env"
ENV_TXT_FILE="/opt/app/env.txt"

# Function to generate random password
generate_random_password() {
    echo $(openssl rand -base64 12)
}

# Function to create .env from env.txt
create_env_file() {

    # Check if env.txt exists
    if [[ ! -f "$ENV_TXT_FILE" ]]; then
        echo "Error: $ENV_TXT_FILE not found!"
        return 1
    fi

    # Create or clear the .env file
    echo "" | sudo tee "$ENV_FILE" > /dev/null  # Clear the existing .env file or create a new one
    if [[ $? -ne 0 ]]; then
        echo "Failed to create .env file. Check permissions."
        return 1
    fi

    # Read from env.txt and process each line
    while IFS= read -r line; do

        # Replace RANDOM_PASSWORD with a generated password
        if [[ "$line" == *"RANDOM_PASSWORD"* ]]; then
            password=$(generate_random_password)
            line=${line//RANDOM_PASSWORD/$password}  # Replace RANDOM_PASSWORD with the generated password
        fi
        
        # Replace placeholders with actual values
        line=$(eval echo "$line")  # This will evaluate any variable in the line

        # Append to .env file with error handling
        echo "$line" | sudo tee -a "$ENV_FILE" > /dev/null
        if [[ $? -ne 0 ]]; then
            echo "Failed to write to .env file. Check permissions."
            return 1
        fi
    done < "$ENV_TXT_FILE"

    # Attempt to remove env.txt, handle errors
    if ! sudo rm -f "$ENV_TXT_FILE"; then
        echo "Warning: Unable to remove $ENV_TXT_FILE. Check permissions."
    fi

    echo ".env file created successfully."
}

# Call the function to create the .env file
create_env_file

# Move to app directory
cd /opt/app

# Execute the pre-install script
PRE_INSTALL_SCRIPT="/opt/app/scripts/preInstall.sh"
if [ -f "$PRE_INSTALL_SCRIPT" ]; then
    echo "Running pre-install script..."
    sudo bash "$PRE_INSTALL_SCRIPT"
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

# Define the location of your web.txt file
WEB_FILE="/opt/app/web.txt"

# Function to display the information in a table format
display_web_info() {
    echo "---------------------------------------------"
    while IFS= read -r line; do
        # Use eval to expand the variables
        eval "echo \$line" | while IFS='=' read -r key value; do
            printf "| %-15s | %s\n" "$key" "$value"
        done
    done < "$WEB_FILE"
    echo "---------------------------------------------"
}

display_web_info

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
