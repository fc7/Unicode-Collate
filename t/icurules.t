
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

use Test;
BEGIN { plan tests => 19 };

use strict;
use warnings;
use utf8;
use Unicode::Collate;
use Data::Dump;

my $c=Unicode::Collate->new(
    table=>"keys.db",
);


ok($c->lt("a", "z"));

my $c2=Unicode::Collate->new(
    table=>"keys.db",
    ICU_rules=>'& z < a <<< A << ä'
);

ok($c2->gt("a", "z"));
ok($c2->gt("ä", "z"));
ok($c2->gt("ä", "A"));

# traditional collation rules for Swedish (ICU syntax)
my $icu_rules_SV = <<END ;
& D << đ <<< Đ << ð <<< Ð 
& th <<< þ
& T <<< Þ / H
& v <<< w             & V <<< W 
& Y << ü <<< Ü << ű <<< Ű 
& [before 1] ʒ < å <<< Å < ä <<< Ä << æ <<< Æ << ę <<< Ę < ö <<< Ö << ø <<< Ø << ő <<< Ő << œ <<< Œ << ô <<< Ô 
END

my $c3 = Unicode::Collate->new(
    table=>"allkeys.db",
    normalization=>"on",
    ICU_rules=>$icu_rules_SV
);

ok($c3->lt("D","đ")); 
ok($c3->lt("th","þ")); 
ok($c3->lt("TH","Þ")); 
ok($c3->gt("å","z")); 
ok($c3->lt("å","ʒ")); 
ok($c3->lt("å","ô")); 
ok($c3->lt("Ô","ʒ")); 
ok($c3->gt("æ","z")); 
ok($c3->gt("ü","Y")); 
ok($c3->gt("ű","Ü")); 
ok($c3->gt("u\x{308}","Y"));
ok($c3->gt("e\x{328}", "æ"));
ok($c3->gt("\x{119}", "æ"));
ok($c3->eq("e\x{328}", "\x{119}"));

$c3->change(level=>2);
# v and w only differ at level 3
ok($c3->eq("wovel", "vowel"));
