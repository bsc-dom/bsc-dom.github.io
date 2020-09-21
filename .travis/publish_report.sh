#!/bin/bash
###### SET SSH
bash .travis/set_ssh_mn.sh
bash .travis/set_ssh_report.sh

git remote set-url origin git@github.com:bsc-dom/bsc-dom.github.io.git

# get test results
mkdir -p ~/$TRAVIS_BUILD_NUMBER/allure-results
mkdir /tmp/allure-results/
scp -r dataclay@mn1.bsc.es:~/testing/results/* /tmp/allure-results/
BUILD_NUMBER=$(ssh dataclay@mn1.bsc.es "cd ~/testing/results/ && ls -td -- * | head -1")

# for each copied directory move it to allure-results 
for TESTING_JOB_DIR in /tmp/allure-results/ ; do
    cp $TESTING_JOB_DIR/* ~/$TRAVIS_BUILD_NUMBER/allure-results/
done

if [ "$(ls -A ~/$TRAVIS_BUILD_NUMBER/allure-results/)" ]; then 
	HISTORY_DIR="allure-report/history"
	if [ -d "$HISTORY_DIR" ]; then
		cp -R $HISTORY_DIR ~/$TRAVIS_BUILD_NUMBER/allure-results/history
	fi
	
	# get modified allure version
	scp -r dataclay@mn1.bsc.es:~/testing/allure ~/allure
	
	# generate executor 
	EXECUTOR='{
		"name":"Travis",
	 	"name":"travis",
		"url": "https://travis-ci.com/github/bsc-dom/dataclay-testing",
		"buildOrder":'"$BUILD_NUMBER"', 
		"buildName":"Travis build #'"$BUILD_NUMBER"'",
		"buildUrl": "https://travis-ci.com/github/bsc-dom/dataclay-testing"
		}'
	echo $EXECUTOR > ~/$TRAVIS_BUILD_NUMBER/allure-results/executor.json
	
	
	# remove previous report 
	git rm -rf allure-report/*
	
	# generate report 
	~/allure/bin/allure generate ~/$TRAVIS_BUILD_NUMBER/allure-results -o allure-report --clean
	
	# remove temp files
	rm -rf ~/$TRAVIS_BUILD_NUMBER
	
	# publish 
	sed -i -e "s~base href=\"/\"~base href=\"/allure-report/\"~g" allure-report/index.html
	git add -A
	git commit -m "Updating test report from Travis build $TRAVIS_BUILD_NUMBER"
	git push origin HEAD:master
	
	# remove last test results
	ssh dataclay@mn1.bsc.es "rm -rf testing/results/*"
fi
