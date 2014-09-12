// <?php // This comment is needed since post-update.sh cats this into STDIN of a drush command. Uncomment to run this directly.

/**
 * Recursively remove a directory
 * If a comparision directory is provided, only remove the directories that are
 * common to both $dir and $dir_compare. If we encounter a dir in $blacklist,
 * always delete it.
 *
 * @param $dir
 * @param array $dir_compare
 * @param array $blacklist
 */
function rrmdir($dir, $dir_compare = array(), $blacklist = array()) {
  $unique_dirs = FALSE;
  $objects = array();
  $objects_compare = array();

  if (is_dir($dir)) {
    $objects = scandir($dir);
  }
  else {
    return;
  }

  if (count($dir_compare) > 0) {
    foreach ($dir_compare as $dc) {
      if (is_dir($dc)) {
        $objects_compare = array_merge($objects_compare, scandir($dc));
      }
    }
    $common = array_intersect($objects, $objects_compare);
  }
  else {
    $common = $objects;
  }

  foreach ($objects as $object) {
    if ($object != "." && $object != "..") {
      if (filetype($dir . "/" . $object) == "dir") {
        if ((in_array($object, $common)) || (in_array($object, $blacklist))) {
          rrmdir($dir . "/" . $object);
        }
        else {
          $unique_dirs = TRUE;
          continue;
        }
      }
      else {
        unlink($dir . "/" . $object);
      }
    }
  }
  reset($objects);
  if (!$unique_dirs) {
    rmdir($dir);
  }
}

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


rrmdir("sites/all/themes", array("profiles/openberkeley/themes"));
if (!is_dir("sites/all/themes")) {
  mkdir("sites/all/themes", 0755);
}

rrmdir("sites/all/libraries", array("profiles/openberkeley/libraries"));
// Okay if there is no sites/all/libraries

rrmdir("profiles/panopoly");
