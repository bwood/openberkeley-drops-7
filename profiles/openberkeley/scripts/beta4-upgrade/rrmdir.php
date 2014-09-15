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
