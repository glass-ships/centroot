DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

if [ ! -e "$DIR/analysis-tools" ]; then
	git clone http://gitlab.com/glass-ships/analysis-tools.git

elif [ -d "$DIR/analysis-tools" ]; then
	cd $DIR/analysis-tools
	git pull
fi

cd $DIR
docker build \
    --rm \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    -t detlab/centroot:0.1 \
    -f Dockerfile .

unset DIR
