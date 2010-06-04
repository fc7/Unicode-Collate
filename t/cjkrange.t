
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
BEGIN { plan tests => 61 };

use strict;
use warnings;
use Unicode::Collate;
use Cwd;
my $dir     = getcwd();
my $KeysTxt = File::Spec->catfile($dir, 't', 'data', 'keys.txt');

ok(1);

my $Collator = Unicode::Collate->new(
  table => $KeysTxt,
  normalization => undef,
);

# U+9FBC..U+9FC3 are CJK UI since Unicode 5.1.0.
# U+9FA6..U+9FBB are CJK UI since Unicode 4.1.0.
# U+3400 is CJK UI ExtA, then greater than any CJK UI.

##### 2..13
ok($Collator->lt("\x{9FA5}", "\x{3400}")); # UI < ExtA
ok($Collator->lt("\x{9FA6}", "\x{3400}")); # new UI < ExtA
ok($Collator->lt("\x{9FBB}", "\x{3400}")); # new UI < ExtA
ok($Collator->lt("\x{9FBC}", "\x{3400}")); # new UI < ExtA
ok($Collator->lt("\x{9FC3}", "\x{3400}")); # new UI < ExtA
ok($Collator->gt("\x{9FC4}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FFF}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->lt("\x{9FA6}", "\x{9FBB}")); # new UI > new UI
ok($Collator->lt("\x{3400}","\x{20000}")); # ExtA < ExtB
ok($Collator->lt("\x{3400}","\x{2A6D6}")); # ExtA < ExtB
ok($Collator->gt("\x{9FFF}","\x{20000}")); # Unassigned > ExtB
ok($Collator->gt("\x{9FFF}","\x{2A6D6}")); # Unassigned > ExtB

##### 14..25
$Collator->change(UCA_Version => 11);
ok($Collator->lt("\x{9FA5}", "\x{3400}")); # UI < ExtA
ok($Collator->gt("\x{9FA6}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FBB}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FBC}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FC3}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FC4}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FFF}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->lt("\x{9FA6}", "\x{9FBB}")); # Unassigned > Unassigned
ok($Collator->lt("\x{3400}","\x{20000}")); # ExtA < ExtB
ok($Collator->lt("\x{3400}","\x{2A6D6}")); # ExtA < ExtB
ok($Collator->gt("\x{9FFF}","\x{20000}")); # Unassigned > ExtB
ok($Collator->gt("\x{9FFF}","\x{2A6D6}")); # Unassigned > ExtB

##### 26..37
$Collator->change(UCA_Version => 9);
ok($Collator->lt("\x{9FA5}", "\x{3400}")); # UI < ExtA
ok($Collator->gt("\x{9FA6}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FBB}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FBC}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FC3}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FC4}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FFF}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->lt("\x{9FA6}", "\x{9FBB}")); # Unassigned > Unassigned
ok($Collator->lt("\x{3400}","\x{20000}")); # ExtA < ExtB
ok($Collator->lt("\x{3400}","\x{2A6D6}")); # ExtA < ExtB
ok($Collator->gt("\x{9FFF}","\x{20000}")); # Unassigned > ExtB
ok($Collator->gt("\x{9FFF}","\x{2A6D6}")); # Unassigned > ExtB

##### 38..49
$Collator->change(UCA_Version => 8);
ok($Collator->gt("\x{9FA5}", "\x{3400}")); # UI > ExtA
ok($Collator->gt("\x{9FA6}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FBB}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FBC}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FC3}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FC4}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FFF}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->lt("\x{9FA6}", "\x{9FBB}")); # new UI > new UI
ok($Collator->lt("\x{3400}","\x{20000}")); # ExtA < Unassigned(ExtB)
ok($Collator->lt("\x{3400}","\x{2A6D6}")); # ExtA < Unassigned(ExtB)
ok($Collator->lt("\x{9FFF}","\x{20000}")); # Unassigned < Unassigned(ExtB)
ok($Collator->lt("\x{9FFF}","\x{2A6D6}")); # Unassigned < Unassigned(ExtB)

##### 50..61
$Collator->change(UCA_Version => 14);
ok($Collator->lt("\x{9FA5}", "\x{3400}")); # UI < ExtA
ok($Collator->lt("\x{9FA6}", "\x{3400}")); # new UI < ExtA
ok($Collator->lt("\x{9FBB}", "\x{3400}")); # new UI < ExtA
ok($Collator->gt("\x{9FBC}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FC3}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FC4}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->gt("\x{9FFF}", "\x{3400}")); # Unassigned > ExtA
ok($Collator->lt("\x{9FA6}", "\x{9FBB}")); # new UI > new UI
ok($Collator->lt("\x{3400}","\x{20000}")); # ExtA < ExtB
ok($Collator->lt("\x{3400}","\x{2A6D6}")); # ExtA < ExtB
ok($Collator->gt("\x{9FFF}","\x{20000}")); # Unassigned > ExtB
ok($Collator->gt("\x{9FFF}","\x{2A6D6}")); # Unassigned > ExtB

