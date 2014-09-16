#!/bin/bash

COMMAND=$1
BUILD_TOP=`dirname $TRAVIS_BUILD_DIR`
DIFFS=0
EXIT_VALUE=0

export PATH="$HOME/.composer/vendor/bin:$PATH"
export DISPLAY=:99.0
export CHROME_SANDBOX=/opt/google/chrome/chrome-sandbox

##
# SCRIPT COMMANDS
##

# system-install
#
# This is meant to setup the server on Travis-CI so that it can run the tests.
#
system_install() {
  # Add the Google Chrome packages.
  header Setting up APT
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
  sudo apt-get update > /dev/null

  # Create a database for our Drupal site.
  mysql -e 'create database openberkeley;'

  # Install the latest Drush 6.
  header Installing Drush
  composer global require --prefer-source --no-interaction drush/drush:6.*
  drush dl -y drupalorg_drush-7.x-1.x-dev --destination=$HOME/.drush
  drush cc drush

  # Run the build script and makefile, if needed.
  if [[ "$MAKEFILE" != false ]]; then
    header Running build script
    cd $BUILD_TOP/openberkeley-drops-7/profiles/openberkeley
    echo "3" | bash ./rebuild.sh

    header Verifying results of makefile
    cd $BUILD_TOP/openberkeley-drops-7
    DIFFS=`git status | grep -e 'modified' -e 'Untracked' | grep -vc -e 'info'`
    if [[ "$DIFFS" != 0 ]]; then
      echo "Files (other than info files) differ"
      echo "from source after running makefile:"
      git status | grep -v -e 'info' -e 'branch' -e '(use' -e 'Changes not staged'
      set_error
    fi
  fi


  # Set up file directories.
  header Setting up file directories
  cd $BUILD_TOP/openberkeley-drops-7
  mkdir sites/default/files
  mkdir sites/default/files/private
  mkdir sites/default/files/temp

  # Build Behat dependencies
  header Installing Behat
  cd profiles/openberkeley/openberkeley_tests/behat
  composer install --prefer-source --no-interaction
  cd ../../../../../

  # Setup files
  sudo chmod -R 777 openberkeley-drops-7/sites/all

  # Setup display for Selenium
  header Starting X
  sh -e /etc/init.d/xvfb start
  sleep 5

  # Get Chrome and ChromeDriver
  header Installing Google Chrome
  sudo apt-get install google-chrome-stable
  wget http://chromedriver.storage.googleapis.com/2.9/chromedriver_linux64.zip
  unzip -a chromedriver_linux64.zip

  # Insane hack from jsdevel:
  #   https://github.com/jsdevel/travis-debugging/blob/master/shim.bash
  # This allows chrome-sandbox to work in side of OpenVZ, because I can't
  # figure out how to start chrome with --no-sandbox.
  sudo rm -f $CHROME_SANDBOX
  sudo wget https://googledrive.com/host/0B5VlNZ_Rvdw6NTJoZDBSVy1ZdkE -O $CHROME_SANDBOX
  sudo chown root:root $CHROME_SANDBOX
  sudo chmod 4755 $CHROME_SANDBOX
  sudo md5sum $CHROME_SANDBOX

  # Get Selenium  - updated for changes to Firefox
  header Downloading Selenium
  wget http://selenium-release.storage.googleapis.com/2.43/selenium-server-standalone-2.43.1.jar
 
  # Disable sendmail
  echo sendmail_path=`which true` >> ~/.phpenv/versions/$(phpenv version-name)/etc/php.ini
}

# before_tests
#
# Setup Drupal to run the tests.
#
before_tests() {

  # Do the site install (either the current revision or old for the upgrade).
  header Installing Drupal
  cd openberkeley-drops-7

  drush si openberkeley --db-url=mysql://root:@127.0.0.1/openberkeley --account-name=ucbadmin --site-mail=admin@example.edu --site-name="Open Berkeley Travis" --yes
  drush dis -y dblog
  drush vset -y file_private_path "sites/default/files/private"
  drush vset -y file_temporary_path "sites/default/files/temp"

  # Our tests depend on panopoly_test.
  drush en -y panopoly_test

  # Run the webserver
  header Starting webserver
  drush runserver --server=builtin 8888 > /dev/null 2>&1 &
  echo $! > /tmp/web-server-pid
  sleep 3

  cd ..

  # Run the selenium server
  header Starting selenium
  java -jar selenium-server-standalone-2.43.1.jar -Dwebdriver.chrome.driver=`pwd`/chromedriver > /dev/null 2>&1 &
  echo $! > /tmp/selenium-server-pid
  sleep 5
}

# before_tests
#
# Run the tests.
#
run_tests() {
  header Running tests

  # Make the Travis tests repos agnostic by injecting drupal_root with BEHAT_PARAMS
  export BEHAT_PARAMS="extensions[Drupal\\DrupalExtension\\Extension][drupal][drupal_root]=$BUILD_TOP/openberkeley-drops-7"

  cd openberkeley-drops-7/profiles/openberkeley/openberkeley_tests/behat

  # First, run all the tests in Firefox.
  run_test ./bin/behat --config behat.travis.yml

  # Then run some Chrome-only tests.
  run_test ./bin/behat --config behat.travis.yml -p chrome
}

# after_tests
#
# Clean up after the tests.
#
after_tests() {
  header Cleaning up after tests

  WEB_SERVER_PID=`cat /tmp/webserver-server-pid`
  SELENIUM_SERVER_PID=`cat /tmp/selenium-server-pid`

  # Stop the servers we started
  kill $WEB_SERVER_PID
  kill $SELENIUM_SERVER_PID
}

##
# UTILITY FUNCTIONS:
##

# Prints a message about the section of the script.
header() {
  set +xv
  echo
  echo "** $@"
  echo
  set -xv
}

# Sets the exit level to error.
set_error() {
  EXIT_VALUE=1
}

# Runs a command and sets an error if it fails.
run_test() {
  if ! $@; then
    set_error
  fi
}

# Runs a command showing all the lines executed
run_command() {
  set -xv
  $@
  set +xv
}

##
# SCRIPT MAIN:
##

# Capture all errors and set our overall exit value.
trap 'set_error' ERR

# We want to always start from the same directory:
cd $BUILD_TOP

case $COMMAND in
  system-install)
    run_command system_install
    ;;

  drupal-install)
    run_command drupal_install
    ;;

  before-tests)
    run_command before_tests
    ;;

  run-tests)
    run_command run_tests
    ;;

  after-tests)
    run_command after_tests
    ;;
esac
##
exit $EXIT_VALUE
