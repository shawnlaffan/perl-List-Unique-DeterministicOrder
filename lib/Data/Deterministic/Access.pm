package Data::Deterministic::Access;

use 5.010;
use Carp;
use strict;
use warnings;

our $VERSION = 0.001;

no autovivification;

sub new {
    my $package = shift;

    my $self = {
        order_hash => {},
        key_array  => [],
    };
    return bless $self, $package;
}

sub exists {
    my ($self, $key) = @_;
    return exists $self->{order_hash}{$key};
}

sub keys {
    my ($self) = @_;
    return wantarray ? @{$self->{key_array}} : scalar @{$self->{key_array}};
}

sub push {
    my ($self, $key) = @_;

    return if exists $self->{order_hash}{$key};
    
    push @{$self->{key_array}}, $key;
    $self->{order_hash}{$key} = $#{$self->{key_array}};
}

sub pop {
    my ($self) = @_;
    my $key = pop @{$self->{key_array}};
    delete $self->{order_hash}{$key};
    return $key;
}

#  returns undef if index is out of bounds
sub get_key_at_pos {
    my ($self, $pos) = @_;
    return $self->{key_array}[$pos];
}

#  does nothing if key does not exist
sub delete {
    my ($self, $key) = @_;
    
    #  get the index while cleaning up
    my $pos = CORE::delete $self->{order_hash}{$key}
      // return;
    
    my $move_key = CORE::pop @{$self->{key_array}};
    $self->{order_hash}{$move_key} = $pos;
    $self->{key_array}[$pos] = $move_key;
    
    return $key;
}

#  delete the key at the specified position
#  and move the last key into it
sub splice {
    my ($self, $pos) = @_;
    
    my $key = $self->{key_array}[$pos]
      // return;
    
    my $move_key = CORE::pop @{$self->{key_array}};
    $self->{order_hash}{$move_key} = $pos;
    $self->{key_array}[$pos] = $move_key;
    CORE::delete $self->{order_hash}{$key};
    return $key;
}


sub _paranoia {
    my ($self) = @_;
    
    my $array_len = @{$self->{key_array}};
    my $hash_len  = CORE::keys %{$self->{order_hash}};
    croak "array and hash key mismatch" if $array_len != $hash_len;
    
    foreach my $key (@{$self->{key_array}}) {
        croak "Key mismatch between array and hash lists"
          if !CORE::exists $self->{order_hash}{$key}; 
    }
    
    return 1;
}