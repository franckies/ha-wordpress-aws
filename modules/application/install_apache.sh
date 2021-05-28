#!/bin/bash -xe

EFS_MOUNT="${EFS_MOUNT}"

DB_NAME="${DB_NAME}"
DB_HOSTNAME="${DB_HOSTNAME}"
DB_USERNAME="${DB_USERNAME}"
DB_PASSWORD="${DB_PASSWORD}"

WP_ADMIN="wordpressadmin"
WP_PASSWORD="wordpressadminn"

LB_HOSTNAME="${LB_HOSTNAME}"


sudo yum update -y
sudo yum install -y httpd
sudo service httpd start
#sudo yum install nfs-utils -y -q Should be already installed in aws linux 2 ami
# Mounting Efs 
sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${EFS_MOUNT}:/  /var/www/html
# Making Mount Permanent
echo ${EFS_MOUNT}:/ /var/www/html nfs4 defaults,_netdev 0 0  | sudo cat >> /etc/fstab
sudo chmod go+rw /var/www/html

# Install wordpress
sudo wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

# Deploy wordpress
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo cp -r wordpress/* /var/www/html/
sudo curl -o /bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x /bin/wp
# Insert DB info to wordpress config file and install theme
cd /var/www/html
sudo wp core download --version='4.9' --locale='en_GB' --allow-root

# Loop until config wordpress file is created
while [ ! -f /var/www/html/wp-config.php ]
do
    cd /var/www/html 
    sudo wp core config --dbname="$DB_NAME" --dbuser="$DB_USERNAME" --dbpass="$DB_PASSWORD" --dbhost="$DB_HOSTNAME" --dbprefix=wp_ --allow-root
    sleep 2
done

sudo wp core install --url="http://$LB_HOSTNAME" --title='HA Wordpress on AWS' --admin_user="$WP_ADMIN" --admin_password="$WP_PASSWORD" --admin_email='admin@example.com' --allow-root


# Restart httpd
sudo chkconfig httpd on
sudo service httpd start
sudo service httpd restart
#Restart httpd after a while
setsid nohup "sleep 480; sudo service httpd restart" &