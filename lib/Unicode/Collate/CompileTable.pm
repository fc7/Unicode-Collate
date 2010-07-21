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

=encoding utf-8

=head1 NAME

Unicode::Collate::CompileTable - helper module to compile a collation table to a GDBM file

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

    use Unicode::Collate;
    use Unicode::Collate::CompileTable;
    my $col=Unicode::Collate->new( table => '/path/to/allkeys.txt' );
    $col->compile_table( '/path/to/allkeys.db' );

=head1 METHOD

=head2 compile_table

    This adds one method to Unicode::Collate.
    It takes the path of the output file as argument.

=head1 AUTHOR

François Charette, C<< <firmicus@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 François Charette, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

=cut

1;
# vim: set tabstop=4 shiftwidth=4 expandtab:
