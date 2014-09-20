// <?php // This comment is needed since post-update.sh cats this into STDIN of a drush command. Uncomment to run this directly.
// include("rrmdir.php");

// Zen can cause a error on bootstrap in post-install.sh
if (is_dir("sites/all/themes/zen")) {
  rrmdir("sites/all/themes/zen");
}
else {
  print "\n==> No offending files found. There will be nothing to commit.  This is okay. <==\n";
  // exit(0) doesn't prevent the drush error. Could implement hook_drush_exit(), maybe...
  exit("*** Intentionally aborting drush.*** Disregard this next drush error:");
}
