#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Log file for recording events and errors
LOG_FILE="debug.log"

# Function to log messages to the log file
log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %T") - $message" >> "$LOG_FILE"
}

# Check if the script is run as root
check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}- - - - - - - - - - - - - - ${NC}"
        echo -e "${RED}| ${NC}Requires Root Privileges ${RED}|${NC}"
        echo -e "${RED}- - - - - - - - - - - - - - ${NC}"
        exit 1
    fi
}

# Check if figlet is installed and install it if not
install_figlet() {
    if ! command -v figlet &>/dev/null; then
        echo -e "${PURPLE}Installing Figlet${NC}"
        log_message "Installing Figlet"
        sleep 1
        sudo apt install -y figlet &>> "$LOG_FILE" || { echo -e "${RED}Failed to install figlet${NC}"; log_message "Failed to install figlet"; exit 1; }
    else
        echo -e "${GREEN}Figlet is already installed${NC}"
        log_message "Figlet is already installed"
    fi
}

# Setup function to update repositories, install dependencies and prepare script
setup_environment() {
    echo -e "${PURPLE}Updating Repositories${NC}"
    log_message "Updating Repositories"
    sleep 1
    sudo apt-get update &>> "$LOG_FILE" || { echo -e "${RED}Failed to update repositories${NC}"; log_message "Failed to update repositories"; exit 1; }
    sleep 1

    install_figlet

    sudo mkdir results

    sleep 1
    if [ -f "ebee-debee.sh" ]; then
        chmod +x ebee-debee.sh
        echo -e "${GREEN}Setup Completed Successfully!${NC}"
        log_message "Setup Completed Successfully"

        # Prompt user to run ebee-debee.sh
        echo -e "${YELLOW}- - - - - - - - - - - - - - - - - - - - - - -"
        read -p "Do you want to run ebee-debee.sh now? (y/n): " choice
        case "$choice" in
            y|Y ) ./ebee-debee.sh;;
            n|N ) echo -e "${YELLOW}You can run at any time with ./ebee-debee.sh${NC}";;
            * ) echo -e "${YELLOW}Invalid option. Please choose 'y' or 'n'.${NC}";;
        esac
    else
        echo -e "${RED}ebee-debee.sh file not found. Unable to set permissions.${NC}"
        log_message "ebee-debee.sh file not found. Unable to set permissions."
        exit 1
    fi
}

# Check if the script is run as root before continuing
check_privileges

# Execute the setup function
setup_environment
