#!/bin/bash
EFS_MOUNT= "${EFS_MOUNT}"

DB_NAME= "${DB_NAME}"
DB_HOSTNAME= "${DB_HOSTNAME}"
DB_USERNAME= "${DB_USERNAME}"
DB_PASSWORD= "${DB_PASSWORD}"

WP_ADMIN="wordpressadmin"
WP_PASSWORD="wordpressadminn"

LB_HOSTNAME="${LB_HOSTNAME}"

# sudo apt update
# sudo apt install nginx
# sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $EFS_MOUNT:/ /usr/share/nginx/html/
# sudo touch /usr/share/nginx/html/index.html
# sudo echo 'Hello, this is my website' >> /usr/share/nginx/html/index.html
# sudo systemctl nginx start

# sudo apt update -y
# sudo apt install -y httpd
# sudo systemctl httpd start
# wget https://wordpress.org/latest.tar.gz
# tar -xzf latest.tar.gz
# cd wordpress
# cp wp-config-sample.php wp-config.php

# cat <<EOF > wp-config.php
# define( 'DB_NAME', $DB_NAME );

# define( 'DB_USER', $DB_USERNAME );

# define( 'DB_PASSWORD', $DB_PASSWORD );

# define( 'DB_HOST', $DB_HOSTNAME );

# define('AUTH_KEY',         'aaaaaaaaaaaaaaaaaaa');
# define('SECURE_AUTH_KEY',  'aaaaaaaaaaaaaaaaaaa');
# define('LOGGED_IN_KEY',    'aaaaaaaaaaaaaaaaaaa');
# define('NONCE_KEY',        'aaaaaaaaaaaaaaaaaaa');
# define('AUTH_SALT',        'aaaaaaaaaaaaaaaaaaa');
# define('SECURE_AUTH_SALT', 'aaaaaaaaaaaaaaaaaaa');
# define('LOGGED_IN_SALT',   'aaaaaaaaaaaaaaaaaaa');
# define('NONCE_SALT',       'aaaaaaaaaaaaaaaaaaa');
# EOF

# #Deploy wp
# sudo apt install -y php7.0 libapache2-mod-php7.0 php7.0-mysql php7.0-xml php7.0-gd
# sudo apt install -y php7.0-mysql mariadb-server mariadb-client
# cd /home/ec2-user
# sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $EFS_MOUNT:/ /var/www/html
# sudo cp -r wordpress/* /var/www/html/
# sudo service httpd restart
cd /home/ubuntu
sudo apt update -y 
sudo apt install -y nginx 
sudo systemctl start nginx
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $EFS_MOUNT:/ /usr/share/nginx/html