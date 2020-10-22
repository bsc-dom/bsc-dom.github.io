#!/bin/bash
###### SET SSH
echo " ** Setting ssh configuration ** "
bash .travis/set_ssh_mn.sh
	bash .travis/set_ssh_report.sh
git remote set-url origin git@github.com:bsc-dom/bsc-dom.github.io.git

# get test results
echo " ** Getting results ** "
mkdir -p ~/$TRAVIS_BUILD_NUMBER/allure-results
mkdir -p ~/$TRAVIS_BUILD_NUMBER/pyclay/tmp
mkdir -p ~/$TRAVIS_BUILD_NUMBER/javaclay/tmp

scp -r dataclay@mn1.bsc.es:~/travis/testing-results/pyclay/* ~/$TRAVIS_BUILD_NUMBER/pyclay/tmp
scp -r dataclay@mn1.bsc.es:~/travis/testing-results/javaclay/* ~/$TRAVIS_BUILD_NUMBER/javaclay/tmp

pushd ~/$TRAVIS_BUILD_NUMBER/pyclay/tmp || exit 1
PYCLAY_BUILD_NUMBER=$(ls -td -- * | head -1) 
popd
pushd ~/$TRAVIS_BUILD_NUMBER/javaclay/tmp || exit 1
JAVACLAY_BUILD_NUMBER=$(ls -td -- * | head -1) 
popd

# for each copied directory move it to allure-results 
for TESTING_JOB_DIR in `find  ~/$TRAVIS_BUILD_NUMBER/pyclay/tmp/ -type d` ; do
	echo "Copying files from $TESTING_JOB_DIR/ to ~/$TRAVIS_BUILD_NUMBER/allure-results/"
    cp -r $TESTING_JOB_DIR/* ~/$TRAVIS_BUILD_NUMBER/allure-results/
done
for TESTING_JOB_DIR in `find  ~/$TRAVIS_BUILD_NUMBER/javaclay/tmp/ -type d` ; do
	echo "Copying files from $TESTING_JOB_DIR/ to ~/$TRAVIS_BUILD_NUMBER/allure-results/"
    cp -r $TESTING_JOB_DIR/* ~/$TRAVIS_BUILD_NUMBER/allure-results/
done
ls  ~/$TRAVIS_BUILD_NUMBER/allure-results/
echo " ** Obtained results ** "

if [ "$(ls -A ~/$TRAVIS_BUILD_NUMBER/allure-results/)" ]; then 
	echo " ** Getting history ** "
	HISTORY_DIR="testing-report/history"
	if [ -d "$HISTORY_DIR" ]; then
		cp -R $HISTORY_DIR ~/$TRAVIS_BUILD_NUMBER/allure-results/history
	fi
	echo " ** Obtained history ** "
	echo " ** Getting allure ** "
	# get modified allure version
	scp -r dataclay@mn1.bsc.es:~/travis/allure ~/allure
	echo " ** Obtained allure ** "
	echo " ** Generating executor ** "
	# generate executor 
	EXECUTOR='{
			"name":"Travis",
		 	"type":"travis",
			"url": "https://travis-ci.com/",
			"buildOrder":'"$TRAVIS_JOB_ID"',
			"buildName":"Report build #'"$TRAVIS_JOB_ID"',
			"buildUrl": "https://travis-ci.com"
			}'
	echo "$EXECUTOR" > ~/$TRAVIS_BUILD_NUMBER/allure-results/executor.json
	echo " ** Generated executor ** "
	# remove previous report 
	echo " ** Removing previous report ** "
	git rm -rf testing-report/*
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
	ssh dataclay@mn1.bsc.es "rm -rf travis/testing-results/*"
	echo " ** Removed results ** "
fi
