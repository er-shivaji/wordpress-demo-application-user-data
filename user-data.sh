ubuntu@ip-172-31-40-211:/mnt$ sudo cat install1.sh 
#!/bin/bash -xe

# Setpassword & DB Variables
DBName='Your-db'
DBUser='Your-username'
DBPassword='your-pass'
DBRootPassword='your-pass'
#DBEndpoint='RDS_DB_ENDPOINT'

# System Updates
apt-get update
apt-get upgrade -y

# Add repository for PHP 8.1
add-apt-repository ppa:ondrej/php -y
apt-get update

# STEP 2 - Install system software - including Web and DB
apt install -y mariadb-server apache2 php8.1 php8.1-mysql

# STEP 3 - Web and DB Servers Online - and set to startup
systemctl enable apache2
systemctl enable mariadb
systemctl start apache2
systemctl start mariadb

# STEP 4 - Set Mariadb Root Password
mysqladmin -u root password $DBRootPassword

# STEP 5 - Install Wordpress
wget http://wordpress.org/latest.tar.gz -P /var/www/html
cd /var/www/html
tar -zxvf latest.tar.gz
cp -rvf wordpress/* .
rm -R wordpress
rm latest.tar.gz

# STEP 6 - Configure Wordpress
cp ./wp-config-sample.php ./wp-config.php
sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
#sed -i "s/'localhost'/'$DBEndpoint'/g" wp-config.php

# Step 6a - permissions 
usermod -a -G www-data ubuntu   
chown -R ubuntu:www-data /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

# STEP 7 Create Wordpress DB
echo "CREATE DATABASE $DBName;" >> /tmp/db.setup
echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup
echo "FLUSH PRIVILEGES;" >> /tmp/db.setup
mysql -u root --password=$DBRootPassword < /tmp/db.setup
sudo rm /tmp/db.setup
