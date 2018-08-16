package Data::Deterministic::Access;

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