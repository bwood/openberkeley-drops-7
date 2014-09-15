// <?php // This comment is needed since post-update.sh cats this into STDIN of a drush command. Uncomment to run this directly.
// include("rrmdir.php");

// Zen can cause a error on bootstrap in post-install.sh
if (is_dir("sites/all/themes/zen")) {
  rrmdir("sites/all/themes/zen");
}
