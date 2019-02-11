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

	git clone --recursive git@github.com:icai/docshub.git
	cd docshub 

    cd ./devdocs 
    thor docs:download --all # download all file

    cd ..
    cd ./docslogo
    sudo apt-get install imagemagick graphicsmagick
    npm install -d
    gulp beauty
    

    cd ..
    
    rake generate_html # generate jekyll base(sand) document
    rake copy_icons # copy docslogo icons to website
    rake copy_json # generate all json files
    rake copy_allhtml # generate all file to website
    cd ./website
    rake test_preview


## Release

	cd ./website
    rake badlink # output badlink url, you need to add in the `_config.yml` file `include` options 
	rake setup_gen # setup generate queue
 	rake multi_gen_deploy # project release
    rake sitemap  # generate sitemap

 


## License

This software is licensed under the terms of the Mozilla Public License v2.0. 




