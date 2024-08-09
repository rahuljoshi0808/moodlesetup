#!/bin/bash
set -e

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/moodle_install.log
}

log "Starting Moodle installation"

# Update and install dependencies
log "Updating system and installing dependencies"
sudo apt update && sudo apt upgrade -y
sudo apt install -y apache2 mysql-client php php-cli php-mysql php-xml php-curl php-gd php-mbstring php-xmlrpc php-soap php-intl php-zip

# Configure Apache
log "Configuring Apache"
sudo a2enmod rewrite
sudo systemctl restart apache2

# Download and extract Moodle
log "Downloading and extracting Moodle"
cd /tmp
wget https://download.moodle.org/download.php/direct/stable401/moodle-latest-401.tgz
tar -zxvf moodle-latest-401.tgz

# Move Moodle to web root
log "Moving Moodle to web root"
sudo mv moodle /var/www/html/

# Create and configure moodledata directory
log "Creating and configuring moodledata directory"
sudo mkdir -p /var/moodledata
sudo chown -R www-data:www-data /var/moodledata
sudo chmod -R 777 /var/moodledata

# Set permissions for Moodle directory
log "Setting permissions for Moodle directory"
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 755 /var/www/html/moodle

# Create and configure config.php
log "Creating and configuring config.php"
sudo -u www-data cp /var/www/html/moodle/config-dist.php /var/www/html/moodle/config.php
sudo sed -i "s/pgsql/mysqli/g" /var/www/html/moodle/config.php
sudo sed -i "s/example.com/$1/g" /var/www/html/moodle/config.php
sudo sed -i "s/username/$3/g" /var/www/html/moodle/config.php
sudo sed -i "s/password/$4/g" /var/www/html/moodle/config.php
sudo sed -i "s/localhost/$2/g" /var/www/html/moodle/config.php
sudo sed -i "s/moodle/moodledb/g" /var/www/html/moodle/config.php
sudo sed -i "s#//      \$CFG->dataroot  = '/home/example/moodledata';#\$CFG->dataroot  = '/var/moodledata';#" /var/www/html/moodle/config.php

# Secure config.php
log "Securing config.php"
sudo chmod 400 /var/www/html/moodle/config.php

# Verify moodledata directory
log "Verifying moodledata directory"
ls -ld /var/moodledata
sudo -u www-data touch /var/moodledata/test_file
if [ $? -eq 0 ]; then
    log "www-data can write to moodledata directory"
    sudo rm /var/moodledata/test_file
else
    log "ERROR: www-data cannot write to moodledata directory"
    exit 1
fi

# Verify Moodle config
log "Verifying Moodle config"
grep dataroot /var/www/html/moodle/config.php

log "Moodle installation completed. Please finish the setup by visiting http://$1/moodle"
