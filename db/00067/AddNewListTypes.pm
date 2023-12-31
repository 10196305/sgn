#!/usr/bin/env perl


=head1 NAME

 AddNewListTypes.pm

=head1 SYNOPSIS

mx-run AddNewListTypes [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This is a test dummy patch.
This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Bryan Ellerbrock <bje24@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package AddNewListTypes;

use Moose;
use Bio::Chado::Schema;
use Try::Tiny;
extends 'CXGN::Metadata::Dbpatch';


has '+description' => ( default => <<'' );
This patch will create new cvterms 'dataset', 'crosses', 'populations', and 'numeric' in the 'list_type' cv.


sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    print STDOUT "\nExecuting the SQL commands.\n";

    my $schema = Bio::Chado::Schema->connect( sub { $self->dbh->clone } );

    my $coderef = sub {

	my $dataset_list_type_cvterm = $schema->resultset("Cv::Cvterm")->create_with({
	    name => 'dataset',
      definition => 'dataset',
	    cv   => 'list_types',
	});

  my $crosses_list_type_cvterm = $schema->resultset("Cv::Cvterm")->create_with({
      name => 'crosses',
      definition => 'crosses',
      cv   => 'list_types',
  });

  my $populations_list_type_cvterm = $schema->resultset("Cv::Cvterm")->create_with({
      name => 'populations',
      definition => 'populations',
      cv   => 'list_types',
  });

  my $numbers_list_type_cvterm = $schema->resultset("Cv::Cvterm")->create_with({
      name => 'numbers',
      definition => 'numbers',
      cv   => 'list_types',
  });

    };

    try {
        $schema->txn_do($coderef);

    } catch {
        die "Load failed! " . $_ .  "\n" ;
    };

    print "You're done!\n";
}


####
1; #
####
