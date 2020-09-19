#!/bin/bash
###### SET SSH
bash .travis/set_ssh_mn.sh
bash .travis/set_ssh_report.sh

git remote set-url origin git@github.com:bsc-dom/bsc-dom.github.io.git

# get test results
scp -r dataclay@mn1.bsc.es:~/testing/results/* ~/$TRAVIS_BUILD_NUMBER/allure-results/

HISTORY_DIR="allure-report/history"
if [ -d "$HISTORY_DIR" ]; then
	cp -R $HISTORY_DIR ~/$TRAVIS_BUILD_NUMBER/allure-results/history
fi

# remove previous report 
git rm -rf allure-report/*

# generate report 
allure generate ~/$TRAVIS_BUILD_NUMBER/allure-results -o allure-report --clean

# remove temp files
rm -rf ~/$TRAVIS_BUILD_NUMBER

# publish 
sed -i -e "s~base href=\"/\"~base href=\"/allure-report/\"~g" allure-report/index.html
git add -A
git commit -m "Updating test report from Travis build $TRAVIS_BUILD_NUMBER"
git push origin HEAD:master

# remove last test results
ssh dataclay@mn1.bsc.es "rm -rf testing/results/*"
