#!/usr/bin/env perl


=head1 NAME

 AddVectorStockType.pm

=head1 SYNOPSIS

mx-run AddVectorStockType [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This is a test dummy patch.
This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Nicolas Morales <nm529@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package AddVectorStockType;

use Moose;
use Bio::Chado::Schema;
use Try::Tiny;
extends 'CXGN::Metadata::Dbpatch';


has '+description' => ( default => <<'' );
This patch will find_or_create a cvterm name of vector, which is a new stock type

has '+prereq' => (
    default => sub {
        [],
    },
  );

sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    print STDOUT "\nExecuting the SQL commands.\n";

    my $schema = Bio::Chado::Schema->connect( sub { $self->dbh->clone } );

    my $coderef = sub {

	my $vector_stock_cvterm = $schema->resultset("Cv::Cvterm")->create_with({
	    name => 'vector_construct',
	    cv   => 'stock_type',
	});
	my $vector_stockprop_transgenic_cvterm = $schema->resultset("Cv::Cvterm")->create_with({
	    name => 'transgenic',
	    cv   => 'stock_property',
	});
	my $vector_stockprop_t1_cvterm = $schema->resultset("Cv::Cvterm")->create_with({
	    name => 'T1',
	    cv   => 'stock_property',
	});
	my $vector_stockprop_t2_cvterm = $schema->resultset("Cv::Cvterm")->create_with({
	    name => 'T2',
	    cv   => 'stock_property',
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
