<!--
 * @Author: Terry Cai
 * @Date: 2020-11-20 23:54:23
 * @LastEditors: Terry Cai
 * @LastEditTime: 2022-01-24 22:57:51
 * @Description: Do not edit
-->
# Docshub
W3cubDocs API Documentation - [W3cubDocs](http://docs.w3cub.com/)


## Submodules

```md
./   
├── [devdocs](https://github.com/w3cub/devdocs/) # Origin project   
├── [docslogo](https://github.com/w3cub/docslogo/) # Generate logos for index page
└── [website](https://github.com/w3cub/docsgen/) # Jekyll project , which we need to convert static pages	
```  

 



## Usage

```shell
sudo apt install curl nodejs

# firewall user  

export http_proxy=http://127.0.0.1:1080 && export https_proxy=$http_proxy && export ALL_PROXY=$http_proxy

# rvm

\curl -sSL https://get.rvm.io | bash -s stable

rvm install "ruby-2.6.5"

git clone --recursive git@github.com:icai/docshub.git
cd docshub 

cd ./devdocs 
gem install bundler
bundle install

thor docs:download --all # download all file

thor sprites:generate

cd ..
cd ./docslogo
sudo apt-get install imagemagick graphicsmagick
npm install -d
gulp beauty


cd ..

# dev test

# try diff and synchronize the javascript, image and stylesheet files

bundle install
rake copy_json # generate all json files
rake copy_all # to copy the other file
    # - rake copy_icons # copy docslogo icons to website
    # - rake copy_json # generate all json files
rake copy_test # generate all file to website
cd ./website
rake erb # icon file
rake test_preview

# deploy test
bundle install
rake generate_html # generate jekyll base(sand) document
rake copy_icons # copy docslogo icons to website
rake copy_json # generate all json files
rake copy_allhtml # generate all file to website
cd ./website
rake test_preview
```

## Release

```shell
cd ./website
rake badlink # output badlink url, you need to add in the `_config.yml` file `include` options 
rake erb
rake setup_gen  # [option] setup generate queue
rake gitinit # [option]
rake multi_gen_deploy # project release
rake sitemap  # generate sitemap
rake push
```


## Deploy New Server

```sh

# nginx

wget https://raw.githubusercontent.com/w3cub/docshub/master/deploy/nginx.sh -O nginx.sh \
&& mkdir -p /opt/deploy && cd /opt/deploy  \
&& wget https://raw.githubusercontent.com/w3cub/docshub/master/deploy/gsync.sh -O sync.sh

```

### download file to nginx workplace

```sh

# download file 

wget https://raw.githubusercontent.com/w3cub/docshub/master/deploy/gsync.sh -O sync.sh && chmod +x sync.sh



# download openresty conf

wget https://raw.githubusercontent.com/w3cub/docshub/master/deploy/conf.sh -O conf.sh && chmod +x conf.sh

```




## License

This software is licensed under the terms of the Mozilla Public License v2.0. 




