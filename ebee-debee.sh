#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define menu options and title
MENU_TITLE="EBEE-DEBEE"
MENU_OPTIONS=("Network Sweep" "Exit")

# Define menu variables
TERM_WIDTH=0
MENU_WIDTH=0
PADDING=0

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

# help function
help_option() {
    echo -e "${PURPLE}- - - - - - - - - - - - - - - - - - - - - - - - -${NC}"
    echo -e "${PURPLE}| Usage: ./ebee-debee.sh [-h] [-i <interface>]  |${NC}"
    echo -e "${PURPLE}|                                               |${NC}"
    echo -e "${PURPLE}| -h        Display help message                |${NC}"
    echo -e "${PURPLE}| -i        Specify network interface           |${NC}"
    echo -e "${PURPLE}|                                               |${NC}"
    echo -e "${PURPLE}| Example: ./ebee-debee.sh -i eth0              |${NC}"
    echo -e "${PURPLE}- - - - - - - - - - - - - - - - - - - - - - - - -${NC}"

    log_message "Displaying help message."
    exit 0
}

# Parameter Validation
validate_interface() {
    local iface="$1"

    if ! ip link show "$iface" >/dev/null 2>&1; then
        echo -e "${RED}Invalid interface: $iface${NC}"
        log_message "Invalid interface: $iface"
        exit 1
    fi
}

sweep() {
    echo -e "${PURPLE}\n- - - - - - - - - - - - -${NC}"
    echo -e "${PURPLE}| Running Network Sweep |${NC}"
    echo -e "${PURPLE}- - - - - - - - - - - - -${NC}"
    log_message "Running Network Sweep."

    # Prompt user for network space and subnet, and verify the input
    while true; do
        echo -e "${YELLOW}\n"
        read -p "Enter the network space and subnet (e.g., 10.0.0.0/24): " network_subnet
        if [[ $network_subnet =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
            echo -e "${GREEN}Valid network space and subnet${NC}\n"
            log_message "Valid network space and subnet submitted: $network_subnet"
            break
        else
            echo -e "${RED}Invalid input. Please enter a valid network space and subnet (e.g., 10.0.0.0/24).${NC}\n"
            log_message "Invalid input entered for network space and subnet."
        fi
    done

    # Get current date
    current_date=$(date +"%Y-%m-%d_%H-%M-%S")

    # Define filename with current date
    filename="sweep-$current_date.txt"

    # Scan network for hosts and capture output
    scan_result=$(sudo nmap -sn "$network_subnet")
    echo -e "$scan_result\n" >> "results/$filename"

    # Extract number of hosts found
    num_hosts=$(echo "$scan_result" | grep -oP '\d+(?= hosts up)')

    # Extract IP addresses of hosts
    ip_addresses=$(echo "$scan_result" | grep -oP '\d+\.\d+\.\d+\.\d+')

    # Print number of hosts found and their IP addresses
    echo -e "${PURPLE}Number of hosts found: $num_hosts${NC}\n"
    log_message "Number of hosts found: $num_hosts"

    # Get the total number of IP addresses
    total_ips=$(echo "$ip_addresses" | wc -l)
    current_ip=1

    # Loop through each IP address and run sudo nmap -O
    for ip in $ip_addresses; do
        # Output to terminal
        echo -e "${PURPLE}Running nmap -A on IP $current_ip/$total_ips${NC}"
        log_message "Running nmap -A on IP $current_ip/$total_ips: $ip"

        # Output to sweep results file
        echo -e "- - - - - - - - - - - - - - - - - - - - - - - - - - HOST $current_ip/$total_ips RESULTS - - - - - - - - - - - - - - - - - - - - - - - - - -" >> "results/$filename"
        sudo nmap -A $ip >> "results/$filename"
        echo -e "\n" >> "results/$filename"

        ((current_ip++))
    done

    echo -e "\n${GREEN}Network sweep completed and results saved in $filename${NC}\n"
    log_message "Network sweep completed and results saved in $filename."
}

display_menu() {
    # Get terminal width
    TERM_WIDTH=$(tput cols)

    # Calculate center alignment
    MENU_WIDTH=40
    PADDING=$((($TERM_WIDTH - $MENU_WIDTH) / 2))

    # Print title centered
    echo
    figlet -w $TERM_WIDTH -c "$MENU_TITLE"
    echo
}

# Function to handle user input
handle_input() {
    # Print menu options centered
    echo
    for ((i = 0; i < ${#MENU_OPTIONS[@]}; i++)); do
        echo -e "$(printf '%*s' $PADDING)" "[$((i+1))] ${MENU_OPTIONS[$i]}"
    done

    log_message "Menu displayed."

    local option
    read -p "$(printf '%*s' $PADDING)> " option

    log_message "User input handled: $option"

    case $option in
        1) # Run Network Sweep
            sweep ;;
        2) # Close Program
            log_message "Closing ebee-debee"
            echo -e "\nShutting Down" && exit 0 ;;
        "exit") # Close Program
            log_message "Closing ebee-debee"
            echo -e "\nShutting Down" && exit 0 ;;
        *) # Default Case
            log_message "Invalid menu option"
            echo -e "${RED}\nInvalid option${NC}" ;;
    esac
}

# Main Script Logic
main() {
    log_message "Running ebee-debee"

    # Check if the script is run as root
    check_privileges

    local iface=""

    # Check if no arguments are provided
    if [ $# -eq 0 ]; then
        echo -e "${YELLOW}No arguments provided."
        log_message "No arguments provided."
        read -p "Enter network interface: " iface
    fi

    # Get the options
    while getopts "hi:" option; do
        case $option in
            h) # Help
                help_option ;;
            i) # Interface
                iface=$OPTARG ;;
            \?) # Invalid option
                echo -e "${RED}\nInvalid flag${NC}"
                echo -e "${RED}Use the -h option for help${NC}"
                log_message "Invalid flag."
                exit 1 ;;
        esac
    done

    validate_interface "$iface"

    echo -e "${GREEN}Interface $iface is valid.${NC}"
    log_message "Interface $iface is valid."
    sleep 1
    echo -e "${PURPLE}Starting ebee-debee${NC}"
    log_message "Starting ebee-debee."
    sleep 1

    clear

    display_menu

    while true; do
        handle_input
    done
}

# Execute the main function with provided arguments
main "$@"
