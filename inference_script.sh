#!/bin/bash

sudo apt-get update -y \
&& sudo apt-get install -y virtualenv openjdk-11-jdk gcc python3-dev

mkdir inference && cd inference
virtualenv --python=python3 inference
source inference/bin/activate

pip3 install \
torch torchtext torchvision sentencepiece psutil \
future wheel requests torchserve torch-model-archiver

mkdir torchserve-examples && cd torchserve-examples

git clone https://github.com/pytorch/serve.git

mkdir model_store

wget https://download.pytorch.org/models/fasterrcnn_resnet50_fpn_coco-258fb6c6.pth

torch-model-archiver --model-name fasterrcnn --version 1.0 \
--model-file serve/examples/object_detector/fast-rcnn/model.py \
--serialized-file fasterrcnn_resnet50_fpn_coco-258fb6c6.pth \
--handler object_detector \
--extra-files serve/examples/object_detector/index_to_name.json

mv fasterrcnn.mar model_store/

# Create a configuration file for Torchserve (config.properties) and 
# configure Torchserve to listen on your instance’s private IP

torchserve --start \
--model-store model_store \
--models fasterrcnn=fasterrcnn.mar \
--ts-config config.properties
