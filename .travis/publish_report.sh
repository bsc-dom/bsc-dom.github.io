#!/bin/bash
###### SET SSH
bash .travis/set_ssh_mn.sh
bash .travis/set_ssh_report.sh

git remote set-url origin git@github.com:bsc-dom/bsc-dom.github.io.git
last_tests=$(ssh dataclay@mn1.bsc.es "ls -td testing/results/* | head -1")

# remove previous report 
git rm -rf allure-report/*

# generate report 
mkdir ~/$TRAVIS_BUILD_NUMBER/allure-results/
scp -r dataclay@mn1.bsc.es:~/$last_tests/* ~/$TRAVIS_BUILD_NUMBER/allure-results/
ls -la ~/$TRAVIS_BUILD_NUMBER/allure-results
cp -R allure-report/history ~/$TRAVIS_BUILD_NUMBER/allure-results/history
allure generate ~/$TRAVIS_BUILD_NUMBER/allure-results -o allure-report --clean
rm -rf ~/$TRAVIS_BUILD_NUMBER

# publish 
sed -i -e "s~base href=\"/\"~base href=\"/allure-report/\"~g" allure-report/index.html
git add -A
git commit -m "Updating test report from Travis build $TRAVIS_BUILD_NUMBER"
git push origin HEAD:master

# remove last test results
ssh dataclay@mn1.bsc.es "rm -rf $last_tests"
