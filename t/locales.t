use strict;
use warnings;

use Test::More tests => 138;

use Unicode::Collate::Locale;
use Unicode::Collate::Locale::Data;

foreach (@Unicode::Collate::Locale::Data::available_locales) {
     my $loc = Unicode::Collate::Locale->load($_);
     isa_ok($loc, 'Unicode::Collate::Locale');
     can_ok($loc, qw/tailoring rules settings types default_type/);
}
