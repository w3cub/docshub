# Docshub
W3cubDocs API Documentation - [W3cubDocs](http://docs.w3cub.com/)



##Submodules


.   
├── [devdocs](https://github.com/icai/devdocs/) # Origin project    
├── [docslogo](https://github.com/icai/tech-logo/) # Generate logos for index page    
└── [website](https://github.com/icai/docshub/tree/source) # Jekyll project , which we need to convert static pages	   



##Usage

	git clone --recursive git@github.com:icai/docshub.git
	cd docshub 

    cd ./devdocs 
    thor docs:download --all # download all file
    cd ..
    rake copy_allhtml # generate all file to website
    cd ./website
    rake test_preview


##Release

	cd ./website
 	rake multi_gen_deploy # project preview


##License

This software is licensed under the terms of the Mozilla Public License v2.0. 




