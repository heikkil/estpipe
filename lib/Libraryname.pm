#!/usr/bin/env perl

# Libraryname.pm
#
# export two functions:
#
# set_libraryname()
#
# determine the name of the EST library from the fasta headers
# unless it has been set manually
#
# get_libraryname()
#
# return libraryname
#
# Libraryname persistance is file work/libraryname.
#
#

package Libraryname;

use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw(set_libraryname get_libraryname);

our $librarynamefile = 'work/libraryname';
our $fastafile = 'raw/bab.fa';

sub set_libraryname {

    return 0 if -e $librarynamefile;	# do nothing if file exists

    my $libraryname;

    # parse library name from the first fasta header

    open F, $fastafile or die "Can't open [$fastafile]: $!";

    while (<F>) {
	($libraryname) = $_ =~ /\/library_name=([^ ]+)/;
	last;
    }
    close F;

    if ( not $libraryname) {
	print "\n\tCould not read libraryname from $fastafile. Using 'library'\n\n";
	$libraryname = 'library'
    }

    open F, ">", $librarynamefile or die "Can't open [$librarynamefile]: $!";
    print F $libraryname;

}


sub get_libraryname {
    open F, "<", $librarynamefile or die "Can't open [$librarynamefile]: $!";
    my $libraryname;
    while (<F>) {
	$libraryname = $_;
	last;
    }
    chomp($libraryname) if $libraryname;
    return $libraryname;
}


1;
