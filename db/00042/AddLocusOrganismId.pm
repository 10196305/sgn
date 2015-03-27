#!/usr/bin/env perl


=head1 NAME

 AddLocusOrganismId.pm

=head1 SYNOPSIS

mx-run AddLocusOrganismId [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This patch adds organism_id field to phenome.locus referencing public.organism
This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

  Naama Menda <nm249@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package AddLocusOrganismId;

use Moose;
extends 'CXGN::Metadata::Dbpatch';


has '+description' => ( default => <<'' );
Add locus.organism_id field

has '+prereq' => (
    default => sub {
        [ ],
    },
  );

sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    print STDOUT "\nExecuting the SQL commands.\n";

    $self->dbh->do(<<EOSQL);
--do your SQL here
--


ALTER TABLE locus ADD COLUMN organism_id INTEGER REFERENCES public.organism;


EOSQL

}

print "Done!\n";


####
1; #
####
