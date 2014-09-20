#!/bin/bash
#
# Run this script on a site that's just had it's code switched from -beta4
# to version 0.1 of Open Berkeley.
#

ALIAS=$1
if [ x$ALIAS = x ]; then
  echo "Must pass a drush alias as the first argument, for example: @mytest.dev"
  exit 1
fi

PARAM_TWO=$2

DRUSH=${DRUSH:-drush}
DRUSH_OPTS=${DRUSH_OPTS:---strict=0}

cleanup() {
  # Before proceeding we'll weed out unneeded modules, themes, libraries etc which
  # exist in the site that we are upgrading. This clean up is required if you
  # have used Pantheon Apply Updates to merge in the latest platform code
  SITE_NAME=`echo $ALIAS | cut -d '.' -f2`
  SITE_UUID=`$DRUSH $DRUSH_OPTS psite-uuid $SITE_NAME | cut -d ':' -f 2`

  # change to sftp mode
  $DRUSH $DRUSH_OPTS psite-cmode $SITE_UUID dev sftp
  echo -n "Pausing to permit Pantheon server magic..."
  sleep 20

  # clean up modules, themes, libraries on the site being upgraded
  cat rrmdir.php rrmdir-post.php | $DRUSH $DRUSH_OPTS $ALIAS scr - && (
  echo -n "..."
  sleep 20
  # commit the changes resulting from the delete
  $DRUSH $DRUSH_OPTS psite-commit $SITE_UUID dev --message="Remove profiles/panopoly and clean up modules, themes, libraries in preparation for upgrade." || (
    echo ""
    echo "This server is sadly unmagical.  Try the following:"
    echo "1. Visit the site dashboard."
    echo "2. Ensure the site is in SFTP mode"
    echo "3. Paste these commands one at a time into your terminal:"
    echo "cat rrmdir.php rrmdir-post.php | $DRUSH $DRUSH_OPTS $ALIAS scr -"
    echo "# if that runs with no errors continue"
    echo "$DRUSH $DRUSH_OPTS psite-commit $SITE_UUID dev --message='Remove profiles/panopoly and clean up modules, themes, libraries in preparation for upgrade.'"
    echo "# if that runs with no errors continue"
    echo "$DRUSH $DRUSH_OPTS psite-cmode $SITE_UUID dev git"
    echo "# if you now see that commit in your commit log on the dashboard, continue by re-running this script like this:"
    echo "$0 $1 resume"
    $DRUSH $DRUSH_OPTS psite-dash $SITE_UUID
    exit
  )
)
  sleep 10
  # change to git mode
  $DRUSH $DRUSH_OPTS psite-cmode $SITE_UUID dev git
}

if [[ "$PARAM_TWO" != "resume" ]];then
 if [[ "$PARAM_TWO" != "noaliases" ]];then
  # After some period of time, Pantheon rotates the username/password on the
  # database, so we need to update your Drush aliases. This depends on having
  # installed and authenticated with Terminus:
  #
  #   https://github.com/pantheon-systems/terminus
  #
  echo "Fetching pantheon aliases.  Disable this with $0 $1 noaliases"
  $DRUSH $DRUSH_OPTS pantheon-aliases
  fi
  cleanup
fi

if [[ "$PARAM_TWO" == "noupdate" ]];then
  exit 0;
fi

# New cache tables. There's known issues with clearing caches before a new cache
# table can get created, and we do some magic below to work around them.
NEW_CACHE_TABLES="cache_panels cache_search_api_solr cache_entity_fieldable_panels_pane"

# Pantheon has an 'input screener' on what it allows you to do over SSH, and 
# using 'drush sqlq' runs afoul of it! Here is some hyper-magic to allow us to
# execute SQL on Patheon (and locally).
drush_sqlq() {
  local MYSQL_CONNECT=`$DRUSH $DRUSH_OPTS $ALIAS sql-connect`
  echo "$1" | $MYSQL_CONNECT
}

# Switch profile from 'panopoly' to 'openberkeley'. Unfortunately, drush won't
# be able to bootstrap Drupal ('drush vset' will error out) so we have to set
# this variable directly in the database.
drush_sqlq "UPDATE variable SET value = 's:12:\"openberkeley\";' WHERE name = 'install_profile'"

# In a moment, we're going to call 'drush rr' which will clear all caches at
# the very end. Unfortunately, this will try to clear some new cache tables that
# haven't been created yet.
echo "Creating temp cache tables."
for CACHE_TABLE in $NEW_CACHE_TABLES; do
  drush_sqlq "CREATE TABLE $CACHE_TABLE ( cid VARCHAR(255) NOT NULL PRIMARY KEY, data LONGBLOB, expire INT NOT NULL DEFAULT 0, created INT NOT NULL DEFAULT 0, serialized SMALLINT NOT NULL DEFAULT 0 )"
done


# Clear the code registry and all caches so Drupal can find the new locations
# of all modules.
echo "Running registry rebuild. See /tmp/rr-$ALIAS.out.txt if you want to see the output."
$DRUSH $DRUSH_OPTS $ALIAS rr --fire-bazooka -v &> /tmp/rr-$ALIAS.out.txt

# Drop the new cache tables so they can be created for real in the updates.
echo "Dropping temp cache tables."
for CACHE_TABLE in $NEW_CACHE_TABLES; do
  drush_sqlq "DROP TABLE $CACHE_TABLE"
done

# This is necessary to get the openberkely_update_N() functions to run!
echo "Changing the profile to openberkeley."
drush_sqlq "UPDATE system SET status = 1, schema_version = 0 WHERE name = 'openberkeley'"

# Run the update functions upto $UPDB_LIMIT times
LIMIT=1
UPDB_MSG="Running database updates"
echo "*** $UPDB_MSG ***"
echo "(Ouput might not appear for up to 10 minutes depending on then number of
faq nodes on the site.)"
UPDB_LIMIT=6
UPDB_OUT=`$DRUSH $DRUSH_OPTS $ALIAS updb -y`
echo "$UPDB_OUT"
echo ""
while [[ ! "$UPDB_OUT" =~ "No database updates required" ]] && [[ $LIMIT -lt $UPDB_LIMIT ]]; do
  UPDB_OUT=`$DRUSH $DRUSH_OPTS $ALIAS updb -y`
  echo "*** $UPDB_MSG. Run: $LIMIT. (Max: $UPDB_LIMIT) ***"
  echo "$UPDB_OUT"
  echo ""
  (( LIMIT++ ))
done


# Make sure Features is enabled
echo "Ensuring that features is enabled..."
$DRUSH $DRUSH_OPTS $ALIAS en features -y
$DRUSH $DRUSH_OPTS $ALIAS en features_override -y

# Revert all Features.
$DRUSH $DRUSH_OPTS $ALIAS fra -y

# Now that we've upgraded, we can remove the 'mediafield' module - it was used
# by panopoly_widgets in older versions. We need to run cron a couple times to
# get the field actually purged.
$DRUSH $DRUSH_OPTS $ALIAS cron
$DRUSH $DRUSH_OPTS $ALIAS cron

$DRUSH $DRUSH_OPTS $ALIAS dis -y mediafield || (
  echo
  echo "**"
  echo "** ERROR: We were unable to disable 'mediafield' automatically."
  echo "**"
  echo "** You'll have to wait for cron to run a few times, and then disable"
  echo "** it manually yourself."
  echo "**"
  echo
)

# One final cache clear to hopefully fix the issue where /admin/content
# is giving 'Page not found' and any other cache-y issuse.
$DRUSH $DRUSH_OPTS $ALIAS cc all

# Tell the user what to do next.
echo 
echo "**"
echo "** Enabling panopoly_search via Drush fails because it can't contact the"
echo "** SOLR server (it's on the internal Pantheon network)."
echo "**"
echo "** So, you need to:"
echo "**  (1) Login to the site and enable 'Panopoly Search' via the UI."
echo "**  (2) Clear all caches (can be done via UI or drush)."
echo "**  (3) Index all the content (go to: /admin/config/search/search_api)."
echo "**"
echo

