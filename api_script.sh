#!/bin/bash

curl -O https://s3.amazonaws.com/model-server/inputs/kitten.jpg

curl -X POST \
http://<your_inf_server_internal_IP>:8080/predictions/fasterrcnn \
-T kitten.jpg

sudo apt-get update -y \
&& sudo apt-get install -y \
libsm6 libxrender1 libfontconfig1 virtualenv

mkdir apiserver && cd apiserver
git clone https://github.com/mikegcoleman/flask_wavelength_api .

virtualenv --python=python3 apiserver
source apiserver/bin/activate

pip3 install opencv-python flask pillow requests flask-cors

