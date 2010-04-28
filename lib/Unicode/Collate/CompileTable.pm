package Unicode::Collate::CompileTable;
use strict;
use warnings;
use GDBM_File;
use Storable qw(freeze); 

# generate pre-compiled tables
sub Unicode::Collate::compile_table {
    my($self,$dbfile) = @_;
    tie my %MAPPING, 'GDBM_File', $dbfile, &GDBM_WRCREAT, 0644 || die "Cannot tie: $!";
    print "Compiling collation table " . $self->{table} . " ... \n";
    foreach my $key ( keys %{$self->{mapping}} ) {
        my $value = $self->{mapping}{$key};
        $MAPPING{$key} = freeze $value 
    }

    untie %MAPPING; 
}

1;
