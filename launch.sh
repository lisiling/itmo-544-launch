#!/bin/bash

aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $6 --security-group-ids $4 --subnet-id $5 --associate-public-ip-address --user-data file://itmo544-env/install-env.sh --debug
