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

    if (exists $self->{versionTable}) {
        $MAPPING{_versionTable} = $self->{versionTable}
    }

    #as well as all "logical positions"
    $MAPPING{_first_variable} = $self->{first_variable};
    $MAPPING{_last_variable} = $self->{last_variable};
    $MAPPING{_first_primary_ignorable} = $self->{first_primary_ignorable};
    $MAPPING{_last_primary_ignorable} = $self->{last_primary_ignorable};
    $MAPPING{_first_secondary_ignorable} = $self->{first_secondary_ignorable};
    $MAPPING{_last_secondary_ignorable} = $self->{last_secondary_ignorable};
    $MAPPING{_first_tertiary_ignorable} = $self->{first_tertiary_ignorable};
    $MAPPING{_last_tertiary_ignorable} = $self->{last_tertiary_ignorable};
    $MAPPING{_first_non_ignorable} = $self->{first_non_ignorable};
    $MAPPING{_last_non_ignorable} = $self->{last_non_ignorable};
    #$MAPPING{_first_trailing} = $self->{first_trailing};
    #$MAPPING{_last_trailing} = $self->{last_trailing};

    foreach my $key ( keys %{$self->{maxlength}} ) {
        my $k = Unicode::Collate::CODE_SEP . $key;
        my $value = $self->{maxlength}{$key};
        $MAPPING{$k} = $value;
	}

    untie %MAPPING;
}

1;
