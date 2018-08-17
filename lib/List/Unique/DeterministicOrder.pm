package List::Unique::DeterministicOrder;

use 5.010;
use Carp;
use strict;
use warnings;
use List::Util qw /uniq/;

our $VERSION = 0.001;

no autovivification;

sub new {
    my ($package, %args) = @_;

    my $self = {
        hash  => {},
        array => [],
    };
    
    #  use data if we were passed some
    if (my $data = $args{data}) {
        my %hash;
        @hash{@$data} = (0..$#$data);
        #  rebuild the lists if there were dups
        if (scalar keys %hash != scalar @$data) {
            my @uniq = uniq @$data;
            @hash{@uniq} = (0..$#uniq);
            $self->{array} = \@uniq;
        }
        else {
            $self->{array} = [@$data];
        }
        $self->{hash} = \%hash;
    }
    
    return bless $self, $package;
}

sub exists {
    my ($self, $key) = @_;
    return exists $self->{hash}{$key};
}

sub keys {
    my ($self) = @_;
    return wantarray
      ? @{$self->{array}}
      : scalar @{$self->{array}};
}

sub push {
    my ($self, $key) = @_;

    return if exists $self->{hash}{$key};
    
    push @{$self->{array}}, $key;
    $self->{hash}{$key} = $#{$self->{array}};
}

sub pop {
    my ($self) = @_;
    my $key = pop @{$self->{array}};
    delete $self->{hash}{$key};
    return $key;
}

#  returns undef if key not in hash
sub get_key_pos {
    my ($self, $key) = @_;
    return $self->{hash}{$key};
}


#  returns undef if index is out of bounds
sub get_key_at_pos {
    my ($self, $pos) = @_;
    return $self->{array}[$pos];
}

#  does nothing if key does not exist
sub delete {
    my ($self, $key) = @_;
    
    #  get the index while cleaning up
    my $pos = CORE::delete $self->{hash}{$key}
      // return;
    
    my $move_key = CORE::pop @{$self->{array}};
    #  make sure we don't just reinsert the last item
    #  from a single item list
    if ($move_key ne $key) {
        $self->{hash}{$move_key} = $pos;
        $self->{array}[$pos] = $move_key;
    }
    
    return $key;
}

#  Delete the key at the specified position
#  and move the last key into it.
#  Not a true splice, but one day might work
#  on multiple indices.
sub splice {
    my ($self, $pos) = @_;
    
    my $key = $self->{array}[$pos]
      // return;
    
    my $move_key = CORE::pop @{$self->{array}};
    $self->{hash}{$move_key} = $pos;
    $self->{array}[$pos] = $move_key;
    CORE::delete $self->{hash}{$key};
    return $key;
}


sub _paranoia {
    my ($self) = @_;
    
    my $array_len = @{$self->{array}};
    my $hash_len  = CORE::keys %{$self->{hash}};
    croak "array and hash key mismatch" if $array_len != $hash_len;
    
    foreach my $key (@{$self->{array}}) {
        croak "Key mismatch between array and hash lists"
          if !CORE::exists $self->{hash}{$key}; 
    }
    
    return 1;
}

1;

=head1 NAME

List::Unique::DeterministicOrder - Store keys with deterministic order based on insertions and deletions

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

This module provides a structure to store a set
of keys, without duplicates, and be able to access
them by either key name or index.

The algorithm used inserts keys at the end, but
swaps keys around on deletion.  Hence it is
deterministic and repeatable, but only if the
sequence of insertion and deletions is replicated
exactly.  

The algorithm used is from
L<https://stackoverflow.com/questions/5682218/data-structure-insert-remove-contains-get-random-element-all-at-o1/5684892#5684892>

So why would one use this in the first place?
The motivating use case was to track keys
under a random selection procedure 
where keys are extracted from a pool of keys,
and sometimes inserted.  e.g. the process might
select and remove the 10th key, then the 257th,
then insert a new key, followed by more selections
and removals.  The randomisations needed to 
produce the same results same for the same given
PRNG sequence for reproducibility purposes.
Using a hash to store the data provides rapid access,
but getting the nth key requires the key list be generated,
and Perl's hashes do not provide their keys in a deterministic
order across all versions and platforms.  
Binary searches over sorted lists proved very
effective for a while, but bottlenecks started
to manifest when the data sets became
much larger and the number of lists
became both abundant and lengthy.
Since the order itself does not matter,
only the ability to replicate it, this module was written.


    use List::Unique::DeterministicOrder;

    my $foo = List::Unique::DeterministicOrder->new(
        data => [qw /foo bar quux fetangle/]
    );
    
    print $foo->keys;
    #  foo bar quux fetangle
    
    $foo->delete ('bar')
    print $foo->keys;
    #  foo fetangle quux 
    
    print $foo->get_key_at_pos(2);
    #  quux
    print $foo->get_key_at_pos(20);
    #  undef
    
    $foo->push ('bardungle')
    print $foo->keys;
    #  foo fetangle quux bardungle

    #  duplicates are stored only once,
    #  just like with a normal hash
    $foo->push ('fetangle')
    print $foo->keys;
    #  foo fetangle quux bardungle
    
    print $foo->exists ('gelert');
    #  false
    
    print $foo->pop;
    #  bardungle
    

=head1 METHODS

Note that most methods take a single argument
(if any), so while the method names look
hash-like, this is essentially cosmetic.

=head2 new

Create a new object.
Optionally pass data using the data
keyword.  Duplicate keys are
stored once only.

    $foo->new();

    $foo->new(data => [/a b c d e/]);

=cut

=head2 delete

Deletes the key passed as an argument.

=cut

=head2 exists

True or false for if the key exists.

=cut

=head2 get_key_at_pos

Returns the key at some position.

    $foo->get_key_at_pos(5);

=cut

=head2 get_key_pos

Returns the position of a key.

    $foo->get_key_pos('quux');

=cut

=head2 keys

Returns the list of keys in list context,
and the number of keys in scalar context.

=cut

=head2 pop

Removes and returns the last key in the list.

=cut

=head2 push

Appends the specified key to the end of the list,
unless it is already in the set.

=cut

=head2 splice

Removes a single key from the set at the specified position.

    $foo->splice(1);

=cut


=head1 AUTHOR

Shawn Laffan, C<< <shawnlaffan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-deterministic-access at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=List-Unique-DeterministicOrder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::Unique::DeterministicOrder


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=List-Unique-DeterministicOrder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/List-Unique-DeterministicOrder>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/List-Unique-DeterministicOrder>

=item * Search CPAN

L<https://metacpan.org/release/List-Unique-DeterministicOrder>

=back


=head1 ACKNOWLEDGEMENTS

The algorithm used is from
L<https://stackoverflow.com/questions/5682218/data-structure-insert-remove-contains-get-random-element-all-at-o1/5684892#5684892>

=head1 SEE ALSO

L<Hash::Ordered>

L<List::BinarySearch>

L<List::MoreUtils>


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Shawn Laffan 

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

