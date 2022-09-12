

wget https://raw.githubusercontent.com/w3cub/docshub/master/deploy/openresty.sh -O openresty.sh && chmod +x openresty.sh

./openresty.sh

# download www file 

mkdir -p /opt/deploy && cd /opt/deploy

wget https://raw.githubusercontent.com/w3cub/docshub/master/deploy/gsync.sh -O sync.sh && chmod +x sync.sh

./sync.sh

# network

wget https://raw.githubusercontent.com/w3cub/docshub/master/deploy/network.sh -O network.sh && chmod +x network.sh

./network.sh


# download openresty conf

wget https://raw.githubusercontent.com/w3cub/docshub/master/deploy/conf.sh -O conf.sh && chmod +x conf.sh

./conf.sh
