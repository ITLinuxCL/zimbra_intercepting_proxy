#!/bin/bash
##

VERSION=`grep VERSION lib/zimbra_intercepting_proxy/version.rb | awk '{print $3}' | sed 's/"//g'`
docker build --tag itlinuxcl/zimbra_zip:$VERSION .

IMAGE_ID=`docker images | grep zimbra_zip | grep $VERSION | awk '{print $3}'`

docker tag $IMAGE_ID itlinuxcl/zimbra_zip:latest