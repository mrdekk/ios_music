#!/bin/bash
docker run -it --name flute -v `pwd`:/opt/midi gcr.io/tensorflow/tensorflow bash
