# This package was auto-generated by tools/cldr_generate.pl
# included in the forked distribution of the CPAN module 
# Unicode::Collate at http://github.com/fc7/Unicode-Collate
# using the collation data in CLDR version 1.8

package Unicode::Collate::Locale::vi;

our %tailoring = 
    (
      standard => {
                    rules => <<END,
& \x{300} << \x{309} << \x{303} << \x{301} << \x{323} 
& a < \x{103} <<< \x{102} < \xE2 <<< \xC2 
& d < \x{111} <<< \x{110} 
& e < \xEA <<< \xCA 
& o < \xF4 <<< \xD4 < \x{1A1} <<< \x{1A0} 
& u < \x{1B0} <<< \x{1AF} 
END
                    settings => { normalization => "on" },
                  },
      types    => ["standard"],
      version  => 4126,
    );

1;
