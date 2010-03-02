use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MRS::Client',
    AUTHOR              => 'Martin Senger <martin.senger@gmail.com>',
    VERSION_FROM        => 'lib/MRS/Client.pm',
    ABSTRACT_FROM       => 'lib/MRS/Client.pod',
    EXE_FILES           => ['scripts/mrsclient', 'scripts/mrsblast', 'scripts/mrsclustal'],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'XML::Compile::SOAP11' => 0,
	'XML::Compile::WSDL11' => 0,
	'XML::Compile::Transport::SOAPHTTP' => 0,
	'File::Basename' => 0,
	'Math::BigInt' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MRS-Client-*' },
);
