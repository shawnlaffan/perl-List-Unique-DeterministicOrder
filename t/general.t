use 5.010;
use rlib;

use Test::More;
use Data::Deterministic::Access;


my $obj = Data::Deterministic::Access->new;

my @keys = qw /a z b y c x/;
foreach my $key (@keys) {
    $obj->push ($key);
}

foreach my $key (@keys) {
    ok ($obj->exists ($key), "Contains $key"); 
}
foreach my $key (qw /d e f g/) {
    ok (!$obj->exists ($key), "Does not contain $key"); 
}

my $key_count = $obj->keys;
is ($key_count, 6, "Got correct key count");

my @got_keys = $obj->keys;
is_deeply \@got_keys, \@keys, 'Got expected key order';

eval {$obj->_paranoia};
my $e = $@;
ok !$e, 'no errors from paranoia check';

my $last_key = pop @keys;
my $popper = $obj->pop;
is $popper, $last_key, "Popped $last_key";

for my $i (0 .. $#keys) {
    is $obj->get_key_at_pos($i), $keys[$i], "got correct key at pos $i";
}

$key_count = $obj->keys;
is ($key_count, 5, "Got correct key count after pop");

#  now we delete some keys by index
my $deletion = $obj->splice (1);
is $deletion, $keys[1], "key deletion of position returned $keys[1]";
ok (!$obj->exists ($keys[1]), "no $keys[1] in the hash");
$key_count = $obj->keys;
is ($key_count, 4, "Got correct key count after delete_key_at_pos");

eval {$obj->_paranoia};
note $@ if $@;

#  update @keys
splice @keys, 1;

#  now delete by name
$deletion = $obj->delete ('c');
is $deletion, 'c', "got deleted key c";
$key_count = $obj->keys;
is ($key_count, 3, "Got correct key count after delete");
ok (!$obj->exists ('c'), 'no c in the hash');

note "Keys are now " . join ' ', $obj->keys;


done_testing();
