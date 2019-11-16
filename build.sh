#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

IMG='glasslabs/centroot'
IMG_VER='0.2'

if [ ! -e "$DIR/analysis-tools" ]; then
	git clone http://gitlab.com/glass-ships/analysis-tools.git
elif [ -d "$DIR/analysis-tools" ]; then
	cd $DIR/analysis-tools
	git pull
fi

if [ ! -e "$DIR/bash-env" ]; then
    cd $DIR
    git clone http://gitlab.com/glass-ships/bash-env.git
elif [ -d "$DIR/bash-env" ]; then
    cd $DIR/bash-env
    git pull
fi

cd $DIR
if 
    docker build --rm \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    --tag $IMG:$IMG_VER \
    -f Dockerfile .; 
then
    docker push $IMG:$IMG_VER
else 
    echo -e "\e[31mERROR\e[0m: Docker build failed!"
fi

unset DIR
