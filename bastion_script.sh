#!/bin/bash

git clone https://github.com/mikegcoleman/react-wavelength-inference-demo.git

cd react-wavelength-inference-demo && npm install

npm run build

cp -r ./build/* /home/bitnami/htdocs

