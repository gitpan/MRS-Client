#-----------------------------------------------------------------
# MRS::Client
# Authors: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see MRS::Client pod.
#
# A SOAP-based client of the MRS Retrieval server
#-----------------------------------------------------------------

package MRS::Client;

use strict;
use warnings;
use vars qw( $AUTOLOAD );

use Carp;
use XML::Compile::SOAP11;
use XML::Compile::WSDL11;
use XML::Compile::Transport::SOAPHTTP;
use File::Basename;

use MRS::Constants;
use MRS::Client::Databank;
use MRS::Client::Find;
use MRS::Client::Blast;
use MRS::Client::Clustal;

#-----------------------------------------------------------------
# Global variables (available for all packages in this file)
#-----------------------------------------------------------------
our $VERSION = '0.53';

#-----------------------------------------------------------------
# A list of allowed options/arguments (used in the new() method)
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 search_url       => 1,
         blast_url        => 1,
	 clustal_url      => 1,
	 admin_url        => 1,

	 search_service   => 1,
         blast_service    => 1,
	 clustal_service  => 1,
	 admin_service    => 1,

	 search_wsdl      => 1,
	 blast_wsdl       => 1,
	 clustal_wsdl     => 1,
	 admin_wsdl       => 1,

	 host             => 1,
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr};
    }
}

#-----------------------------------------------------------------
# Deal with 'set' and 'get' methods.
#-----------------------------------------------------------------
sub AUTOLOAD {
    my ($self, $value) = @_;
    my $ref_sub;
    if ($AUTOLOAD =~ /.*::(\w+)/ && $self->_accessible ("$1")) {

	# get/set method
	my $attr_name = "$1";
	$ref_sub =
	    sub {
		# get method
		local *__ANON__ = "__ANON__$attr_name" . "_" . ref ($self);
		my ($this, $value) = @_;
		return $this->{$attr_name} unless defined $value;

		# set method
		$this->{$attr_name} = $value;
		return $this->{$attr_name};
	    };

    } else {
	throw ("No such method: $AUTOLOAD");
    }

    no strict 'refs'; 
    *{$AUTOLOAD} = $ref_sub;
    use strict 'refs'; 
    return $ref_sub->($self, $value);
}

#-----------------------------------------------------------------
# Keep it here! The reason is the existence of AUTOLOAD...
#-----------------------------------------------------------------
sub DESTROY {
}

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------
sub new {
    my ($class, @args) = @_;

    # create an object
    my $self = bless {}, ref ($class) || $class;

    # set default values
    $self->search_url ($ENV{'MRS_SEARCH_URL'} or DEFAULT_SEARCH_ENDPOINT);
    $self->blast_url ($ENV{'MRS_BLAST_URL'} or DEFAULT_BLAST_ENDPOINT);
    $self->clustal_url ($ENV{'MRS_CLUSTAL_URL'} or DEFAULT_CLUSTAL_ENDPOINT);
    $self->admin_url ($ENV{'MRS_ADMIN_URL'} or DEFAULT_ADMIN_ENDPOINT);
    $self->search_service (DEFAULT_SEARCH_SERVICE);
    $self->blast_service (DEFAULT_BLAST_SERVICE);
    $self->clustal_service (DEFAULT_CLUSTAL_SERVICE);
    $self->admin_service (DEFAULT_ADMIN_SERVICE);

    $self->{compiled_operations} = {};

    # set all @args into this object with 'set' values
    my (%args) = (@args == 1 ? (value => $args[0]) : @args);
    foreach my $key (keys %args) {
        no strict 'refs';
        $self->$key ($args {$key});
    }
    $self->host ($ENV{'MRS_HOST'}) if $ENV{'MRS_HOST'};

    # done
    return $self;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub host {
    my ($self, $host) = @_;
    return $self->{host} unless $host;

    my $current = $self->{host};

    # use $host and default ports,
    # unless some URLs were given specifically
    if ( $self->search_url eq DEFAULT_SEARCH_ENDPOINT or
	 ($current and $self->search_url eq "http://$current:18081/") ) {
	$self->search_url  ("http://$host:18081/");
    }
    if ( $self->blast_url eq DEFAULT_BLAST_ENDPOINT or
	 ($current and $self->blast_url eq "http://$current:18082/") ) {
	$self->blast_url  ("http://$host:18082/");
    }
    if ( $self->clustal_url eq DEFAULT_CLUSTAL_ENDPOINT or
	 ($current and $self->clustal_url eq "http://$current:18083/") ) {
	$self->clustal_url  ("http://$host:18083/");
    }
    if ( $self->admin_url eq DEFAULT_ADMIN_ENDPOINT or
	 ($current and $self->admin_url eq "http://$current:18084/") ) {
	$self->admin_url  ("http://$host:18084/");
    }
    $self->{host} = $host;
}

#-----------------------------------------------------------------
# Read the WSDL file, create from it a proxy and store it in
# itself. Do it only once unless $force_creation is defined.
#
# $ptype tells what kind of proxy to create: search, blast, clustal or
# admin.
#
# What WSDL file is read: It reads file previously set by one of the
# methods (depending which proxy should be read): search_wsdl(),
# blast_wsdl(), clustal_wsdl or admin_wsdl(). If such method was not
# called, the default WSDL is read from the file named '$ptype
# . _proxy', located in the same directory as this module.
# -----------------------------------------------------------------
sub _create_proxy {
    my ($self, $ptype, $default_wsdl, $force_creation) = @_;
    $self->{$ptype . '_proxy'} = undef if $force_creation;
    if (not defined $self->{$ptype . '_proxy'}) {
	my $wsdl;
	if (not defined $self->{$ptype . '_wsdl'}) {
	    $wsdl = _readfile ( (fileparse (__FILE__))[-2] . _default_wsdl ($ptype) );
	    $wsdl =~ s/\${LOCATION}/$self->{$ptype . '_url'}/eg;
	    $wsdl =~ s/\${SERVICE}/$self->{$ptype . '_service'}/eg;
	} else {
	    $wsdl  = XML::LibXML->new->parse_file ($self->{$ptype . '_wsdl'});
	}
	$self->{$ptype . '_proxy'} = XML::Compile::WSDL11->new ($wsdl);
    }
}

sub _default_wsdl {
    my $ptype = shift;
    return DEFAULT_SEARCH_WSDL  if $ptype eq 'search';
    return DEFAULT_BLAST_WSDL   if $ptype eq 'blast';
    return DEFAULT_CLUSTAL_WSDL if $ptype eq 'clustal';
    return DEFAULT_ADMIN_WSDL   if $ptype eq 'admin';
    die "Uknown proxy type '" . $ptype . "'\n";
}

sub _readfile {
    my $filename = shift;
    my $data;
    {
	local $/=undef;
	open FILE, $filename or croak "Couldn't open file $filename: $!\n";
	$data = <FILE>;
	close FILE;
    }
    return $data;
}

#-----------------------------------------------------------------
# Make a SOAP call to a MRS server, using $proxy (created usually by
# _create_proxy), invoking $operation with $parameters (a hash
# reference).
# -----------------------------------------------------------------
sub _call {
    my ($self, $proxy, $operation, $parameters) = @_;

    # the compiled client for the same operation may be already
    # cached; if not then compile it and save for later
    my $call = $self->{compiled_operations}->{$operation};
    unless (defined $call) {
	$call = $proxy->compileClient ($operation);
	$self->{compiled_operations}->{$operation} = $call;
    }

    # make a SOAP call
    my ($answer, $trace) = $call->( %$parameters );

    # $trace->printTimings;
    # $trace->printRequest;
    # $trace->printResponse;

    croak 'ERROR: ' . $answer->{Fault}->{'faultstring'} . "\n"
	if defined $answer and defined $answer->{Fault};

    return $answer;
}

#-----------------------------------------------------------------
# Factory method for creating one or more databanks:
#   it returns an array of MRS::Client::Databank if $db is undef or empty
#   else it returns a databank indicated by $db (which is an Id) 
#-----------------------------------------------------------------
sub db {
    my ($self, $db) = @_;

    return MRS::Client::Databank->new (id => $db, client => $self)
	if $db and $db ne 'all';

    $self->_create_proxy ('search');
    my $answer = $self->_call (
	$self->{search_proxy}, 'GetDatabankInfo', { db => 'all' });
    my @dbs = ();
    return @dbs unless defined $answer;
    foreach my $info (@{ $answer->{parameters}->{info} }) {
	push (@dbs, MRS::Client::Databank->new (%$info, client => $self));
    }
    return @dbs;
}

#-----------------------------------------------------------------
# The same as db->find but acting on all available databanks
#-----------------------------------------------------------------
sub find {
    my $self = shift;

    my $multi = MRS::Client::MultiFind->new (@_);
    $multi->{client} = $self;

    # create individual finds for each available databank
    $multi->{args} = \@_;   # will be needed for cloning
    $multi->{children} = $multi->_read_first_hits;
    $multi->{current} = 0; 

    # do we have any hits, at all?
    $multi->{eod} = 1 if @{ $multi->{children} } == 0;

    return $multi;
}

#-----------------------------------------------------------------
# Create a blast object - it can be used for running more jobs, with
# different parameters [TBD: , giving a statistics about all jobs?]
#
# Create maximum one blast object; we do not need more.
# -----------------------------------------------------------------
sub blast {
    my $self = shift;
    return $self->{blastobj} if $self->{blastobj};
    $self->{blastobj} = MRS::Client::Blast->_new (client => $self);
    return $self->{blastobj};
}

#-----------------------------------------------------------------
# Create a clustal object; a simple factory method.
# -----------------------------------------------------------------
sub clustal {
    my $self = shift;
    return MRS::Client::Clustal->_new (client => $self);
}

#-----------------------------------------------------------------
#
# Admin calls ... work in progress, and not really supported
#
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# Return a script that parses a databank. $script is its name.
#-----------------------------------------------------------------
sub parser {
    my ($self, $script) = @_;

    croak "Empty parser name. Cannot retrieve it, I am afraid.\n"
	unless $script;

    $self->_create_proxy ('admin');
    my $answer = $self->_call (
	$self->{admin_proxy}, 'GetParserScript',
	{ script => $script,
	  format => 'plain' });
    return  $answer->{parameters}->{response};
}

1;
__END__


#-----------------------------------------------------------------
# only for debugging
#-----------------------------------------------------------------
# sub _print_operations {
#     my ($proxy) = @_;
#     my @opers = $proxy->operations();
#     foreach my $oper (@opers) {
# 	print $oper->name . "\n";
#     }
#     print "\n";
# }

# sub _list_of_all_operations {
#     my $self = shift;
#     $self->_create_proxy ('search');
#     $self->_create_proxy ('blast');
#     $self->_create_proxy ('clustal');
#     $self->_create_proxy ('admin');

#     _print_operations ($self->{search_proxy});
#     _print_operations ($self->{blast_proxy});
#     _print_operations ($self->{clustal_proxy});
#     _print_operations ($self->{admin_proxy});
# }

