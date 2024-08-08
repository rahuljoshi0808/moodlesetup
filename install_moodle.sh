#!/bin/bash

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install Apache, PHP, and required extensions
sudo apt install -y apache2 php php-cli php-mysql php-xml php-curl php-gd php-mbstring php-xmlrpc php-soap php-intl php-zip

# Install MySQL client
sudo apt install -y mysql-client

# Enable Apache modules
sudo a2enmod rewrite

# Restart Apache
sudo systemctl restart apache2

# Download Moodle
cd /tmp
wget https://download.moodle.org/stable401/moodle-latest-401.tgz
tar -zxvf moodle-latest-401.tgz

# Move Moodle to web root
sudo mv moodle /var/www/html/

# Set permissions
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 755 /var/www/html/moodle

# Create moodledata directory
sudo mkdir /var/www/moodledata
sudo chown -R www-data:www-data /var/www/moodledata
sudo chmod -R 777 /var/www/moodledata

# Create Moodle config.php
sudo -u www-data cp /var/www/html/moodle/config-dist.php /var/www/html/moodle/config.php

# Configure Moodle
sudo sed -i "s/example.com/$1/g" /var/www/html/moodle/config.php
sudo sed -i "s/username/$2/g" /var/www/html/moodle/config.php
sudo sed -i "s/password/$3/g" /var/www/html/moodle/config.php
sudo sed -i "s/moodle/moodledb/g" /var/www/html/moodle/config.php
sudo sed -i "s#dirname(__FILE__) . '/moodledata'#'/var/www/moodledata'#g" /var/www/html/moodle/config.php

# Secure config.php
sudo chmod 400 /var/www/html/moodle/config.php

echo "Moodle installation completed. Please finish the setup by visiting http://your-vm-ip/moodle"
