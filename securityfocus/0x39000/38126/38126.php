<?php
header ('Content-Type: text/html; charset=utf-8');
// Data Includes
include_once "PHPLib/db_mysql.inc";
include_once "Data/dbConnection.class.php";
include_once "Data/dbConfig.class.php";
include_once "Data/dataAdapter.class.php";
include_once "Quicksite/Core/domxml.class.php";


// Quicksite Core Includes
include_once "Quicksite/Core/all.inc.php";

// Configuration
include_once "Quicksite/db.config.php";
include_once "inc/vars.config.php";

// Initialise the Site
$site = new Site($_VARS['site']);
print_r($_SESSION['login']);
// Initialise the Page
$page = new Page($site, $_GET['id'], array_merge($_POST, $_GET));

// Load plugin sources
$page->loadPluginSources();

// Create the Page
$page->createPage();

echo $page->Result;
?>