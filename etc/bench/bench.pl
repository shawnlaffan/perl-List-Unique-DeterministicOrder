
use Benchmark qw {:all};
use 5.016;
use Data::Dumper;
use Test::More;

use rlib '../../lib';

use Data::Deterministic::Access;
use List::BinarySearch::XS qw /binsearch/;
use List::MoreUtils::XS 0.423 qw/bremove binsert/;
use List::MoreUtils;# qw /bremove/;

use Clone qw /clone/;


my $nreps = $ARGV[0] || 500;
my $data_size = $ARGV[1] || 1000;
my $run_benchmarks = $ARGV[2];

srand 1534390472;

my %hashbase;
#@hash{1..1000} = (rand()) x 1000;
for my $i (1..$data_size) {
    $hashbase{$i} = rand() + 1;
}
my $hashref = \%hashbase;

my %insertion_hash;
for my $i ('a' .. 'zzzz') {
    $insertion_hash{$i} = rand() + 1;
}
my @insertions = sort {$insertion_hash{$a} <=> $insertion_hash{$b}} keys %insertion_hash;


my @sorted_keys = sort keys %$hashref;

my $dds_base = Data::Deterministic::Access->new();
foreach my $key (@sorted_keys) {
    $dds_base->push ($key);
}

my %data = (
    lmu => [],
    lbs => [],
    ldd => [],
    baseline => [],
);

#  make lots of copies to ensure data creation
#  is outside the benchmarking
foreach my $i (0 .. $nreps+1) {
    push @{$data{lmu}}, [@sorted_keys];
    push @{$data{lbs}}, [@sorted_keys];
    push @{$data{ldd}}, clone $dds_base;
    push @{$data{baseline}}, [@sorted_keys];
}




my $l1 = lmu();
my $l2 = lbs();
my $l3 = ldd();

say 'First few items in each list:';
say join ' ', @$l1[0 .. 5];
say join ' ', @$l2[0 .. 5];
say join ' ', @$l3[0 .. 5];

is_deeply ($l1, $l2, 'same order');
is_deeply ($l1, [sort @$l3], 'same contents');

done_testing();

exit if !$run_benchmarks;


cmpthese (
    $nreps,
    {
        lmu  => sub {lmu()},
        lbs  => sub {lbs()},
        ldd  => sub {ldd()},
        baseline => sub {baseline()},
    }
);

sub lbs {
    my $list = shift @{$data{lbs}};
    my $i = -1;
    foreach my $key (keys %hashbase) {
        $i++;
        delete_from_sorted_list_aa($key, $list);
        my $insert = $insertions[$i] // next;
        binsert {$_ cmp $insert} $insert, @$list;
    }
    $list;
}

sub delete_from_sorted_list_aa {
    my $idx  = binsearch { $a cmp $b } $_[0], @{$_[1]};
    splice @{$_[1]}, $idx, 1;

    $idx;
}

sub insert_into_sorted_list_aa {
    my $idx  = binsearch_pos { $a cmp $b } $_[1], @{$_[2]};
    splice @{$_[2]}, $idx, 0, $_[1];

    $idx;
}


sub lmu {
    my $list = shift @{$data{lmu}};
    my $i = -1;
    foreach my $key (keys %hashbase) {
        $i++;
        bremove {$_ cmp $key} @$list;
        my $insert = $insertions[$i] // next;
        binsert {$_ cmp $insert} $insert, @$list;
    }
    $list;
}

sub ldd {
    my $dds = shift @{$data{ldd}};
    my $i = -1;
    foreach my $key (keys %hashbase) {
        $i++;
        $dds->delete ($key);
        my $insert = $insertions[$i] // next;
        $dds->push ($insert);
    }
    [$dds->keys];
}

sub baseline {
    my $list = shift @{$data{baseline}};
    my $i;
    foreach my $key (keys %hashbase) {
        $i++;
        my $insert = $insertions[$i] // next;
    }
    $list;
}

__END__

perl etc\bench\bench.pl 5000 1000 1
First few items:
aali aanc afib afzk agxb ahdg
aali aanc afib afzk agxb ahdg
pwey scmn hfhd eqdg xsyo vpev
ok 1 - same order
ok 2 - same contents
1..2
           Rate      lmu      lbs      ldd baseline
lmu       151/s       --      -5%     -62%     -97%
lbs       159/s       5%       --     -60%     -97%
ldd       394/s     161%     147%       --     -93%
baseline 5612/s    3614%    3425%    1326%       --

