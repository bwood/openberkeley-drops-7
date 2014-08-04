<?php
/**
 * @file
 * openberkeley_admin.features.inc
 */

/**
 * Implements hook_ctools_plugin_api().
 */
function openberkeley_admin_ctools_plugin_api($module = NULL, $api = NULL) {
  if ($module == "page_manager" && $api == "pages_default") {
    return array("version" => "1");
  }
  if ($module == "strongarm" && $api == "strongarm") {
    return array("version" => "1");
  }
}

/**
 * Implements hook_views_default_views_alter()
 */
function openberkeley_admin_views_default_views_alter(&$views) {
  $handler =& $views['control_users']->display['page_1']->handler;
  $handler->default_display->display->display_options['fields']['login']['custom_date_format'] = 'm/d g:ia';
}
