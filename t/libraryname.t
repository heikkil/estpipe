use strict;
use Test;

BEGIN { plan tests => 2 }
use lib 'lib'; 
use Libraryname;

unlink '../work/libraryname' if -e '../work/libraryname';
ok set_libraryname;
ok get_libraryname, 'BABEVCEREB-C-01-1-7KB';
