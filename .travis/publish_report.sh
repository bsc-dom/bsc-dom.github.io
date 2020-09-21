#!/bin/bash
###### SET SSH
bash .travis/set_ssh_mn.sh
bash .travis/set_ssh_report.sh

git remote set-url origin git@github.com:bsc-dom/bsc-dom.github.io.git

# get test results
echo " ** Getting results ** "
mkdir -p ~/$TRAVIS_BUILD_NUMBER/allure-results
mkdir /tmp/allure-results/
scp -r dataclay@mn1.bsc.es:~/testing/results/* /tmp/allure-results/
BUILD_NUMBER=$(ssh dataclay@mn1.bsc.es "cd ~/testing/results/ && ls -td -- * | head -1")
echo " ** Obtained results ** "
ls /tmp/allure-results

# for each copied directory move it to allure-results 
for TESTING_JOB_DIR in /tmp/allure-results/ ; do
	echo "Copying files from $TESTING_JOB_DIR/ to ~/$TRAVIS_BUILD_NUMBER/allure-results/"
    cp -r $TESTING_JOB_DIR/* ~/$TRAVIS_BUILD_NUMBER/allure-results/
done

if [ "$(ls -A ~/$TRAVIS_BUILD_NUMBER/allure-results/)" ]; then 
	echo " ** Getting history ** "
	HISTORY_DIR="allure-report/history"
	if [ -d "$HISTORY_DIR" ]; then
		cp -R $HISTORY_DIR ~/$TRAVIS_BUILD_NUMBER/allure-results/history
	fi
	echo " ** Obtained history ** "
	echo " ** Getting allure ** "
	# get modified allure version
	scp -r dataclay@mn1.bsc.es:~/testing/allure ~/allure
	echo " ** Obtained allure ** "
	echo " ** Creating executor.json ** "
	
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
	echo " ** Created executor.json ** "
	
	# remove previous report 
	echo " ** Removing previous report ** "
	git rm -rf allure-report/*
	echo " ** Removed previous report ** "
	
	# generate report 
	echo " ** Generating report ** "
	~/allure/bin/allure generate ~/$TRAVIS_BUILD_NUMBER/allure-results -o testing-report --clean
	echo " ** Generated report ** "
	
	
	# remove temp files
	rm -rf ~/$TRAVIS_BUILD_NUMBER
	
	# publish 
	echo " ** Publishing ** "
	sed -i -e "s~base href=\"/\"~base href=\"/testing-report/\"~g" testing-report/index.html
	git add -A
	git commit -m "Updating test report from Travis build $TRAVIS_BUILD_NUMBER"
	git push origin HEAD:master
	echo " ** Published ** "
	# remove last test results
	echo " ** Removing results ** "
	ssh dataclay@mn1.bsc.es "rm -rf testing/results/*"
	echo " ** Removed results ** "
fi
