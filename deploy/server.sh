#!/bin/sh

###
 # DNS upstream with new server
### 

set -x

OS_FLAVOR=$(cat /etc/os-release | grep ID | sed -n 1p |cut -d'=' -f2)
VERSION=$(cat /etc/os-release | grep VERSION_ID | sed -n 1p |cut -d'"' -f2)
centos=centos
ubuntu=ubuntu

src_dir=/usr/local/src
cur_dir=$(cd "$(dirname "$0")"; pwd)

DOMAIN=docs.w3cub.com

githubsource=https://github.com/w3cub/w3cub-release-202011


if [ "$OS_FLAVOR" = "$centos" ] && [ "$VERSION" -eq 7 ]; then
	echo "----------- Installing Dependacy for CentOS 7 ----------------- "
	yum groupinstall "Development Tools" -y
    yum install pcre pcre-devel zlib zlib-devel openssl openssl-devel -y
    yum install git wget
    yum install gcc gcc-c++  make automake autoconf -y

elif [ "$OS_FLAVOR" = "$ubuntu" ] && [ "${VERSION%%.*}" -ge 15 ]; then
    echo " Installing Dependacy for Ubuntu $VERSION"
    apt-get install build-essential -y # for gcc
    apt-get install libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev -y
    apt-get install git wget
    apt-get isntall make automake autoconf -y
else

	echo " Unsupported OS VERSION ...Try with CentOS 7 or ubuntu 15+ "
fi


if [ ! -f $src_dir/LuaJIT-2.1.0-beta3.tar.gz ] ; then
	`wget  https://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz`
fi

if [ ! -d $src_dir/LuaJIT-2.1.0-beta3 ] ; then
	tar -zxvf LuaJIT-2.1.0-beta3.tar.gz
fi 

if [ ! -d /usr/local/luajit ] ; then
	cd $src_dir/LuaJIT-2.1.0-beta3
	make && make install PREFIX=/usr/local/luajit
fi 


export LUAJIT_LIB=/usr/local/luajit/lib
export LUAJIT_INC=/usr/local/luajit/include/luajit-2.1

cd $src_dir

wget https://github.com/vision5/ngx_devel_kit/archive/v0.3.1.tar.gz  -O ngx_devel_kit.tar.gz

mkdir -p ngx_devel_kit && tar -zxvf ngx_devel_kit.tar.gz -C ngx_devel_kit --strip-components=1


cd $src_dir


wget https://github.com/openresty/lua-nginx-module/archive/v0.10.20.tar.gz -O lua-nginx-module.tar.gz

mkdir -p lua-nginx-module && tar -zxvf lua-nginx-module.tar.gz -C lua-nginx-module --strip-components=1

cd $src_dir


nginx_version=1.20.2  # Set the version you want to install

wget http://nginx.org/download/nginx-$nginx_version.tar.gz

tar -zxvf nginx-$nginx_version.tar.gz

cd nginx-$nginx_version/ || exit

./configure --sbin-path=/usr/bin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--with-pcre \
--pid-path=/var/run/nginx.pid \
--add-module=/usr/local/src/ngx_devel_kit \
--add-module=/usr/local/src/lua-nginx-module \
--with-http_ssl_module

make && make install

echo "::Check the configuration file exists or not::"

ls -lsrt /usr/bin/nginx || exit
nginx -V || exit


echo "::Create systemd service::"

cat <<EOT >> /lib/systemd/system/nginx.service
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target
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
sudo sh -c 'echo "
worker_processes  auto;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       80;
        server_name  $DOMAIN;
        root   /opt/www;
        error_page 404 /404.html;
        location / {
            index  index.html index.htm;
            try_files \$uri.html \$uri/ =404;
        }

        location /sync {
            if (\$host = $DOMAIN) {
               return 404;
            }
            content_by_lua_block {
               os.execute("sh /opt/deploy/sync.sh")
            }
        }
    }
}" > /etc/nginx/nginx.conf'


echo "::Download nginx request shell::"

cd /opt
mkdir -p deploy
cd /opt/deploy
wget https://raw.githubusercontent.com/w3cub/docshub/master/deploy/sync.sh -O sync.sh




echo "::::"

systemctl enable nginx && systemctl daemon-reload &&  systemctl start nginx

systemctl status nginx


echo "127.0.0.1 $DOMAIN" >> /etc/hosts


cd /opt

wget $githubsource/tarball/master -O www.tar.gz
mkdir -p www && tar -zxvf www.tar.gz -C www --strip-components=1


SUB=W3cubDocs
CONTENT=$(wget 127.0.0.1 -q -O -)
if [[ "$CONTENT" == *"$SUB"* ]]; then
  echo "Server is OK, bye."
  exit
fi
