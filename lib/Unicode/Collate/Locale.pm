package Unicode::Collate::Locale;
use Carp;
use Unicode::Collate::Locale::Data;

#TODO POD

my %aliases           = %Unicode::Collate::Locale::Data::aliases;
my %aliases_with_type = %Unicode::Collate::Locale::Data::aliases_with_type;
my @available         = @Unicode::Collate::Locale::Data::available_locales;
my %available         = map { $_ => 1 } @available;

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

sub version {
    return shift->{version}
}

sub types {
    return @{shift->{types}}
}

sub id {
    return shift->{id}
}

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

1;
