<?php
/**
 * @file
 * openberkeley_admin.features.user_permission.inc
 */

/**
 * Implements hook_user_default_permissions().
 */
function openberkeley_admin_user_default_permissions() {
  $permissions = array();

  // Exported permission: 'administer pathauto'.
  $permissions['administer pathauto'] = array(
    'name' => 'administer pathauto',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'pathauto',
  );

  // Exported permission: 'administer total control'.
  $permissions['administer total control'] = array(
    'name' => 'administer total control',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'total_control',
  );

  // Exported permission: 'have total control'.
  $permissions['have total control'] = array(
    'name' => 'have total control',
    'roles' => array(
      'administrator' => 'administrator',
      'builder' => 'builder',
    ),
    'module' => 'total_control',
  );

  // Exported permission: 'notify of path changes'.
  $permissions['notify of path changes'] = array(
    'name' => 'notify of path changes',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'pathauto',
  );

  return $permissions;
}
