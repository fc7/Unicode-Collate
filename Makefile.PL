use ExtUtils::MakeMaker;

WriteMakefile(
    'INSTALLDIRS'	=> $] > 5.007 ? 'perl' : 'site',
    'NAME'		=> 'Unicode::Collate',
    'VERSION_FROM'	=> 'Collate.pm', # finds $VERSION
);
