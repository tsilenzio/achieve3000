#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Update Package List
apt-get update

# Update System Packages
apt-get upgrade -y

# Force Locale
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8

# Install Some PPAs
apt-get install -y software-properties-common curl

apt-add-repository ppa:nginx/development -y
apt-add-repository ppa:ondrej/php -y

# Update Package Lists
apt-get update

# Install Some Basic Packages
apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev libpng-dev ntp unzip make python2.7-dev \
python-pip re2c supervisor unattended-upgrades whois vim libnotify-bin pv cifs-utils mcrypt bash-completion zsh \
graphviz avahi-daemon tshark imagemagick

# Set My Timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Install PHP Stuffs
apt-get install -y --allow-change-held-packages \
php7.3-cli php7.3-bcmath php7.3-curl php7.3-dev php7.3-gd php7.3-imap php7.3-intl  php7.3-json  php7.3-ldap \
php7.3-mbstring php7.3-mysql php7.3-odbc php7.3-phpdbg php7.3-pspell php7.3-soap php7.3-sqlite3 \
php7.3-xml php7.3-zip php7.3-readline php-memcached php-xdebug php-pear php-imagick php-redis

# Install Nginx & PHP-FPM
apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages nginx php7.3-fpm

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default

# Do Stuffz
rm /etc/nginx/nginx.conf
ln -sf /vagrant/conf/nginx.conf /etc/nginx/nginx.conf

rm -rf /etc/nginx/conf.d/*.conf
ln -sf /vagrant/conf/achieve3000.conf /etc/nginx/conf.d/achieve3000.conf

# Create a configuration file for Nginx overrides.
#sudo mkdir -p /home/vagrant/.config/nginx
#sudo chown -R vagrant:vagrant /home/vagrant
#touch /home/vagrant/.config/nginx/nginx.conf
#sudo ln -sf /home/vagrant/.config/nginx/nginx.conf /etc/nginx/conf.d/nginx.conf

# Setup Some PHP-FPM Options
echo "xdebug.remote_enable = 1" >> /etc/php/7.3/mods-available/xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php/7.3/mods-available/xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php/7.3/mods-available/xdebug.ini
echo "xdebug.max_nesting_level = 512" >> /etc/php/7.3/mods-available/xdebug.ini
echo "opcache.revalidate_freq = 0" >> /etc/php/7.3/mods-available/opcache.ini

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.3/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.3/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.3/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.3/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.3/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.3/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.3/fpm/php.ini

printf "[openssl]\n" | tee -a /etc/php/7.3/fpm/php.ini
printf "openssl.cainfo = /etc/ssl/certs/ca-certificates.crt\n" | tee -a /etc/php/7.3/fpm/php.ini

printf "[curl]\n" | tee -a /etc/php/7.3/fpm/php.ini
printf "curl.cainfo = /etc/ssl/certs/ca-certificates.crt\n" | tee -a /etc/php/7.3/fpm/php.ini

# Disable XDebug On The CLI
sudo phpdismod -s cli xdebug

# Copy fastcgi_params to Nginx because they broke it on the PPA
cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param	QUERY_STRING		\$query_string;
fastcgi_param	REQUEST_METHOD		\$request_method;
fastcgi_param	CONTENT_TYPE		\$content_type;
fastcgi_param	CONTENT_LENGTH		\$content_length;
fastcgi_param	SCRIPT_FILENAME		\$request_filename;
fastcgi_param	SCRIPT_NAME		\$fastcgi_script_name;
fastcgi_param	REQUEST_URI		\$request_uri;
fastcgi_param	DOCUMENT_URI		\$document_uri;
fastcgi_param	DOCUMENT_ROOT		\$document_root;
fastcgi_param	SERVER_PROTOCOL		\$server_protocol;
fastcgi_param	GATEWAY_INTERFACE	CGI/1.1;
fastcgi_param	SERVER_SOFTWARE		nginx/\$nginx_version;
fastcgi_param	REMOTE_ADDR		\$remote_addr;
fastcgi_param	REMOTE_PORT		\$remote_port;
fastcgi_param	SERVER_ADDR		\$server_addr;
fastcgi_param	SERVER_PORT		\$server_port;
fastcgi_param	SERVER_NAME		\$server_name;
fastcgi_param	HTTPS			\$https if_not_empty;
fastcgi_param	REDIRECT_STATUS		200;
EOF

# Set The Nginx & PHP-FPM User
sed -i "s/user www-data;/user vagrant;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sed -i "s/user = www-data/user = vagrant/" /etc/php/7.3/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = vagrant/" /etc/php/7.3/fpm/pool.d/www.conf

sed -i "s/listen\.owner.*/listen.owner = vagrant/" /etc/php/7.3/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = vagrant/" /etc/php/7.3/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.3/fpm/pool.d/www.conf

service nginx restart
service php7.3-fpm restart

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Vagrant User To WWW-Data
usermod -a -G www-data vagrant
id vagrant
groups vagrant

# Install SQLite
apt-get install -y sqlite3 libsqlite3-dev

# Install MySQL
echo "mysql-server mysql-server/root_password password secret" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password secret" | debconf-set-selections
apt-get install -y mysql-server

# Configure MySQL Password Lifetime
echo "default_password_lifetime = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf

# Configure MySQL Remote Access
sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
service mysql restart

# Create Achieve3000 database
mysql --user="root" --password="secret" -e "CREATE USER 'achieve3000'@'0.0.0.0' IDENTIFIED BY 'secret';"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'achieve3000'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'achieve3000'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"
mysql --user="root" --password="secret" -e "CREATE DATABASE achieve3000 character set UTF8mb4 collate utf8mb4_bin;"

sudo tee /home/vagrant/.my.cnf <<EOL
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_bin
EOL

# Add Timezone Support To MySQL
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=secret mysql
service mysql restart

# One last upgrade check
apt-get upgrade -y

# Clean Up
apt-get -y autoremove
apt-get -y clean
chown -R vagrant:vagrant /home/vagrant
chown -R vagrant:vagrant /usr/local/bin

# Add Composer Global Bin To Path
printf "\nPATH=\"$(sudo su - vagrant -c 'composer config -g home 2>/dev/null')/vendor/bin:\$PATH\"\n" | tee -a /home/vagrant/.profile
