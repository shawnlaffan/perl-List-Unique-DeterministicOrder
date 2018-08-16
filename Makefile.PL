use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Deterministic::Access',
    AUTHOR           => q{SLAFFAN <shawnlaffan@gmail.com>},
    VERSION_FROM     => 'lib/Data/Deterministic/Access.pm',
    ABSTRACT_FROM    => 'lib/Data/Deterministic/Access.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'autovivification' => 0,
        'List::Util' => 0,
        'Carp' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Deterministic-Access-*' },
);
