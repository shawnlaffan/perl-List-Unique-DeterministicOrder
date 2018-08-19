
use Benchmark qw {:all};
use 5.016;
use Data::Dumper;
use Test::More;

use rlib '../../lib';

use List::Unique::DeterministicOrder;
use List::BinarySearch::XS qw /binsearch/;
use List::MoreUtils::XS 0.423 qw/bremove binsert/;
use List::MoreUtils;# qw /bremove/;
use Hash::Ordered;

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
my @sorted_pairs = map {$_ => 1} @sorted_keys;

my $dds_base = List::Unique::DeterministicOrder->new(data => \@sorted_keys);
my $ho_base  = Hash::Ordered->new (@sorted_pairs);

my %data = (
    lmu => [],
    lbs => [],
    ldd => [],
    lho => [],
    baseline => [],
);

#  make lots of copies to ensure data generation
#  is outside the benchmarking
foreach my $i (0 .. $nreps+1) {
    push @{$data{lmu}}, [@sorted_keys];
    push @{$data{lbs}}, [@sorted_keys];
    push @{$data{ldd}}, clone $dds_base;
    push @{$data{lho}}, clone $ho_base;
    push @{$data{baseline}}, [@sorted_keys];
}




my $l1 = lmu();
my $l2 = lbs();
my $l3 = ldd();
my $l4 = lho();

say 'First few items in each list:';
say join ' ', @$l1[0 .. 5];
say join ' ', @$l2[0 .. 5];
say join ' ', @$l3[0 .. 5];
say join ' ', @$l4[0 .. 5];

is_deeply ($l1, $l2, 'same order');
is_deeply ($l1, [sort @$l3], 'same contents, list-u-det-order');
is_deeply ($l1, [sort @$l4], 'same contents, hash ordered');


done_testing();

exit if !$run_benchmarks;


cmpthese (
    $nreps,
    {
        lmu  => sub {lmu()},
        lbs  => sub {lbs()},
        ldd  => sub {ldd()},
        lho  => sub {lho()},
        baseline => sub {baseline()},
    }
);

sub lbs {
    my $list = shift @{$data{lbs}};
    my $i = -1;
    foreach my $key (@sorted_keys) {
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
    foreach my $key (@sorted_keys) {
        $i++;
        bremove {$_ cmp $key} @$list;
        my $insert = $insertions[$i] // next;
        binsert {$_ cmp $insert} $insert, @$list;
    }
    $list;
}

sub ldd {
    #  $dds reflects the old name for the module
    my $dds = shift @{$data{ldd}};
    my $i = -1;
    foreach my $key (@sorted_keys) {
        $i++;
        $dds->delete ($key);
        my $insert = $insertions[$i] // next;
        $dds->push ($insert);
    }
    [$dds->keys];
}

sub lho {
    my $ho = shift @{$data{lho}};
    my $i = -1;
    foreach my $key (@sorted_keys) {
        $i++;
        $ho->delete ($key);
        my $insert = $insertions[$i] // next;
        $ho->set ($insert => 1);
    }
    [$ho->keys];
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
First few items in each list:
aali aanc afib afzk agxb ahdg
aali aanc afib afzk agxb ahdg
pkme hmfp rtyt mwpd blnm njh
hmfp rtyt mwpd blnm njh xgre
ok 1 - same order
ok 2 - same contents, list-u-det-order
ok 3 - same contents, hash ordered
1..3
           Rate      lmu      lbs      lho      ldd baseline
lmu       178/s       --      -3%     -25%     -64%     -96%
lbs       184/s       3%       --     -23%     -63%     -96%
lho       239/s      34%      30%       --     -52%     -95%
ldd       501/s     181%     172%     109%       --     -90%
baseline 5081/s    2747%    2661%    2023%     915%       --


perl etc\bench\bench.pl 500 10000 1
First few items in each list:
aadb aadn aadv aagi aaja aaje
aadb aadn aadv aagi aaja aaje
gntg gyxl rgqp mjgz ayfi abd
gyxl rgqp mjgz ayfi abd wtja
ok 1 - same order
ok 2 - same contents, list-u-det-order
ok 3 - same contents, hash ordered
1..3
           Rate      lbs      lmu      lho      ldd baseline
lbs      3.41/s       --      -1%     -83%     -91%     -99%
lmu      3.46/s       1%       --     -83%     -91%     -99%
lho      20.5/s     501%     493%       --     -48%     -94%
ldd      39.4/s    1053%    1038%      92%       --     -89%
baseline  360/s   10438%   10302%    1655%     814%       --


###  NEEDS UPDATING
perl etc\bench\bench.pl 50 50000 1
First few items in each list:
aa aaaa aaad aaal aaar aaat
aa aaaa aaad aaal aaar aaat
odqc ersz ozmd kccn zgpi umeo
ersz ozmd kccn zgpi umeo lhdw
ok 1 - same order
ok 2 - same contents, list-u-det-order
ok 3 - same contents, hash ordered
1..3
            Rate      lbs      lmu      lho      ldd baseline
lbs      0.131/s       --      -1%     -96%     -98%    -100%
lmu      0.133/s       1%       --     -96%     -98%    -100%
lho       3.56/s    2606%    2583%       --     -40%     -92%
ldd       5.96/s    4436%    4396%      68%       --     -87%
baseline  46.4/s   35207%   34895%    1205%     678%       --
