#!/bin/bash
#
# Run this script on a site that's going to be upgraded from -beta4 to
# Open Berkeley 0.1, but run it BEFORE actually updating the code.
#

ALIAS=$1
if [ x$ALIAS = x ]; then
  echo "Must pass a drush alias as the first argument, for example: @mytest.dev"
  exit 1
fi

DRUSH=${DRUSH:-drush}
DRUSH_OPTS=${DRUSH_OPTS:---strict=0}

# Custom modules to disable.  Don't uninstall so we don't loose config.
DIS_MODULES="quicktabs apachesolr"
for MODULE in $DIS_MODULES; do
  $DRUSH $DRUSH_OPTS $ALIAS dis -y $MODULE
done

# Modules to disable and uninstall.
OLD_MODULES="panopoly_demo panopoly_admin panopoly_pages entity_view_mode better_formats conditional_styles views_slideshow_cycle views_slideshow ucb_openberkeley"

for MODULE in $OLD_MODULES; do
  $DRUSH $DRUSH_OPTS $ALIAS dis -y $MODULE
done

for MODULE in $OLD_MODULES; do
  $DRUSH $DRUSH_OPTS $ALIAS pm-uninstall -y $MODULE
done

SITE_NAME=`echo $ALIAS | cut -d '.' -f2`
SITE_UUID=`$DRUSH $DRUSH_OPTS psite-uuid $SITE_NAME | cut -d ':' -f 2`

# change to sftp mode
$DRUSH $DRUSH_OPTS psite-cmode $SITE_UUID dev sftp
echo -n "Pausing to permit Pantheon server magic..."
sleep 30

# clean up modules, themes, libraries on the site being upgraded
cat rrmdir.php rrmdir-pre.php | $DRUSH $DRUSH_OPTS $ALIAS scr - && (
  echo -n "..."
  sleep 20
  # commit the changes resulting from the delete
  $DRUSH $DRUSH_OPTS psite-commit $SITE_UUID dev --message="Remove sites/all/themes/zen preparation for upgrade." || (
    echo ""
    echo "This server is sadly unmagical.  Try the following:"
    echo "1. Visit the site dashboard."
    echo "2. Ensure the site is in SFTP mode"
    echo "3. Paste these commands one at a time into your terminal:"
    echo "cat rrmdir.php rrmdir-pre.php | $DRUSH $DRUSH_OPTS $ALIAS scr -"
    echo "# if that runs with no errors continue"
    echo "$DRUSH $DRUSH_OPTS psite-commit $SITE_UUID dev --message='Remove sites/all/themes/zen preparation for upgrade.'"
    echo "# if that runs with no errors continue"
    echo "$DRUSH $DRUSH_OPTS psite-cmode $SITE_UUID dev git"
    echo "# if you now see that commit in your commit log on the dashboard, continue with the Apply Updates step."
    $DRUSH $DRUSH_OPTS psite-dash $SITE_UUID
    exit
  )
)

echo "..."
sleep 10
# change to git mode
$DRUSH $DRUSH_OPTS psite-cmode $SITE_UUID dev git
