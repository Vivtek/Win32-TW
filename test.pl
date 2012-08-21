use lib "./lib";

use Win32::TW;

$tw = Win32::TW->open('c:\translation\dcc\simatic.tmw');

$tw->export('c:\translation\_tmx\test.tmx');

#$tw->close();