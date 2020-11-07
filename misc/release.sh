#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BASEDIR=$SCRIPTDIR/..
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "master" ]]; then
  printError 'Branch is not master. Aborting script';
  exit 1;
fi

# clone javaclay into temporary folder
TMP_DIR=$(mktemp -d)
git clone git@github.com:bsc-dom/javaclay.git $TMP_DIR

# create javadoc
pushd $TMP_DIR
mvn site -Ppublish
popd

# copy here and push
rm -rf $BASEDIR/javaclay/*
cp -r $TMP_DIR/target/site/* $BASEDIR/javaclay/

git add $BASEDIR/javaclay
git commit -m "New release"
git push

