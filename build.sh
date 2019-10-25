DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

if [ ! -e "$DIR/analysis-tools" ]; then
	git clone http://gitlab.com/glass-ships/analysis-tools.git

elif [ -d "$DIR/analysis-tools" ]; then
	cd $DIR/analysis-tools
	git pull
fi

DOCKER_IMG='glasslabs/centroot'
IMAGE_VER='0.2'

cd $DIR
if docker build  --rm \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    --tag $DOCKER_IMG:$IMAGE_VER \
    -f Dockerfile . ; then
    docker push $DOCKER_IMG:$IMAGE_VER
else echo -e "\e[31mError\e[0m\]: Docker build failed!"
fi

unset DIR
