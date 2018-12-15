# Docshub
W3cubDocs API Documentation - [W3cubDocs](http://docs.w3cub.com/)



## Submodules


./
├── Gemfile
├── LICENSE
├── Rakefile
├── devdocs  [devdocs](https://github.com/icai/devdocs/) # Origin project 
├── docslogo [docslogo](https://github.com/icai/docslogo/) # Generate logos for index page 
├── lib
│   └── string.rb
├── merge
├── readme.md
└── website [website](https://github.com/icai/docshub/tree/source) # Jekyll project , which we need to convert static pages	  
 



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
	rake setup_gen # setup generate queue
 	rake multi_gen_deploy # project release

 


## License

This software is licensed under the terms of the Mozilla Public License v2.0. 




