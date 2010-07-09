package main;
require 5.006001;
use ExtUtils::MakeMaker;
use File::Spec;
use File::Basename;
use File::Copy;
use Unicode::UCD;
use lib 'lib';
use Unicode::Collate;
use Unicode::Collate::CompileTable;

my $UnicodeVersion  = Unicode::UCD::UnicodeVersion();
my $FallbackVersion = '5.0.0';

my $DUCET = File::Spec->catfile('data', 'UCA', $UnicodeVersion, 'allkeys.txt');

if (-f $DUCET ) {
    print "Using DUCET for Unicode version $UnicodeVersion\n";
}
#TODO attempt to fetch it from http://www.unicode.org/Public/UCA/${UnicodeVersion}/allkeys.txt using File::Fetch ??
#elsif ( eval {
#               require File::Fetch;
#               my $ff = File::Fetch->new( uri => "http://www.unicode.org/Public/UCA/${UnicodeVersion}/allkeys.txt" );
#               $ff->fetch( to => File::Spec->catfile('data', 'UCA', $UnicodeVersion) )
#             } ) {
#      printf "Fetched %s for Unicode version %s from %s\n", $ff->file, $UnicodeVersion, $ff->uri;
#}
else {
    warn "I could not find a DUCET file corresponding to the version of Unicode underlying your version of Perl.\nI will use version $FallbackVersion as fallback";
    $DUCET = File::Spec->catfile('data', 'UCA', $FallbackVersion, 'allkeys.txt');
}

copy( $DUCET, File::Spec->catfile( qw(lib Unicode Collate), 'allkeys.txt' ) )
    or die "ERROR: Cannot copy $DUCET to lib/Unicode/Collate/";

my @tables = glob( File::Spec->catfile( qw(lib Unicode Collate), "*.txt" ) );
foreach my $table (@tables) {
    $table  = basename($table);
    my $col = Unicode::Collate->new( table=>$table );
    my $db  = $table;
       $db  =~ s/\.txt$/\.db/;
    my $dbfile = File::Spec->catfile( qw(lib Unicode Collate), $db );
    $col->compile_table($dbfile);
}

WriteMakefile(
    'INSTALLDIRS' => $] >= 5.007002 ? 'perl' : 'site',
    'NAME' => 'Unicode::Collate',
    'VERSION_FROM' => 'lib/Unicode/Collate.pm',    # finds $VERSION
    'PREREQ_PM'    => {
        Carp           => 0,
        'File::Spec'   => 0,
        GDBM_File      => 0,
        Storable       => 0,
        'Unicode::UCD' => 0,
        Test           => 0,
        constant       => 0,
        strict         => 0,
        warnings       => 0,
    },
    clean =>
      { FILES => File::Spec->catfile( qw(lib Unicode Collate), "allkeys.*" ) },
);
