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

SITE_NAME=`echo $ALIAS | cut -d '.' -f2`
SITE_UUID=`$DRUSH $DRUSH_OPTS psite-uuid $SITE_NAME | cut -d ':' -f 2`

OLD_MODULES="panopoly_demo panopoly_admin panopoly_pages entity_view_mode better_formats conditional_styles views_slideshow_cycle views_slideshow ucb_openberkeley"

for MODULE in $OLD_MODULES; do
  $DRUSH $DRUSH_OPTS $ALIAS dis -y $MODULE
done

for MODULE in $OLD_MODULES; do
  $DRUSH $DRUSH_OPTS $ALIAS pm-uninstall -y $MODULE
done

# change to sftp mode
$DRUSH $DRUSH_OPTS psite-cmode $SITE_UUID dev sftp
echo -n "Pausing to permit Pantheon server magic..."
sleep 10

# Remove profiles/panopoly. You can't do a recursive rm with SFTP, so we use a
# PHP script piped into 'drush php-script' (scr).  Switching to SFTP mode
# sets permissions so we can do the delete.
echo 'function rrmdir($dir) {
   if (is_dir($dir)) {
     $objects = scandir($dir);
     foreach ($objects as $object) {
       if ($object != "." && $object != "..") {
         if (filetype($dir."/".$object) == "dir") rrmdir($dir."/".$object); else unlink($dir."/".$object);
       }
     }
     reset($objects);
     rmdir($dir);
   }
}
rrmdir("profiles/panopoly");' | $DRUSH $DRUSH_OPTS $ALIAS scr -

echo -n "..."
sleep 10
# commit the changes resulting from the delete
$DRUSH $DRUSH_OPTS psite-commit $SITE_UUID dev --message="Remove profiles/panopoly in preparation for upgrade."

echo "..."
sleep 10
# change to git mode
$DRUSH $DRUSH_OPTS psite-cmode $SITE_UUID dev git
