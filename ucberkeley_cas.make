api = 2
core = 7.x

; phpCAS library
libraries[phpcas][download][type] = "get"
libraries[phpcas][download][url] = "http://downloads.jasig.org/cas-clients/php/current/CAS-1.3.2.tgz"

; CAS
projects[cas][type] = module
projects[cas][version] = 1.3
projects[cas][patch][1394666-cas_library_path-15.patch] = "https://drupal.org/files/cas-library-detection-1394666-15.patch"

; CAS Attributes
projects[cas_attributes][type] = module
projects[cas_attributes][version] = 1.0-beta2

; LDAP
projects[ldap][type] = module
projects[ldap][version] = 1.0-beta12

