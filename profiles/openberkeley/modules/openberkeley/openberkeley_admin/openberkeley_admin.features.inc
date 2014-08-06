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
 * Implements hook_views_api().
 */
function openberkeley_admin_views_api($module = NULL, $api = NULL) {
  return array("api" => "3.0");
}

/**
 * Implements hook_views_default_views_alter()
 * - change date format
 * - Add VBO user roles actions, pathauto and panelizer settings
 */
/**/
function openberkeley_admin_views_default_views_alter(&$views) {
  $handler =& $views['control_users']->display['page_1']->handler;
  $handler->default_display->display->display_options['fields']['login']['custom_date_format'] = 'm/d g:ia';
  $handler->default_display->display->display_options['fields']['views_bulk_operations']['vbo_operations']['action::views_bulk_operations_user_roles_action']['selected'] = 1;
  $handler->default_display->display->display_options['fields']['views_bulk_operations']['vbo_operations']['action::panelizer_set_status_action'] = array(
    'selected' => 0,
    'postpone_processing' => 0,
    'skip_confirmation' => 0,
    'override_label' => 0,
    'label' => '',
  );
  $handler->display->display_options['fields']['views_bulk_operations']['vbo_operations']['action::pathauto_user_update_action'] = array(
    'selected' => 0,
    'postpone_processing' => 0,
    'skip_confirmation' => 0,
    'override_label' => 0,
    'label' => '',
  );
}

