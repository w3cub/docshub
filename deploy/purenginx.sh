
set -x

DOMAIN=docs.w3cub.com


apt update

apt install nginx -y
systemctl status nginx
ufw allow http
ufw reload

systemctl stop nginx


unlink /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/w3cub.conf << EOF
   server {
      listen 80;
      listen [::]:80;
      server_name  $DOMAIN;
      root   /var/www/html;
      error_page 404 /404.html;

      location ~ /\. {
          return 404;
          access_log off;
          log_not_found off;
      }
      
      location ~* /(README|README\.md) {
          return 404;
          access_log off;
          log_not_found off;
      }

      location / {
          index  index.html index.htm;
          try_files \$uri \$uri/index.html \$uri.html =404;
      }
    }
EOF

ln -s /etc/nginx/sites-available/w3cub.conf /etc/nginx/sites-enabled/


echo "127.0.0.1 $DOMAIN" >> /etc/hosts
echo "::1 $DOMAIN" >> /etc/hosts


systemctl enable nginx
systemctl daemon-reload
systemctl restart nginx
