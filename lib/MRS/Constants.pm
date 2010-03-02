#-----------------------------------------------------------------
# MRS::Constants
# Authors: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see MRS::Client pod.
#-----------------------------------------------------------------

use strict;
use warnings;
use vars qw( @EXPORT @ISA );

@ISA = qw( Exporter );
@EXPORT = qw( $DEFAULT_SEARCH_ENDPOINT $DEFAULT_BLAST_ENDPOINT $DEFAULT_CLUSTAL_ENDPOINT $DEFAULT_ADMIN_ENDPOINT $DEFAULT_SEARCH_WSDL $DEFAULT_BLAST_WSDL $DEFAULT_CLUSTAL_WSDL $DEFAULT_ADMIN_WSDL $DEFAULT_SEARCH_SERVICE $DEFAULT_BLAST_SERVICE $DEFAULT_CLUSTAL_SERVICE $DEFAULT_ADMIN_SERVICE );

#-----------------------------------------------------------------
#
#  Expoted constants
#
#-----------------------------------------------------------------
use constant DEFAULT_SEARCH_ENDPOINT  => 'http://mrs.cmbi.ru.nl/mrsws/search';
use constant DEFAULT_BLAST_ENDPOINT   => 'http://mrs.cmbi.ru.nl/mrsws/blast';
use constant DEFAULT_CLUSTAL_ENDPOINT => 'http://mrs.cmbi.ru.nl/mrsws/clustal';
use constant DEFAULT_ADMIN_ENDPOINT   => 'http://mrs.cmbi.ru.nl/mrsws/admin';
use constant DEFAULT_SEARCH_WSDL      => 'search.wsdl.template';
use constant DEFAULT_BLAST_WSDL       => 'blast.wsdl.template';
use constant DEFAULT_CLUSTAL_WSDL     => 'clustal.wsdl.template';
use constant DEFAULT_ADMIN_WSDL       => 'admin.wsdl.template';
use constant DEFAULT_SEARCH_SERVICE   => 'mrsws_search';
use constant DEFAULT_BLAST_SERVICE    => 'mrsws_blast';
use constant DEFAULT_CLUSTAL_SERVICE  => 'mrsws_clustal';
use constant DEFAULT_ADMIN_SERVICE    => 'mrsws_admin';

#-----------------------------------------------------------------
#
#  MRS::EntryFormat ... enumeration of entry formats
#
#-----------------------------------------------------------------
package MRS::EntryFormat;

use constant {
    PLAIN    => 'plain',
    TITLE    => 'title',
    HTML     => 'html',
    FASTA    => 'fasta',
    SEQUENCE => 'sequence',
    HEADER   => 'header',    # only limited usage
};

#-----------------------------------------------------------------
# Return 1 only if $format is one of the recognized constants
# -----------------------------------------------------------------
sub check {
    my ($class, $format) = @_;
    return 0 unless $format;
    my $regex =
	PLAIN . '|' . TITLE . '|' . HTML . '|' . FASTA . '|' . SEQUENCE .
	'|' . HEADER;
    my $regex_c = qr/^($regex)$/;
    $format =~ $regex_c;
}

#-----------------------------------------------------------------
#
#  MRS::Algorithm ... enumeration of scoring algorithms
#
#-----------------------------------------------------------------
package MRS::Algorithm;

use constant {
    VECTOR   => 'Vector',
    DICE     => 'Dice',
    JACCARD  => 'Jaccard',
};

#-----------------------------------------------------------------
# Return 1 only if $algorithm is one of the recognized constants
# -----------------------------------------------------------------
sub check {
    my ($class, $algorithm) = @_;
    return 0 unless $algorithm;
    my $regex = VECTOR . '|' . DICE . '|' . JACCARD;
    my $regex_c = qr/^($regex)$/;
    $algorithm =~ $regex_c;
}

#-----------------------------------------------------------------
#
#  MRS::Operator ... enumeration of operators
#
#-----------------------------------------------------------------
package MRS::Operator;

use constant {
    CONTAINS       => 'CONTAINS',
    LT             => 'LT',
    LE             => 'LE',
    EQ             => 'EQ',
    GT             => 'GT',
    GE             => 'GE',
    UNION          => 'UNION',
    INTERSECTION   => 'INTERSECTION',
    NOT            => 'NOT',
    OR             => 'OR',
    AND            => 'AND',
    ADJACENT       => 'ADJACENT',
    CONTAINSSTRING => 'CONTAINSSTRING',
};

#-----------------------------------------------------------------
# Return 1 only if $query contains at least one of the recognized
# operators (which qualifies it for an expression)
# -----------------------------------------------------------------
sub contains {
    my ($class, $query) = @_;
    return 0 unless $query;
    my $regex =
	CONTAINS . '|' . UNION . '|' . INTERSECTION .
	'|' . LT . '|' . LE. '|' . EQ . '|' . GT . '|' . GE .
	'|' . NOT . '|' . '|' . OR . '|' . AND .
	'|' . ADJACENT . '|' . CONTAINSSTRING;
    my $regex_c = qr/\W+($regex)\W+/;
    $query =~ $regex_c;
}

#-----------------------------------------------------------------
#
#  MRS::JobStatus ... enumeration of blast job states
#
#-----------------------------------------------------------------
package MRS::JobStatus;

use constant {
    UNKNOWN  => 'unknown',
    QUEUED   => 'queued',
    RUNNING  => 'running',
    ERROR    => 'error',
    FINISHED => 'finished',
};

#-----------------------------------------------------------------
# Return 1 only if $status is one of the recognized constants
# -----------------------------------------------------------------
sub check {
    my ($class, $status) = @_;
    return 0 unless $status;
    my $regex = UNKNOWN . '|' . QUEUED . '|' . RUNNING . '|' . ERROR . '|' . FINISHED;
    my $regex_c = qr/^($regex)$/;
    $status =~ $regex_c;
}

#-----------------------------------------------------------------
#
#  MRS::BlastOutputFormat
#
#-----------------------------------------------------------------
package MRS::BlastOutputFormat;

use constant {
    XML   => 'xml',
    HITS  => 'hits',
    FULL  => 'full',
    STATS => 'stats',
};

#-----------------------------------------------------------------
# Return 1 only if $format is one of the recognized constants
# -----------------------------------------------------------------
sub check {
    my ($class, $format) = @_;
    return 0 unless $format;
    my $regex = XML . '|' . HITS . '|' . FULL . '|' . STATS;
    my $regex_c = qr/^($regex)$/;
    $format =~ $regex_c;
}

1;
__END__
=head1 NAME

MRS::Constants - part of a SOAP-based client accessing MRS databases

=head1 REDIRECT

For the full documentation of the project see please:

   perldoc MRS::Client

=cut
