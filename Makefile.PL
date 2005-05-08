require 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    'INSTALLDIRS'	=> $] >= 5.007002 ? 'perl' : 'site',
    'NAME'		=> 'Unicode::Collate',
    'VERSION_FROM'	=> 'Collate.pm', # finds $VERSION
    'PREREQ_PM'	  	=> {
	Carp		=> 0,
	File::Spec	=> 0,
	Test		=> 0,
	constant	=> 0,
	strict		=> 0,
	warnings	=> 0,
    },
);
