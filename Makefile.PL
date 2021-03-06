package main;
require 5.006001;
use ExtUtils::MakeMaker;
use File::Spec;
use File::Basename;
use lib 'lib';
use Unicode::Collate;
use Unicode::Collate::CompileTable;

my @tables = glob(File::Spec->catfile( qw(lib Unicode Collate), "*.txt" ));
foreach my $table (@tables) {
    $table  = basename($table);
    my $col = Unicode::Collate->new( table=>$table );
    my $db  = $table;
       $db  =~ s/\.txt$/\.db/;
    my $dbfile = File::Spec->catfile( qw(lib Unicode Collate), $db );
    $col->compile_table($dbfile);
}

WriteMakefile(
    'INSTALLDIRS'	=> $] >= 5.007002 ? 'perl' : 'site',
    'NAME'		    => 'Unicode::Collate',
    'VERSION_FROM'	=> 'lib/Unicode/Collate.pm', # finds $VERSION
    'PREREQ_PM'	  	=> {
        Carp         => 0,
        File::Spec   => 0,
        GDBM_File    => 0,
        Storable     => 0,
        Unicode::UCD => 0,
        Test         => 0,
        constant     => 0,
        strict       => 0,
        warnings     => 0,
    },
    clean            => { FILES => File::Spec->catfile( qw(lib Unicode Collate), "*.db") },
);
