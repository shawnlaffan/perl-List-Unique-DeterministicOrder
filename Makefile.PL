use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'List::Unique::DeterministicOrder',
    AUTHOR           => q{SLAFFAN <shawnlaffan@gmail.com>},
    VERSION_FROM     => 'lib/List/Unique/DeterministicOrder.pm',
    ABSTRACT_FROM    => 'lib/List/Unique/DeterministicOrder.pm',
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
    clean => { FILES => 'List-Unique-DeterministicOrder-*' },
);
