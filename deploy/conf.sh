DOMAIN=docs.w3cub.com

cat >/usr/local/openresty/nginx/conf/nginx.conf << EOF
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

# ipv4
echo "127.0.0.1 $DOMAIN" >> /etc/hosts

# ipv6
echo "::1 $DOMAIN" >> /etc/hosts
