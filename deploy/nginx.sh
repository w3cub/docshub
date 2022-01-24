#!/bin/sh

###
 # DNS load balancing with new server
### 

set -x

OS_FLAVOR=$(cat /etc/os-release | grep ID | sed -n 1p |cut -d'=' -f2)
VERSION=$(cat /etc/os-release | grep VERSION_ID | sed -n 1p |cut -d'"' -f2)
centos=centos
ubuntu=ubuntu
NDK_VERSION=0.3.1
NGINX_LUA_VERSION=0.10.20
NGINX_ECHO_VERSION=0.62
LUA_VERSION=5.1
LUA_JIT_VERSION=2.1-20220111
LUA_RESTY_VERSION=0.1.22
LUA_RESTY_LRU_VERSION=0.11
NGINX_VERSION=1.20.2  # Set the version you want to install
NGINX_PREFIX=/usr/local/nginx
WORKDIR=/usr/local/src
cur_dir=$(cd "$(dirname "$0")"; pwd)
ROOTDOMAIN=w3cub.com
EMAIL=gidcai@gmail.com
DOMAIN=docs.w3cub.com
WWW_SOURCE=https://github.com/w3cub/w3cub-release-202011
HTTP_ONLY=true



if [ "$OS_FLAVOR" = "$centos" ] && [ "$VERSION" -eq 7 ]; then
	echo "::Installing Dependacy for CentOS 7::"
	yum groupinstall "Development Tools" -y
    yum install pcre pcre-devel zlib zlib-devel openssl openssl-devel -y
    yum install git wget -y
    yum install gcc gcc-c++  make automake autoconf -y

elif [ "$OS_FLAVOR" = "$ubuntu" ] && [ "${VERSION%%.*}" -ge 15 ]; then
    echo " Installing Dependacy for Ubuntu $VERSION"
    apt-get install build-essential -y # for gcc
    apt-get install libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev -y
    apt-get install git wget -y
    apt-get install make automake autoconf -y
else

	echo " Unsupported OS VERSION ...Try with CentOS 7 or ubuntu 15+ "
fi

# stop nginx
systemctl stop nginx 
systemctl disable nginx

# remove all source
rm -rf $WORKDIR/*

#  remove old nginx
rm -rf /usr/local/nginx && rm -rf /usr/local/sbin/nginx
rm -rf /etc/nginx
rm -rf /etc/nginx/conf.d

rm -rf /usr/local/luajit
rm -rf /usr/local/lib/lua/5.1


# remove log
rm -rf /usr/local/nginx

rm -rf /var/log/nginx/error.log
rm -rf /var/log/nginx/access.log



cd $WORKDIR

wget -O luajit2.tar.gz https://github.com/openresty/luajit2/archive/v${LUA_JIT_VERSION}.tar.gz
tar -xf luajit2.tar.gz
cd luajit2-${LUA_JIT_VERSION}
make && make install

# ln -sf /usr/local/luajit/bin/luajit-2.1.0-beta3 /usr/local/bin/luajit


cd $WORKDIR

wget -O lua-resty.tar.gz https://github.com/openresty/lua-resty-core/archive/v${LUA_RESTY_VERSION}.tar.gz
tar -xf lua-resty.tar.gz
cd lua-resty-core-${LUA_RESTY_VERSION}
sed -i "s/#LUA_VERSION/LUA_VERSION/" Makefile
make && make install




cd $WORKDIR

wget -O lua-resty-lru.tar.gz https://github.com/openresty/lua-resty-lrucache/archive/v${LUA_RESTY_LRU_VERSION}.tar.gz
tar -xf lua-resty-lru.tar.gz
cd lua-resty-lrucache-${LUA_RESTY_LRU_VERSION}
sed -i "/PREFIX ?=/i LUA_VERSION := 5.1" Makefile
make && make install



cd $WORKDIR

wget https://github.com/vision5/ngx_devel_kit/archive/v${NDK_VERSION}.tar.gz  -O ngx_devel_kit.tar.gz

mkdir -p ngx_devel_kit && tar -zxvf ngx_devel_kit.tar.gz -C ngx_devel_kit --strip-components=1


cd $WORKDIR


wget https://github.com/openresty/lua-nginx-module/archive/v${NGINX_LUA_VERSION}.tar.gz -O lua-nginx-module.tar.gz

mkdir -p lua-nginx-module && tar -zxvf lua-nginx-module.tar.gz -C lua-nginx-module --strip-components=1

cd $WORKDIR

wget https://github.com/openresty/echo-nginx-module/archive/v${NGINX_ECHO_VERSION}.tar.gz -O echo-nginx-module.tar.gz

mkdir -p echo-nginx-module && tar -zxvf echo-nginx-module.tar.gz -C echo-nginx-module --strip-components=1


cd $WORKDIR


wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -O nginx-$NGINX_VERSION.tar.gz

tar -zxvf nginx-$NGINX_VERSION.tar.gz

cd nginx-$NGINX_VERSION/ || exit

mkdir -p /run
mkdir -p /var/run
mkdir -p /var/log/nginx/

export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1

./configure \
--with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" \
--prefix=$NGINX_PREFIX \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/run/nginx.pid \
--lock-path=/var/lock/nginx.lock \
--add-module=$WORKDIR/ngx_devel_kit \
--add-module=$WORKDIR/lua-nginx-module \
--add-module=$WORKDIR/echo-nginx-module \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_gzip_static_module \
--with-http_sub_module

make -j2 && make install

echo "::Check the configuration file exists or not::"

ls -lsrt /usr/bin/nginx || exit

nginx -V || exit


systemctl stop nginx 
systemctl disable nginx 

rm -rf /lib/systemd/system/nginx.service

echo "::Create systemd service::"

cat > /lib/systemd/system/nginx.service <<EOT
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/bin/nginx -t
ExecStart=/usr/bin/nginx
ExecReload=/usr/bin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOT


mkdir -p /etc/systemd/system/nginx.service.d

cat > /etc/systemd/system/nginx.service.d/override.conf <<EOT
[Service]
ExecStartPost=/bin/sleep 0.1
EOT

echo "::Config Nginx::"

config_nginx() {
    if [ ! -f /etc/nginx/nginx.conf ]; then
        echo "::Create nginx.conf::"
        if [ "$HTTP_ONLY" = "true" ]; then
            cat >/etc/nginx/nginx.conf << EOF
user root;
worker_processes  auto;
events {
    worker_connections  1024;
}
http {
    lua_package_path "/usr/local/lib/lua/$LUA_VERSION/?.lua;;";
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       80;
        server_name  $DOMAIN;
        root   /opt/www;
        error_page 404 /404.html;

        gzip             on;
        gzip_comp_level  3;
        gzip_types       text/plain text/css application/javascript image/*;

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

        location /sync {
            default_type 'text/html';
            if (\$host = $DOMAIN) {
               return 404;
            }
            content_by_lua_block {
               ngx.say("<h1>Hello, World!</h1>")
               ngx.eof()
               os.execute("sh /opt/deploy/sync.sh")
            }
        }
    }
}
EOF
        else

            certbot certonly --nginx --agree-tos -n -d $DOMAIN --email $EMAIL
            cat >/etc/nginx/nginx.conf << EOF
user root;
worker_processes  auto;
events {
    worker_connections  1024;
}
http {
    lua_package_path "/usr/local/lib/lua/$LUA_VERSION/?.lua;;";
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen 443 ssl; # managed by Certbot
        server_name  $DOMAIN;
        root   /opt/www;
        error_page 404 /404.html;

        gzip             on;
        gzip_comp_level  3;
        gzip_types       text/plain text/css application/javascript image/*;
        
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

        location /sync {
            default_type 'text/html';
            if (\$host = $DOMAIN) {
                return 404;
            }
            content_by_lua_block {
                ngx.say("<h1>Hello, World!</h1>")
                ngx.eof()
                os.execute("sh /opt/deploy/sync.sh")
            }
        }

        ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem; # managed by Certbot
        include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
    }

    server {
        listen          80;
        server_name     $DOMAIN;
        return          301 https://\$server_name\$request_uri;
    }
}
EOF
        fi
    fi  

}

config_nginx


echo "::Download nginx request shell::"


echo "127.0.0.1 $DOMAIN" >> /etc/hosts



mkdir -p /opt/www


echo "it's OK" > /opt/www/index.html


systemctl enable nginx && systemctl daemon-reload &&  systemctl start nginx

systemctl status nginx && exit

