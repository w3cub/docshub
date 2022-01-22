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
NGINX_PREFIX=/usr/local/nginx
WORKDIR=/usr/local/src
cur_dir=$(cd "$(dirname "$0")"; pwd)

DOMAIN=t.w3cub.com

githubsource=https://github.com/w3cub/w3cubTools-alpha


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



cd $WORKDIR


wget -O lua.tar.gz https://github.com/openresty/luajit2/archive/v${LUA_JIT_VERSION}.tar.gz
tar -xf lua.tar.gz
cd luajit2-${LUA_JIT_VERSION}
make && make install


export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1


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


nginx_version=1.20.2  # Set the version you want to install

wget http://nginx.org/download/nginx-$nginx_version.tar.gz -O nginx-$nginx_version.tar.gz

tar -zxvf nginx-$nginx_version.tar.gz

cd nginx-$nginx_version/ || exit

./configure \
--with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" \
--prefix=$NGINX_PREFIX \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
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


cd $WORKDIR

wget -O lua-resty.tar.gz https://github.com/openresty/lua-resty-core/archive/v${LUA_RESTY_VERSION}.tar.gz
tar -xf lua-resty.tar.gz
cd lua-resty-core-${LUA_RESTY_VERSION}
sed -i "s/#LUA_VERSION/LUA_VERSION/" Makefile
make install PREFIX=$NGINX_PREFIX


cd $WORKDIR

wget -O lua-resty-lru.tar.gz https://github.com/openresty/lua-resty-lrucache/archive/v${LUA_RESTY_LRU_VERSION}.tar.gz
tar -xf lua-resty-lru.tar.gz
cd lua-resty-lrucache-${LUA_RESTY_LRU_VERSION}
sed -i "/PREFIX ?=/i LUA_VERSION := 5.1" Makefile
make install PREFIX=$NGINX_PREFIX

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
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/bin/nginx -t
ExecStart=/usr/bin/nginx
ExecReload=/usr/bin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOT

echo "::Config Nginx::"


cat >/etc/nginx/nginx.conf << EOF
user root;
worker_processes  auto;
events {
    worker_connections  1024;
}
http {
    lua_package_path "/usr/local/lib/lua/?.lua;;";
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

        location / {
            index  index.html index.htm;
            try_files \$uri \$uri/index.html \$uri.html =404;
        }

        location /sync {
            if (\$host = $DOMAIN) {
               return 404;
            }
            content_by_lua_block {
               ngx.header.content_type = "text/html" 
               ngx.say("<h1>Hello, World!</h1>")
               ngx.eof()
               os.execute("sh /opt/deploy/sync.sh")
            }
        }
    }
}
EOF

echo "::Download nginx request shell::"


echo "127.0.0.1 $DOMAIN" >> /etc/hosts

iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT

mkdir -p /opt/www


echo "it's OK" > /opt/www/index.html


systemctl enable nginx && systemctl daemon-reload &&  systemctl start nginx

systemctl status nginx
