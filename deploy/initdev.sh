cd ./devdocs
bundle install
thor docs:download --default # download all file

cd ..
cd ./docslogo
npm install -d
gulp beauty