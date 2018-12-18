
cd ./devdocs
pwd
bundle install
bundle exec thor docs:download --default # download all file

cd ..
cd ./docslogo
npm install -d
gulp beauty