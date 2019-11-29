#! /bin/bash
#DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

mkdir -p $DIR/repos/Analysis
mkdir -p $DIR/data 

# misc. repos
cd $DIR/repos
if [ ! -e "bash-env" ]; then
  git clone http://gitlab.com/glass-ships/bash-env.git
elif [ -d "$DIR/repos/bash-env" ]; then
  cd bash-env
  git pull
fi

### CDMS repos
export CDMSGIT="git@gitlab.com:supercdms"

# analysis code
cd $DIR/repos

repos=(
  "Analysis/pyCAP"
  "Analysis/scdmsPyTools"
)

for repo in "${repos[@]}"; do
  if [ -d "$repo" ] && [ -d "$repo/.git" ]; then  
    cd $repo
    git pull
    git submodule update --init --recursive
  elif [ ! -e "$repo" ]; then
    cd $DIR/repos/Analysis
    git clone --recursive "$CDMSGIT/$repo.git"
  fi  
done

# reference data
cd $DIR/data

data=(
  "ReferenceData/pyCAP_reference_data"
  "ReferenceData/pyTools_reference_data"
)

for data in "${data[@]}"; do
  export data=$( echo "$data" | sed 's:.*/::' )
  if [ -d "$data" ] && [ -d "$data/.git" ]; then
    cd $data
    git pull
    cd ..
  elif [ ! -e "$data" ]; then
    git clone --recursive $CDMSGIT/$data.git
  fi
  unset data
done
