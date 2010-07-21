package Unicode::Collate::Locale;
use Carp;
use Unicode::Collate::Locale::Data;

=encoding utf-8

=head1 NAME

Unicode::Collate::Locale - interface to CLDR collation tailorings

(CLDR stands for Unicode's "Common Locale Data Repository")

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

=head SYNOPSIS

    use Unicode::Collate::Locale;
    my $loc       = Unicode::Collate::Locale->load($id);
    my @types     = $loc->types;
    my $rules     = $loc->rules($type);
    my %settings  = $loc->settings($type);
    my %tailoring = $loc->tailoring($type);

=cut

my %aliases           = %Unicode::Collate::Locale::Data::aliases;
my %aliases_with_type = %Unicode::Collate::Locale::Data::aliases_with_type;
my @available         = @Unicode::Collate::Locale::Data::available_locales;
my %available         = map { $_ => 1 } @available;

=head1 METHODS

=head2 load

    my $loc = Unicode::Collate::Locale->load($locale_id);

    Initializes a Unicode::Collate::Locale object

=cut

sub load {
    my $class  = shift;
    my $locale = shift;
    my $type;

    my $id     = $locale;
    my %seen   = ( $id => 1 );
    while (exists $aliases{$id}) {
        $id = $aliases{$id};
        croak "Oops! Locale $id was already seen. Exiting from infinite loop!"
            if $seen{$id};
        $seen{$id}++;
    }
    if ($aliases_with_type{$id}) {
        ($id, $type) = @{ $aliases_with_type{$id} }
    }

    # if id is unavaible, try the root id:
    unless ($available{$id}) {
        $id =~ s/^([a-z]+)_.+$/$1/;
    }

    if ($id eq 'default') {
        return bless { id => 'default' }, $class
    }

    my $localeclass = __PACKAGE__ . "::" . $id;
    eval "require $localeclass";
    if ($@) {
        $available{$id}
            ? carp "Cannot load class $localeclass"
            : carp "$localeclass is not available"
    }
    else {
        my %tlr = %{"${localeclass}::tailoring"};
        if ($type) {
            $tlr{default_type} = $type;
            foreach my $y (@{$tlr{types}}) {
                delete $tlr{$y} unless $y eq $type
            }
            $tlr{types} = [$type]
        }
        carp "Empty tailoring in $localeclass" unless scalar keys %tlr;
        return bless { id => $id, locale => $locale, %tlr }, $class
    }
    return
}

=head2 tailoring

    $loc->tailoring($collation_type);

    Returns a hash which can be used as a tailoring for initializing a
    Unicode::Collate object. If no collation type is passed as argument,
    the default type is used.

=cut

sub tailoring {
    my ($self, $type) = @_;

    return if $self->{id} eq 'default';

    unless ($type) {
        $type = $self->default_type
    }

    if ($self->{$type}) {
        if ($self->rules($type)) {
            return
                (
                    %{$self->{$type}{settings}},
                    ICU_rules => $self->{$type}{rules},
                )
        }
        else {
            return
                (
                    %{$self->{$type}{settings}},
                )
        }
    } else {
        carp "Collation type '$type' is not available for locale '" . $self->{id} . "'"
    }

    return
}

=head2 rules

    $loc->rules($collation_type);

    Returns a string with the collation rules in ICU syntax for a particular
    collation type. If no argument is passed, the rules for the default type
    are returned. These rules can be passed to the 'ICU_rules' parameter of
    Unicode::Collate.

=cut

sub rules {
    my ($self, $type) = @_;

    return if $self->{id} eq 'default';

    unless ($type) {
        $type = $self->default_type
    }

    if ($self->{$type}) {
        return $self->{$type}{rules} if exists $self->{$type}{rules}
    } else {
        carp "Collation type '$type' is not available for locale '" . $self->{id} . "'";
    }

    return
}

=head2 settings

    $loc->settings($collation_type);

    Return a hash with the collation settings corresponding to a particular
    collation type. If no argument is passed, the settings for the default type
    are returned. These settings are parameters which can be passed to a
    Unicode::Collate object.

=cut

sub settings {
    my ($self, $type) = @_;

    return if $self->{id} eq 'default';

    unless ($type) {
        $type = $self->default_type
    }

    if ($self->{$type}) {
        return %{$self->{$type}{settings}}
    } else {
        carp sprintf "Collation type '%s' is not available for locale '%s'", $type, $self->{id}
    }

    return

}

=head2 version

    Returns the version (actually a SVN revision number) of the collation data
    in the LDML file of the CLDR release underlying the
    Unicode::Collate::Locale::* modules.

=cut

sub version {
    return shift->{version}
}

=head2 CLDR_Version

    Returns the CLDR release number underlying the collation data in the
    Unicode::Collate::Locale::* modules.

=cut

sub CLDR_Version {
    return $Unicode::Collate::Locale::Data::CLDR_Version
}

=head2 types

    Returns an array with the different collation types available for a
    particular locale.

=cut

sub types {
    return @{shift->{types}}
}

=head2 id

    Returns the id string identifying a locale.

=cut

sub id {
    return shift->{id}
}

=head2 default_type

    Returns the default collation type for a given locale.

=cut

sub default_type {
    my $self = shift;
    if ($self->{default_type}) {
        return $self->{default_type}
    }
    elsif (scalar $self->types == 1) {
        my @t = $self->types;
        return $t[0] if defined $t[0]
    }
    else {
        return 'standard'
    }
}

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
