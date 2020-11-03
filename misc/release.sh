#!/bin/bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "master" ]]; then
  printError 'Branch is not master. Aborting script';
  exit 1;
fi

# clone javaclay into temporary folder
TMP_DIR=$(mktemp -d)
git clone git@github.com:bsc-dom/javaclay.git $TMP_DIR

# create javadoc
cd $TMP_DIR
mvn site -Ppublish

# copy here and push
cp $TMP_DIR/target/site ./site

git add ./site
git commit -m "New release"
git push origin HEAD:master

