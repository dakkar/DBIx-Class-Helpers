package DBIx::Class::Helper::ResultSet::Random;

use strict;
use warnings;

use parent 'DBIx::Class::Helper::ResultSet::Union';

# ABSTRACT: Get random rows from a ResultSet

# this is ghetto
my %rand_order_by = (
   'DBIx::Class::Storage::DBI::SQLite'                     => 'RANDOM()',
   'DBIx::Class::Storage::DBI::mysql'                      => 'RANDOM()',
   'DBIx::Class::Storage::DBI::ODBC::Microsoft_SQL_Server' => 'RAND()',
   'DBIx::Class::Storage::DBI::MSSQL'                      => 'RAND()',
   'DBIx::Class::Storage::DBI::Pg'                         => 'RAND()',
   'DBIx::Class::Storage::DBI::Oracle'                     => 'dbms_random.value',
);

sub rand_order_by {
   return $rand_order_by{ref shift->result_source->storage} || 'RANDOM()';
}

sub rand {
   my $self   = shift;
   my $amount = shift || 1;

   $self->throw_exception('rand can only return a positive amount of rows')
      unless $amount > 0;

   $self->throw_exception('rand can only return an integer amount of rows')
      unless $amount == int $amount;

   my $order_by = $self->rand_order_by;

   return $self->search(undef, { rows=> $amount, order_by => \$order_by});
}

1;

=pod

=head1 SYNOPSIS

 # note that this is normally a component for a ResultSet
 package MySchema::ResultSet::Bar;

 use strict;
 use warnings;

 use parent 'DBIx::Class::ResultSet';

 __PACKAGE__->load_components('Helper::Random');

 # in code using resultset:
 my $random_row  = $schema->resultset('Bar')->rand->single;

=head1 DESCRIPTION

This component allows convenient selection of random rows.

=head1 METHODS

=head2 rand

This method takes a single argument, being the size of the random ResultSet
to return.  It defaults to 1.  This Component will throw exceptions if the
argument is not an integer or not greater than zero.

=head2 rand_order_by

This module currently does an C<ORDER BY> on some db specific function.  If for
some reason it guesses incorrectly for your database the easiest way to fix
that in the short-term (ie without patching upstream) is to override this
method.  So for example, if your db uses C<RAND()> instead of C<RANDOM()> and
it's not in the predefined list of dbs you could just do the following in your
ResultSet class:

 sub rand_order_by { 'RAND()' }
