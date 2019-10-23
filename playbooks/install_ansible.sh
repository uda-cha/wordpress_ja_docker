#!/bin/bash

yum install -y https://centos7.iuscommunity.org/ius-release.rpm
yum install -y python3-3.6.8-10.el7

set -e
python3.6 --version
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.6 get-pip.py
/usr/local/bin/pip3.6 install ansible==2.8.4
