# This package was auto-generated by tools/cldr_generate.pl
# included in the forked distribution of the CPAN module
# Unicode::Collate at http://github.com/fc7/Unicode-Collate
# using the collation data in CLDR version 1.8

package Unicode::Collate::Locale::ln;

our %tailoring = 
    (
      alphanumeric => {
            rules => <<END,
& E < \x{25B} <<< \x{190} 
& O << \x{254} <<< \x{186} 
END
          },
      default_type => "alphanumeric",
      phonemic => {
            rules => <<END,
& E < \x{25B} <<< \x{190} 
& O << \x{254} <<< \x{186} 
& G < gb <<< gB <<< Gb <<< GB 
& K < kp <<< kP <<< Kp <<< KP 
& M < mb <<< mB <<< Mb <<< MB < mf <<< mF <<< Mf <<< MF < mp <<< mP <<< Mp <<< MP < mv <<< mV <<< Mv <<< MV 
& N < nd <<< nD <<< Nd <<< ND < ng <<< nG <<< Ng <<< NG < ngb <<< ngB <<< nGb <<< nGB <<< Ngb <<< NgB <<< NGB < nk <<< nK <<< Nk <<< NK < ns <<< nS <<< Ns <<< NS < nt <<< nT <<< Nt <<< NT < ny <<< nY <<< Ny <<< NY < nz <<< nZ <<< Nz <<< NZ 
& S < sh <<< sH <<< Sh <<< SH 
& T < ts <<< tS <<< Ts <<< TS 
END
          },
      types => ["phonemic", "alphanumeric"],
      version => 4126,
    );

1;
