#!/bin/bash

gh repo clone scorpio-demon/nextjs_vps

apt update && apt upgrade -y

curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install nodejs -y

apt install npm -y

npm i -g pm2 -y


# read and make folder dir
read -r -p "Enter you git account name: " git_name
read -r -p "Enter you git email name: " git_email

git config --global user.name "$git_name"
git config --global user.email "$git_email"

read -r -p "Enter you git project link: " git_proejct_link

cd /var/www/ 

git clone "$git_proejct_link"
project_dir_with_git_sign=${git_proejct_link##*/}
project_dir=${project_dir_with_git_sign%%.git}
cd "$project_dir"
chown -R $USER:$USER "/var/www/$project_dir"

# enter pass




npm i
npx prisma generate
npx prisma migrate deploy -y
npx prisma migrate dev -y
npm run build



apt install nginx
ufw allow 'Nginx Full'
rm /etc/nginx/sites-enabled/default

# ssl
nano /etc/ssl/cert.pem 
nano /etc/ssl/key.pem 

read -r -p "Enter your website domain name: " domian_name
read -r -p "Enter the port nextjs running: " port_name

echo "
server {
    listen 80;
    listen [::]:80;
    server_name $domian_name www.$domian_name;
    root /var/www/$domian_name;
    index index.html index.htm index.nginx-debian.html;
    return 302 https://$server_name$request_uri;
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
        proxy_set_header X-FORWARD-FOR $remote_addr;
        proxy_set_header Host $http_host;
        proxy_pass http://localhost:$port_name;
    }
    
    # next 12 upgrade
    location /_next/webpack-hmr {
    	proxy_pass http://localhost:$port_name/_next/webpack-hmr;
    	proxy_http_version 1.1;
    	proxy_set_header Upgrade $http_upgrade;
    	proxy_set_header Connection "upgrade";
    }

    location ~ /\.ht {
        deny all;
    }


}" > /etc/nginx/sites-available/"$domian_name"


ln -s /etc/nginx/sites-available/"$domian_name" /etc/nginx/sites-enabled/
unlink /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx


read -r -p "Enter your project name in pm2: " pm2_name
pm2 start npm --name="$pm2_name" -- start

# save pm2
pm2 startup
pm2 save


# change terminal default path
echo "cd /var/www/$project_dir" >> ~/.bashrc

# make executable itself
chmod +x "$0"
