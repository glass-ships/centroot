#! /bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

mkdir -p $DIR/repos

# misc. repos
cd $DIR/repos
if [ ! -e "bash-env" ]; then
  git clone http://gitlab.com/glass-ships/glass-bash.git bash-env
elif [ -d "$DIR/repos/bash-env" ]; then
  cd bash-env
  git pull
fi
