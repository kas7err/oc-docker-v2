<?php
/* Authentication type and info */
$cfg['Servers'][$i]['auth_type'] = 'config';
$cfg['Servers'][$i]['user'] = 'root';
$cfg['Servers'][$i]['password'] = trim(file_get_contents('/run/secrets/db_root_password')); // Use the secret
$cfg['Servers'][$i]['AllowNoPassword'] = true; // Set to true if you are allowing empty root password (not recommended for production)

/* Bind to the MySQL container service */
$cfg['Servers'][$i]['host'] = 'db';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowRoot'] = true;
$cfg['Servers'][$i]['port'] = 3306;
$cfg['Servers'][$i]['ConnectType'] = 'tcp';
$cfg['Servers'][$i]['controluser'] = '';
$cfg['Servers'][$i]['controlpass'] = '';
/* User for advanced features */
$cfg['Servers'][$i]['pmadb'] = 'phpmyadmin';
$cfg['Servers'][$i]['bookmarktable'] = 'pma__bookmarks';
$cfg['Servers'][$i]['relation'] = 'pma__relation';
$cfg['Servers'][$i]['table_info'] = 'pma__table_info';
$cfg['Servers'][$i]['table_coords'] = 'pma__table_coords';
$cfg['Servers'][$i]['pdf_pages'] = 'pma__pdf_pages';
$cfg['Servers'][$i]['column_info'] = 'pma__column_info';
$cfg['Servers'][$i]['history'] = 'pma__history';
$cfg['Servers'][$i]['recent'] = 'pma__recent';
$cfg['Servers'][$i]['favorite'] = 'pma__favorite';
$cfg['Servers'][$i]['table_uiprefs'] = 'pma__table_uiprefs';
$cfg['Servers'][$i]['tracking'] = 'pma__tracking';
$cfg['Servers'][$i]['userconfig'] = 'pma__userconfig';
$cfg['Servers'][$i]['pmadisplaycolumns'] = 'pma__pmadisplaycolumns';
$cfg['Servers'][$i]['primekeys'] = 'pma__primekeys';
$cfg['Servers'][$i]['savedsearches'] = 'pma__savedsearches';
$cfg['Servers'][$i]['central_columns'] = 'pma__central_columns';
$cfg['Servers'][$i]['export_templates'] = 'pma__export_templates';
$cfg['Servers'][$i]['navigationhiding'] = 'pma__navigationhiding';
$cfg['Servers'][$i]['designer_settings'] = 'pma__designer_settings';
$cfg['Servers'][$i]['usergroups'] = 'pma__usergroups';
$cfg['Servers'][$i]['verbose_check'] = true;
$cfg['Servers'][$i]['AllowArbitraryServer'] = true;

// Hide all databases for the root user in the left panel
// $cfg['DefaultTabDatabase'] = 'db_name'; // uncomment and set a default database if you want to land on it
// $cfg['DefaultTabTable'] = 'table_name'; // uncomment and set a default table if you want to land on it
// $cfg['Servers'][$i]['hide_db'] = '^(information_schema|performance_schema|mysql|phpmyadmin)$';

?>
