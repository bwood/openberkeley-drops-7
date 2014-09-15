// <?php // This comment is needed since post-update.sh cats this into STDIN of a drush command. Uncomment to run this directly.
// include("rrmdir.php");

/*
* Clean up modules
*/
// Remove these if found regardless
$blacklist_dirs = array(
  'better_formats',
  'entity_view_mode',
  'openberkeley_update-master',
  'panopoly_demo',
  'PATCHES',
  'ucb_cas',
  'ucb_envconf',
  'ucb_openberkeley',
  'ucb_smtp',
);

$compare_module_dirs = array(
  'profiles/openberkeley/modules/contrib',
  'profiles/openberkeley/modules/openberkeley',
  'profiles/openberkeley/modules/panopoly',
  'profiles/openberkeley/modules/ucb',
);

rrmdir("sites/all/modules", $compare_module_dirs, $blacklist_dirs);
if (!is_dir("sites/all/modules")) {
  mkdir("sites/all/modules", 0755);
}


/*
* Clean up themes
*/
rrmdir("sites/all/themes", array("profiles/openberkeley/themes"));
if (!is_dir("sites/all/themes")) {
  mkdir("sites/all/themes", 0755);
}

/*
* Clean up Libraries
*/
rrmdir("sites/all/libraries", array("profiles/openberkeley/libraries"));
// Okay if there is no sites/all/libraries

rrmdir("profiles/panopoly");
