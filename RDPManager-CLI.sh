#!/bin/bash
clear

PASSWORD_FILE="pwdb.conf"
CONFIG_FILE="config.conf"

check_and_create_config() {
    # Check if the config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Config file not found. Creating $CONFIG_FILE..."
        
        # Create the config file and add the initial content
        cat << EOF > "$CONFIG_FILE"
# Config file for frerdp-mgr

# Size of the virtual monitor
RDP_SIZE=1366x768

# Default Domain
DOMAIN=
EOF

        echo "$CONFIG_FILE has been created with default settings."
    else
        echo "$CONFIG_FILE already exists."
    fi
}

# Call the function
check_and_create_config

source $CONFIG_FILE

# Function to create an empty password.conf file
create_password_db() {
    clear
    if [ -f "$PASSWORD_FILE" ]; then
        echo "Password database file already exists."
        echo "Press Enter to return to the main menu..."
        read
    else
        printf "# Here put all of your passwords, or store them via the software\nExampleUser=ExamplePassword" > $PASSWORD_FILE
        echo "Password database file created."
        echo "Press Enter to return to the main menu..."
        read
    fi
}

# Function to retrieve a password for a username from password.conf
get_password_from_conf() {
    if [ -f "$PASSWORD_FILE" ]; then
        PASSWORD=$(grep "^$USERNAME=" "$PASSWORD_FILE" | cut -d '=' -f2)
    fi
}

# Function to prompt user for password and optionally save it
ask_and_save_password() {
    echo -n "Enter Password for $USERNAME -> "
    read -s PASSWORD
    echo ""

    # Ask if the user wants to save the password
    echo -n "Do you want to save this password for future use? (y/n) -> "
    read SAVE_CHOICE
    if [ "$SAVE_CHOICE" == "y" ]; then
        echo "$USERNAME=$PASSWORD" >> "$PASSWORD_FILE"
        echo "Password saved."
    else
        echo "Password not saved."
    fi
}

# Function to connect to the server
connect_to_server() {
    clear
    local USE_SAVED_DOMAIN

    # If DOMAIN is not empty, ask if the user wants to use the saved domain
    if [ -n "$DOMAIN" ]; then
        echo -e -n "\033[33mWARNING\033[0m: Domain is already filled out in configuration. Do you wish to use the one in it? (y/n) "
        read USE_SAVED_DOMAIN
        if [ "$USE_SAVED_DOMAIN" == "n" ]; then
            echo -n "Domain    -> "
            read DOMAIN
        fi
    else
        echo -n "Domain    -> "
        read DOMAIN
    fi

    echo -n "User Name -> "
    read USERNAME

    # Check if the password for the username exists in password.conf
    get_password_from_conf

    if [ -z "$PASSWORD" ]; then
        echo -e "\033[33mWARNING\033[0m: Password for $USERNAME not found in $PASSWORD_FILE."
        ask_and_save_password
    else
        echo -e "\033[33mWARNING\033[0m: Password for $USERNAME found in $PASSWORD_FILE."
        echo -n "Do you want to use the saved password? (y/n) -> "
        read USE_SAVED
        if [ "$USE_SAVED" == "n" ]; then
            ask_and_save_password
        fi
    fi

    echo ""
    echo "Connecting to the server..."

    # Execute the xfreerdp command with the provided inputs
    xfreerdp /v:"$DOMAIN" /u:"$USERNAME" /p:"$PASSWORD" /size:"$RDP_SIZE" /cert:tofu
    echo ""
    echo "Press Enter to return to the main menu..."
    read
}

# Main Menu
while true; do
    clear
    echo -e "\033[34mR\033[31mD\033[34mP\033[31mM\033[34ma\033[31mn\033[34ma\033[31mg\033[34me\033[31mr\033[34m-\033[31mC\033[34mL\033[31mI\033[0m - \033[35mhttps://github.com/senwawa/freerdp-mgr\033[0m"
    echo ""
    echo -e "1. \033[36mConnect\033[0m"
    echo -e "2. \033[36mCreate Password Database File\033[0m"
    echo -e "3. \033[36mExit\033[0m"
    echo ""
    echo -n -e "\033[35mChoose an option\033[0m -> "
    read MENU_CHOICE

    case $MENU_CHOICE in
        1)
            connect_to_server
            ;;
        2)
            create_password_db
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select 1, 2, or 3."
            ;;
    esac
done
