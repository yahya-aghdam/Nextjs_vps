#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m' 
COLOR_OFF='\033[0m' 


#############################


echo -e "$BLUE Updating VPS ===> $COLOR_OFF"

apt update && apt upgrade -y


#############################



echo -e "$BLUE Installing first deps ===> $COLOR_OFF"
apt install curl -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - &&\
apt-get install -y nodejs

apt install npm -y

npm i -g pm2 -y


############################

echo -e "$BLUE Configuring git ===> $COLOR_OFF"

# read and make folder dir
echo -e "$GREEN Enter you git account name: $COLOR_OFF"
read -r -p " " git_name

echo -e "$GREEN Enter you git email name: $COLOR_OFF"
read -r -p " " git_email

git config --global user.name "$git_name"
git config --global user.email "$git_email"




echo -e "$BLUE Install main next.js project ===> $COLOR_OFF"

echo -e "$GREEN Enter you git project link: $COLOR_OFF"
read -r -p " " git_proejct_link

mkdir /var/www/
cd /var/www/ 

git clone "$git_proejct_link"
project_dir_with_git_sign=${git_proejct_link##*/}
project_dir=${project_dir_with_git_sign%%.git}
cd "$project_dir"
chown -R $USER:$USER "/var/www/$project_dir"

###########################

echo -e "$BLUE Unpacking package.json and build project ===> $COLOR_OFF"

rm package-lock.json
npm i
# add your desire installation and configure here
npx prisma migrate dev -y
npm prisma generate
npx next build

###########################

echo -e "$BLUE Install and configure NginX + SSL ===> $COLOR_OFF"

apt install nginx
ufw allow 'Nginx Full'
rm /etc/nginx/sites-enabled/default



# ssl
nano /etc/ssl/cert.pem 
nano /etc/ssl/key.pem 

echo -e "$GREEN Enter your website domain name: $COLOR_OFF"
read -r -p " " domian_name

echo -e "$GREEN Enter the port of your nextjs project that running on it: $COLOR_OFF"
read -r -p " " port_name

echo "
server {
    listen 80;
    listen [::]:80;
    server_name $domian_name www.$domian_name;
    root /var/www/$domian_name;
    index index.html index.htm index.nginx-debian.html;
    return 302 https://\$server_name\$request_uri;
}
server {
    # SSL configuration
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl_certificate         /etc/ssl/cert.pem;
    ssl_certificate_key     /etc/ssl/key.pem;

    server_name $domian_name www.$domian_name;

    root /var/www/$domian_name;
    index index.php  index.html index.htm index.nginx-debian.html;

    location / {            
        proxy_set_header X-FORWARD-FOR \$remote_addr;
        proxy_set_header Host \$http_host;
        proxy_pass http://localhost:$port_name;
    }
    
    # next 12 upgrade
    location /_next/webpack-hmr {
    	proxy_pass http://localhost:$port_name/_next/webpack-hmr;
    	proxy_http_version 1.1;
    	proxy_set_header Upgrade \$http_upgrade;
    	proxy_set_header Connection '"upgrade"';
    }

    location ~ /\.ht {
        deny all;
    }


}" > /etc/nginx/sites-available/"$domian_name"


ln -s /etc/nginx/sites-available/"$domian_name" /etc/nginx/sites-enabled/
unlink /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx


###########################

echo -e "$BLUE Add project to pm2 and save it ===> $COLOR_OFF"

echo -e "$GREEN Enter your project name in pm2: $COLOR_OFF"
read -r -p " " pm2_name
pm2 start npm --name="$pm2_name" -- start

# save pm2
pm2 startup
pm2 save

##########################

echo -e "$BLUE Change default path of terminal to project path ===> $COLOR_OFF"

# change terminal default path
echo "cd /var/www/$project_dir" >> ~/.bashrc

# make executable itself
# chmod +x "$0"
