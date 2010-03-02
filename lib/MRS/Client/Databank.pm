#-----------------------------------------------------------------
# MRS::Client::Databank
# Authors: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see MRS::Client pod.
#
# Representation of a MRS databank - on a client side.
#-----------------------------------------------------------------
package MRS::Client::Databank;

use Carp;
use MRS::Constants;

#-----------------------------------------------------------------
# Mandatory argument is an 'id' defining what databank should be
# created. However, this method does not need to be called directly:
# better to use factory method db() of MRS::Client.
# -----------------------------------------------------------------
sub new {
    my ($class, %args) = @_;

    # create an object and fill it from $args
    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    # check that we have at least an ID
    croak ("The MRS::Client::Databank instance cannot be created without an ID.\n")
	unless $self->{id};

    # done
    return $self;
}

#-----------------------------------------------------------------
# Getter. Most of them first fill the databank from the server.
# -----------------------------------------------------------------
sub id        { return shift->{id}; }
sub name      { return shift->_populate_info->{name}; }
sub blastable { return shift->_populate_info->{blastable}; }
sub url       { return shift->_populate_info->{url}; }
sub parser    { return shift->_populate_info->{script}; }
sub files     { return shift->_populate_info->{files}; }
sub indices   { return shift->_populate_indices->{indices}; }
sub count     { return shift->_populate_count->{count}; }

sub version {
    my $self = shift;
    my $r = '';
    foreach my $file (@{ $self->files }) {
	$r .= ', ' if $r;
	$r .= $file->version;
    }
    return $r;
}

#-----------------------------------------------------------------
# Mostly for debugging - because it may be expensive: It calls several
# SOAP operations to fill first the databank.
# -----------------------------------------------------------------
use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    my $r = '';
    $r .= "Id:      " . $self->{id}   . "\n";
    $r .= "Name:    " . $self->{name} . "\n" if $self->{name};
    $r .= "Version: " . $self->version  . "\n";
    $r .= "Count:   " . $self->count  . "\n";
    $r .= "URL:     " . $self->{url}  . "\n" if $self->{url};
    $r .= "Parser:  " . $self->parser  . "\n" if $self->parser;
    $r .= "blastable\n" if $self->{blastable};
    $r .= "Files:\n\t" . join ("\n\t", map { s/\n/\n\t/g; $_ } @{ $self->files } ) . "\n";
    $r .= "Indices:\n\t" . join ("\n\t", @{ $self->indices } ) . "\n";
    return $r;
}

#-----------------------------------------------------------------
# If this instance does not have yet info data then populate them.
# Return itself (the databank instance).
#-----------------------------------------------------------------
sub _populate_info {
    my $self = shift;
    return $self if $self->{info_retrieved};

    $self->{client}->_create_proxy ('search');
    my $answer = $self->{client}->_call (
	$self->{client}->{search_proxy}, 'GetDatabankInfo',
	{ db => $self->{id} });
    $self->{info_retrieved} = 1;
    if (defined $answer) {
	foreach my $info (@{ $answer->{parameters}->{info} }) {
	    foreach my $key (keys %$info) {
		$self->{$key} = $info->{$key};
	    }
	}
	# special treatment for 'files': create File objects
	$self->{files} = 
	    [ map { MRS::Client::Databank::File->new (%$_) } @{ $self->{files} } ];
    }
    return $self;
}

#-----------------------------------------------------------------
# If this instance does not have yet indices then populate them.
# Return itself (the databank instance).
#-----------------------------------------------------------------
sub _populate_indices {
    my $self = shift;
    return $self if $self->{indices_retrieved};

    $self->{client}->_create_proxy ('search');
    my $answer = $self->{client}->_call (
	$self->{client}->{search_proxy}, 'GetIndices',
	{ db => $self->{id} });
    $self->{indices_retrieved} = 1;
    if (defined $answer) {
	$self->{indices} =
	    [ map { MRS::Client::Databank::Index->new (%$_) }
	      @{ $answer->{parameters}->{indices} } ];
    }
    return $self;
}

#-----------------------------------------------------------------
# If this instance does not have yet its count then populate it.
# Return itself (the databank instance).
#-----------------------------------------------------------------
sub _populate_count {
    my $self = shift;
    return $self if defined $self->{count};

    $self->{client}->_create_proxy ('search');
    my $answer = $self->{client}->_call (
	$self->{client}->{search_proxy}, 'Count',
	{ db => $self->{id},
	  booleanquery => '*'});
    if (defined $answer) {
	$self->{count} = $answer->{parameters}->{response}->bstr();
    } else {
	$self->{count} = 0;
    }
    return $self;
}

#-----------------------------------------------------------------
# Make a query. See MRS::Client::Find->new about the parameters.
#-----------------------------------------------------------------
sub find {
    my $self = shift;
    my $find = MRS::Client::Find->new (@_);
    $find->{db} = $self->{id};
    $find->{dbobj} = $self;
    $find->{client} = $self->{client};

    my $record = $find->_read_next_hits;
    unshift (@{ $find->{hits} }, $record) if $record;

    return $find;
}

#-----------------------------------------------------------------
# Get an entry defined by $entry_id in the $format (optional).
#-----------------------------------------------------------------
sub entry {
    my ($self, $entry_id, $format) = @_;

    croak "Empty entry ID. Cannot do anything, I am afraid.\n"
	unless $entry_id;
    $format = MRS::EntryFormat->PLAIN
	unless MRS::EntryFormat->check ($format);
    warn ("Method 'entry' does not support format HEADER. Reversed to TITLE.\n")
	and $format = MRS::EntryFormat->TITLE
	if $format eq MRS::EntryFormat->HEADER;

    $self->{client}->_create_proxy ('search');
    my $answer = $self->{client}->_call (
	$self->{client}->{search_proxy}, 'GetEntry',
	{ db => $self->{id},
	  id => $entry_id,
	  format => $format });
    return '' unless defined $answer;
    return $answer->{parameters}->{entry};
}

#-----------------------------------------------------------------
#
#  MRS::Client::Databank::File ... info about a file of a databank
#
#-----------------------------------------------------------------
package MRS::Client::Databank::File;

sub new {
    my ($class, %file) = @_;

    # create an object and fill it from $file
    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %file) {
        $self->{$key} = $file {$key};
    }

    # done
    return $self;
}

sub id             { return shift->{uuid}; }
sub raw_data_size  { return shift->{rawDataSize}->bstr(); }
sub entries_count  { return shift->{entries}->bstr(); }
sub file_size      { return shift->{fileSize}->bstr(); }
sub version        { return shift->{version}; }
sub last_modified  { return shift->{modificationDate}; }

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    "Version:       " . $self->version       . "\n" .
    "Modified:      " . $self->last_modified . "\n" .
    "Entries count: " . $self->entries_count . "\n" .
    "Raw data size: " . $self->raw_data_size . "\n" .
    "File size:     " . $self->file_size     . "\n" .
    "Unique Id:     " . $self->id
    ;
}

#-----------------------------------------------------------------
#
#  MRS::Client::Databank::Index
#
#-----------------------------------------------------------------
package MRS::Client::Databank::Index;

sub new {
    my ($class, %args) = @_;

    # create an object and fill it from $args
    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    # done
    return $self;
}

sub id          { return shift->{id}; }
sub description { return shift->{description}; }
sub count       { return shift->{count}->bstr(); }
sub type        { return shift->{type}; }

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    return sprintf (
	"%-15s%9d  %-9s %s",
	$self->id, $self->count, $self->type, $self->description);
}

1;
__END__

=head1 NAME

MRS::Client::Databank - part of a SOAP-based client accessing MRS databases

=head1 REDIRECT

For the full documentation of the project see please:

   perldoc MRS::Client

=cut
