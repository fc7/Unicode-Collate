#!/usr/bin/perl
use strict;
use warnings;
use XML::LibXML;
#use XML::LibXML::Simple; #do without?
use Data::Dump; # temporary
use Carp;
use FindBin qw($Bin);
use File::Spec;
binmode(STDOUT, ':utf8');


#TODO
#my @ldml_files = glob(Find::Spec->catfile($Bin, qw(.. data CLDR collation), "*.xml"));
# croak if ldml files not found
#
my $locale = $ARGV[0] || "sv";
my $infile = File::Spec->catfile($Bin, qw(.. data CLDR collation), "$locale.xml");
my $parser = XML::LibXML->new();
my $ldml = $parser->parse_file($infile);

#my $ldml = XML::LibXML::Simple::XMLin($infile, 'ForceArray' => 1);
#dd $ldml;
my $xpc = XML::LibXML::XPathContext->new($ldml);

#my $collnode = $xpc->findnodes('/ldml/collations/collation[@type = "standard"]/rules')->get_node(1);

my %levels = ( p => '<' , s => '<<' , t => '<<<', q => '<<<<', i => '=', extend => '/', context => '|' );
# "q" is not explained in UTS#35 but stands obviously for "quaternary"

my %levelNames = ( primary => 1 , secondary => 2 , tertiary => 3 ,
    quaternary => 4, identical => 5 );

my @settingsOK = qw/strength alternate backwards normalization caseLevel
caseFirst hiraganaQuaternary numeric variableTop match-boundaries match-style/;

my %settingsAliases = ( strength => 'level', alternate => 'variable' );
#TODO map on/off to 1/0
#TODO "caseFirst = upper" => 'upper_before_lower = 1'

#TODO implement these in U::C
my @settingsUnimplemented = qw/caseLevel hiraganaQuaternary numeric
  variableTop match-boundaries match-style/;

#TODO: these are not implemented in U::C yet
my @logicalResets = qw/first_variable last_variable first_tertiary_ignorable
 last_tertiary_ignorable first_secondary_ignorable last_secondary_ignorable
 first_primary_ignorable last_primary_ignorable first_non_ignorable
 last_non_ignorable first_trailing last_trailing/;

my %tailoring;

# catch '/ldml/identity/version/@number' (and remove /^$Revision:\s*/ and /\s*\$$/)
my $version = $xpc->findvalue('/ldml/identity/version/@number');
$version =~ s/^\$Revision:\s*//;
$version =~ s/\s*\$$//;

$tailoring{version} = $version;

#check for '/ldml/collations/alias'
if ( $xpc->exists('/ldml/collations/alias') ) {
    my $alias = $xpc->findvalue('/ldml/collations/alias/@source');
    #...
    $tailoring{alias} = $alias;
    #FIXME NEXT LOCALE
}

#catch '/ldml/collations/default'
if ( $xpc->exists('/ldml/collations/default') ) {
    my $default = $xpc->findvalue('/ldml/collations/default/@type');
    #...
    $tailoring{default_type} = $default;
}

my $collnodes = $xpc->findnodes('/ldml/collations/collation');

#TODO sub process_collations {
# my $collnodes = shift;
foreach my $c ($collnodes->get_nodelist) {
    # else create new subhash with value of @type
    my $type = $c->findvalue('@type') || 'default'; #TODO check for uniqueness of node of this type
    my $alt  = $c->findvalue('@alt') if $c->exists('@alt'); #ignore unless there are more than one for the same @type
    # check if alias then register it
    if ( $c->exists('alias') ) {
        my $alias = $c->findvalue('alias');
        $tailoring{$type}{alias} = $alias; #FIXME << check this
        next;
    }
    # then get %settings
    my %settings;
    if ( $c->exists('settings') ) {
        my $settings_node = $c->findnodes('settings')->get_node(1);
        if ($settings_node->hasAttributes) {
            my @attrlist = $settings_node->attributes();
            foreach my $attr ( @attrlist ) {
                #print "attribute: " . $attr->nodeName . " = " . $attr->to_literal . "\n";
                $settings{$attr->nodeName} = $attr->to_literal;
            }
        }
    }

    if ( $c->exists('suppress_contractions') ) {
        my $suppr_contr = $c->findvalue('suppress_contractions');
        $settings{suppress_contractions} = $suppr_contr
    }
#    OMITTED
#    if ( $c->exists('optimize') ) {
#        my $optimize = $c->findvalue('optimize');
#        $settings{optimize} = $optimize
#    }

    #dd %settings;
    $tailoring{$type}{settings} = { %settings } if %settings;
    # also get elements "suppress_contractions", "optimize", and "special" but ignore them for now
    # check if "base" ref then register it
    # then parse rules:
    my $rules_node = $c->findnodes('rules')->get_node(1);
    # ddx $rules_node;
    if ($rules_node) {
        #TODO catch 'rules/alias' if any, else process_rules()
        $tailoring{$type}{rules} = process_rules($rules_node) ;
    }
}

dd %tailoring;

sub process_rules {
    my $collnode = shift;
    my $str = '';
    foreach my $child ($collnode->childNodes) {
        next unless $child->nodeType == 1; # XML_ELEMENT_NODE = 1
        my $name = $child->nodeName;
        if ( $name eq 'reset' ) {
            $str .= "\n" unless $str eq '';
            $str .= "& " ;
            if ( $child->exists('@before') ) {
                my $before_value = $child->find('@before')->string_value;
                $str .= '[before ' . $levelNames{$before_value} . '] ';
            }
            #TODO if $child->nodeType == 1 then use "[$child->nodeName]" if it is in @logicalReset
            $str .= $child->string_value . ' ';
        }
        elsif ($name eq 'x') {
            foreach my $grandchild ($child->childNodes) {
                $str .= process_rule($grandchild);
            }
        }
        else {
            $str .= process_rule($child) ;
        }
    }
    return $str
}

sub process_rule {
    my $node = shift;
    my $type = $node->nodeName;
    #TODO if $node has childNode of nodeType == 1
    #  then use "[$child->nodeName]" if it is in @logicalReset
    #  else use string_value:
    my $value = $node->string_value;
    my @chars = ($value);
    my $levtype = '???'; # to indicate unimplemented elements
    my $basetype = $type;
    if ( $type =~ /^[psti]c$/ ) {
        $basetype =~ s/c$//;
        @chars = split //, $value;
    }
    if ( exists $levels{$basetype} ) {
        $levtype = $levels{$basetype} ;
    } else {
        carp "Unable to handle unknown element $basetype";
    }

    my $str = '';
    foreach my $char (@chars) {
        $str .= $levtype . ' ' . $char . ' ';
    }

    return $str;
}

