use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Unicode::Collate',
    'VERSION_FROM'	=> 'Collate.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Collate.pm', # retrieve abstract from module
       AUTHOR     => 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>') : ()),
    'PM' => {
	'Makefile.PL' => 'Makefile',
	'Collate.pm' => 'blib/lib/Unicode/Collate.pm',
	'keys.txt' => 'blib/lib/Unicode/Collate/keys.txt',
	},
);
