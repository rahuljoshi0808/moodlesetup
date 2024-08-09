#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_message "Starting Moodle installation script"

# Update and upgrade the system
log_message "Updating and upgrading the system"
sudo apt update && sudo apt upgrade -y

# Install Apache, PHP, and required extensions
log_message "Installing Apache, PHP, and required extensions"
sudo apt install -y apache2 php php-cli php-mysql php-xml php-curl php-gd php-mbstring php-xmlrpc php-soap php-intl php-zip

# Install MySQL client
log_message "Installing MySQL client"
sudo apt install -y mysql-client

# Enable Apache modules
log_message "Enabling Apache rewrite module"
sudo a2enmod rewrite

# Restart Apache
log_message "Restarting Apache"
sudo systemctl restart apache2

# Download Moodle
log_message "Downloading Moodle"
cd /tmp
wget https://download.moodle.org/download.php/direct/stable401/moodle-latest-401.tgz
if [ $? -ne 0 ]; then
    log_message "Failed to download Moodle. Exiting."
    exit 1
fi

log_message "Extracting Moodle archive"
tar -zxvf moodle-latest-401.tgz
if [ $? -ne 0 ]; then
    log_message "Failed to extract Moodle archive. Exiting."
    exit 1
fi

# Move Moodle to web root
log_message "Moving Moodle to web root"
sudo mv moodle /var/www/html/
if [ $? -ne 0 ]; then
    log_message "Failed to move Moodle to web root. Exiting."
    exit 1
fi

# Set permissions
log_message "Setting permissions for Moodle directory"
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 755 /var/www/html/moodle

# Create moodledata directory
log_message "Creating moodledata directory"
sudo mkdir -p /var/www/moodledata
sudo chown -R www-data:www-data /var/www/moodledata
sudo chmod -R 0777 /var/www/moodledata

# Create Moodle config.php
log_message "Creating Moodle config.php"
sudo -u www-data cp /var/www/html/moodle/config-dist.php /var/www/html/moodle/config.php

# Configure Moodle
log_message "Configuring Moodle"
sudo sed -i "s/example.com/$1/g" /var/www/html/moodle/config.php
sudo sed -i "s/username/$2/g" /var/www/html/moodle/config.php
sudo sed -i "s/password/$3/g" /var/www/html/moodle/config.php
sudo sed -i "s/moodle/moodledb/g" /var/www/html/moodle/config.php
sudo sed -i "s#dirname(__FILE__) . '/moodledata'#'/var/www/moodledata'#g" /var/www/html/moodle/config.php

# Explicitly set dataroot in config.php
echo "\$CFG->dataroot = '/var/www/moodledata';" | sudo tee -a /var/www/html/moodle/config.php

# Secure config.php
log_message "Securing config.php"
sudo chmod 400 /var/www/html/moodle/config.php

# Ensure Apache has necessary permissions
log_message "Ensuring Apache has necessary permissions"
sudo usermod -a -G www-data www-data

# Restart Apache again to apply all changes
log_message "Restarting Apache to apply all changes"
sudo systemctl restart apache2

log_message "Moodle installation completed. Please finish the setup by visiting http://your-vm-ip/moodle"
