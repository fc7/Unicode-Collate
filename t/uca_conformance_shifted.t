#UCA CONFORMANCE TEST
##Testing
#
#The files are designed so each line in the file will order as being greater than or equal to the previous one, when using the UCA and the Default Unicode Collation Element Table. A test program can read in each line, compare it to the last line, and signal an error if order is not correct. The exact comparison that should be used is as follows:
#
#Read the next line.
#Parse each sequence up to the semicolon, and convert it into a Unicode string.
#Compare that string with the string on the previous line, according to the UCA implementation.
#If the last string is less than the current string, continue to the next line (step 1).
#If the last string is greater than the current string, then stop with an error.
#Compare the strings in code point order.
#If the last string is greater than the current string, then stop with an error
#Continue to the next line (step 1).
#If there are any errors, then the UCA implementation is not compliant.

BEGIN {
    unless ("A" eq pack('U', 0x41)) {
        print "1..0 # Unicode::Collate " .
            "cannot stringify a Unicode code point\n";
        exit 0;
    }
    if ($ENV{PERL_CORE}) {
        chdir('t') if -d 't';
        @INC = $^O eq 'MacOS' ? qw(::lib) : qw(../lib);
    }
}

use strict;
use warnings;
use Test::More;
use Unicode::Collate;
use IO::File;
no locale; # so that gt is done by code point order

my $DUCET_VERSION = '5.2.0';

if ($ENV{TEST_UCA_CONFORMANCE}) {
    plan( tests => 152854 ); # = ($no_of_lines - 1) + 1;
}
else {
    plan( skip_all => "official UCA conformance tests (set TEST_UCA_CONFORMANCE=1 to enable)" );
}
#########################

my $Collator = Unicode::Collate->new(); # use defaults

ok($Collator->{versionTable} eq $DUCET_VERSION, "DUCET version");

##############
chdir "data" or croak("Cannot chdir to 'data'");
my $testfile = 'CollationTest_SHIFTED.txt';

sub packline {
    my $str = shift;
    $str =~ s/^([A-F0-9 ]+);.+$/$1/;
    my @codepoints = split /\s+/, $str;
    return pack "U*", (map hex $_, @codepoints);
}

sub run_test {
    my $current;
    my $previous;
    my $currentline;
    my $previousline;
    my $fh = shift;
    while (<$fh>) {
        next if /^#/;
        next if /^\s*$/;
        chomp($currentline = $_);
        $currentline =~ s/;.*$//;
        $current = packline $_;
        unless (not defined $previous) {
            my $test_name = "$currentline > $previousline";
            my $uca_cmp  = $Collator->cmp($current, $previous);
            my $valid;
            if ( $uca_cmp == -1 ) {
                $valid = 0
            }
            elsif ( $uca_cmp == 1 ) {
                $valid = 1
            }
            else { # $uca_cmp == 0, then code point of $current must be > $previous
                $valid = ($current gt $previous);
                $test_name .= " (code point order)"
            }
            ok($valid, $test_name);
        }
        $previous = $current;
        $previousline = $currentline;
        $current  = undef;
    }
}

my $testfh = new IO::File;

$testfh->open("< $testfile") or die "Cannot open $testfile";
print "==================================================\n";
print "Testing UCA conformance with file $testfile ... \n";
print "==================================================\n";
run_test($testfh);
$testfh->close;
print "==================================================\n";
print "Finished \n";
print "==================================================\n\n\n";
#done_testing();
