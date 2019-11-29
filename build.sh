#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

IMG='glasslabs/centroot'
VER='0.3'

#if 
#  . scripts/clone-repos.sh
#then 
#  echo "Repositories successfully updated/cloned"
#else
#  echo -e "\e[31mERROR\e[0m cloning/updating repositories"
#  exit
#fi
#cd $DIR

if 
    docker build --rm \
    --tag $IMG:$VER \
    -f Dockerfile .;
    #--build-arg UID=$(id -u) \
    #--build-arg GID=$(id -g) \
then
  echo -e "\e[69mGREAT SUCCESS!\e[0m"  
  #docker push $IMG:VER
else 
  echo -e "\e[31mERROR\e[0m: Docker build failed!"
  exit
fi

unset DIR
