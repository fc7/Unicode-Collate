#
#===============================================================================
#
#         FILE:  UCATest.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  30/04/10 16:51:11
#     REVISION:  ---
#===============================================================================
package UCATest;
no warnings; # turn off warnings about illegal Unicode characters

sub packline {
    my $str = shift;
    $str =~ s/^([A-F0-9 ]+);.+$/$1/;
    my @codepoints = split /\s+/, $str;
    return pack "U*", (map hex $_, @codepoints);
}

sub Unicode::Collate::run_test {
    my $Collator = shift;
    my $fh = shift;
    my $current;
    my $previous;
    my $currentline;
    my $previousline;
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
            Test::More::ok($valid, $test_name);
        }
        $previous = $current;
        $previousline = $currentline;
        $current  = undef;
    }
}

1;
