#!/bin/bash
# get test results
echo " ** Getting results ** "
mkdir -p $HOME/all-allure-results

for APPVEYOR_JOB_RESULTS in $HOME/allure-results/* ; do
    cp -r $APPVEYOR_JOB_RESULTS/* $HOME/all-allure-results/
done
echo " ** Obtained results ** "


echo " ** Getting history ** "
HISTORY_DIR="testing-report/history"
if [ -d "$HISTORY_DIR" ]; then
	cp -R $HISTORY_DIR $HOME/all-allure-results/history
fi
echo " ** Obtained history ** "


echo " ** Generating executor ** "
# generate executor
EXECUTOR='{
			"name":"Appveyor",
		 	"type":"appveyor",
			"url": "https://ci.appveyor.com/",
			"buildUrl": "https://ci.appveyor.com/"
}'
echo "$EXECUTOR" > $HOME/all-allure-results/executor.json
echo " ** Generated executor ** "

# remove previous report
echo " ** Removing previous report ** "
git rm -rf testing-report/*
echo " ** Removed previous report ** "
	
# generate report
echo " ** Generating report ** "
$HOME/allure/bin/allure generate $HOME/all-allure-results/ -o testing-report --clean
echo " ** Generated report ** "

# publish
echo " ** Publishing ** "
sed -i -e "s~base href=\"/\"~base href=\"/testing-report/\"~g" testing-report/index.html
git remote set-url origin git@github.com:bsc-dom/bsc-dom.github.io.git
git add -A
git commit -m "Updating test report from Appveyor"
git push origin HEAD:master
echo " ** Published ** "

# remove last test results
echo " ** Removing results ** "
rm -rf $HOME/all-allure-results
rm -rf $HOME/allure-results/*
echo " ** Removed results ** "