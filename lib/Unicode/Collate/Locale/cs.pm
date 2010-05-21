# This package was auto-generated by tools/cldr_generate.pl
# included in the forked distribution of the CPAN module 
# Unicode::Collate at http://github.com/fc7/Unicode-Collate
# using the collation data in CLDR version 1.8

package Unicode::Collate::Locale::cs;

our %tailoring = 
    (
      "digits-after" => {
            rules => <<END,
& C < c\x{30C} <<< C\x{30C} 
& H < ch <<< cH <<< Ch <<< CH 
& R < r\x{30C} <<< R\x{30C} 
& S < s\x{30C} <<< S\x{30C} 
& Z < z\x{30C} <<< Z\x{30C} 
& [last_non_ignorable] < 0 < 1 < 2 < 3 < 4 < 5 < 6 < 7 < 8 < 9 
END
          },
      standard => {
            rules => <<END,
& C < c\x{30C} <<< C\x{30C} 
& H < ch <<< cH <<< Ch <<< CH 
& R < r\x{30C} <<< R\x{30C} 
& S < s\x{30C} <<< S\x{30C} 
& Z < z\x{30C} <<< Z\x{30C} 
END
          },
      types => ["standard", "digits-after"],
      version => 4126,
    );

1;
