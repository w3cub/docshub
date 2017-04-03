# Docshub
W3cubDocs API Documentation - [W3cubDocs](http://docs.w3cub.com/)



## Submodules


.   
├── [devdocs](https://github.com/icai/devdocs/) # Origin project    
├── [docslogo](https://github.com/icai/tech-logo/) # Generate logos for index page    
└── [website](https://github.com/icai/docshub/tree/source) # Jekyll project , which we need to convert static pages	   



## Usage

	git clone --recursive git@github.com:icai/docshub.git
	cd docshub 

    cd ./devdocs 
    thor docs:download --all # download all file
    cd ..
    rake copy_allhtml # generate all file to website
    cd ./website
    rake test_preview


## Release

	cd ./website
	rake setup_gen # setup generate queue
 	rake multi_gen_deploy # project release

 

## Jekyll Case

> ... is invalid because it contains a colon https://github.com/jekyll/jekyll/issues/5261


You should go to path `ruby-2.*.*/gems/jekyll-3.*.*/lib/jekyll/url.rb`, 
comment the code like the following:

    def to_s
      sanitize_url(generated_permalink || generated_url)
      # sanitized_url = sanitize_url(generated_permalink || generated_url)
      # if sanitized_url.include?(":")
      #   raise Jekyll::Errors::InvalidURLError,
      #     "The URL #{sanitized_url} is invalid because it contains a colon."
      # else
      #   sanitized_url
      # end


## License

This software is licensed under the terms of the Mozilla Public License v2.0. 




