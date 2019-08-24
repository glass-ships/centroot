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
    -t glasslabs/centroot:0.2 \
    -f Dockerfile .

unset DIR
