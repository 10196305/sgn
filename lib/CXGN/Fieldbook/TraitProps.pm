package CXGN::Fieldbook::TraitProps;

=head1 NAME

CXGN::Fieldbook::TraitProps - a module to store trait properties in the database.

=head1 USAGE

 my $trait_props = CXGN::Fieldbook::TraitProps->new({ chado_schema => $chado_schema, db_name => $db_name, trait_names_and_props => \@trait_props_data, overwrite => 1, });
 my $validate = $trait_props->validate();  #returns true if the trait props are valid and can be stored and returns false otherwise.
 my $store = $trait_props->store();  #returns true if the trait props are stored and returns false otherwise.

=head1 DESCRIPTION

Stores trait properties in the database to build trait files to use in Fieldbook data collection

=head1 AUTHORS

 Jeremy D. Edwards (jde22@cornell.edu)

=cut

use Moose;
use MooseX::FollowPBP;
use Moose::Util::TypeConstraints;
use Try::Tiny;

has 'chado_schema' => (
		 is       => 'ro',
		 isa      => 'DBIx::Class::Schema',
		 required => 1,
		);
has 'db_name' => (
		  is => 'ro',
		  isa => 'Str',
		  required => 1,
		 );
has 'trait_names_and_props' => (
		  is => 'ro',
		  isa => 'ArrayRef[HashRef[Str]]',
		  required => 1,
		 );
has 'overwrite' => (
		    is => 'ro',
		    isa => 'Str',
		    required => 0,
		   );


sub _get_cvterms {
  my $self = shift;
  my $chado_schema = $self->get_chado_schema();
  my %cvterms;

  my @trait_property_names = qw(
			     trait_format
			     trait_default_value
			     trait_minimum
			     trait_maximum
			     trait_details
			     trait_categories
			  );

  my $cv = $chado_schema->resultset("Cv::Cv")
    ->find_or_create({
		   name => 'trait_property',
		  });
  $cv->insert;

  print STDERR "CV: ".$cv->cv_id()."\n";

  #$cvterms{'cv'}=$cv;

  foreach my $property_name (@trait_property_names) {

    $cvterms{$property_name} = $chado_schema->resultset("Cv::Cvterm")
      ->create_with({
		     name   => $property_name,
		     cv     => 'trait_property',
		     db     => 'null',
		     dbxref => $property_name,
		    });

    print STDERR "prop: $property_name\n";

  }

  return \%cvterms;

}


sub validate {
  my $self = shift;
  my $chado_schema = $self->get_chado_schema();

  my $db_rs = $chado_schema->resultset("General::Db")->search( { 'me.name' => $self->get_db_name() });

  if (!$db_rs) {
    print STDERR "Could not find trait ontology database: ".$self->get_db_name()."\n";
    return;
  }

  my $cvterms = $self->_get_cvterms();

  my @trait_props_data = @{$self->get_trait_names_and_props()};

  if (scalar @trait_props_data == 0) {
    print STDERR "No trait props supplied\n";
    return;
  }


  foreach my $trait_props (@trait_props_data) {
    if (!$trait_props->{'trait_name'}) {
      print STDERR "Bad data structure for trait properties:  no trait_name\n";
      return;
    }
    my $trait_name = $trait_props->{'trait_name'};

    #make sure that the trait name is valid
    my $trait_cvterm;
    $trait_cvterm = $chado_schema->resultset("Cv::Cvterm")
      ->find( {
	       'dbxref.db_id' => $db_rs->first()->db_id(),
	       'name'=> $trait_name,
	      },
	      {
	       'join' => 'dbxref'
	      }
	    );
    if (!$trait_cvterm) {
      print STDERR "Could not find trait $trait_name\n";
      return;
    }

    #make sure that the trait prop names are valid
    foreach my $prop_name (keys %{$trait_props}) {
      if ($prop_name ne 'trait_name') {
	if (!$cvterms->{$prop_name}) {
	  print STDERR "Bad data structure for trait properties: $prop_name is not valid";
	  return;
	}

	my $prop_cvterm = $cvterms->{$prop_name};

	#check for an existing prop of the same name
	  my $cvtermprop_search = $trait_cvterm
	    ->search_related('cvtermprops', {
					     'cvterm_id' => $prop_cvterm->cvterm_id(),
					    }
			    );

	  if ($cvtermprop_search->count() > 1) {
	    print STDERR "More than one cvtermprop for trait $trait_name with property $prop_name\n";
	    return;
	  }

	if ($cvtermprop_search->count() == 1) {
	  if (!$self->get_overwrite()) {
	    print STDERR "A cvtermprop for trait $trait_name with property $prop_name already exists\n";
	    return;
	  }
	}
      }
    }


  }

  return 1;

}

sub store {
  my $self = shift;
  my $chado_schema = $self->get_chado_schema();

  my $db_rs = $chado_schema->resultset("General::Db")->search( { 'me.name' => $self->get_db_name() });

  if (!$db_rs) {
    print STDERR "Could not find trait ontology database: ".$self->get_db_name()."\n";
    return;
  }

  my $cvterms = $self->_get_cvterms();

  my @trait_props_data = @{$self->get_trait_names_and_props()};

  my $coderef = sub {

    foreach my $trait_props (@trait_props_data) {

      my $trait_name = $trait_props->{'trait_name'};

      #get the cvterm for the trait
      my $trait_cvterm = $chado_schema->resultset("Cv::Cvterm")
	->find( {
		 'dbxref.db_id' => $db_rs->first()->db_id(),
		 'name'=> $trait_name,
		},
		{
		 'join' => 'dbxref'
		}
	      );

      foreach my $prop_name (keys %{$trait_props}) {
	if ($prop_name ne 'trait_name') {

	  my $prop_cvterm = $cvterms->{$prop_name};

	  my $trait_prop_value = $trait_props->{$prop_name};

	  #check for an existing prop of the same name
	  my $cvtermprop_search = $trait_cvterm
	    ->search_related('cvtermprops', {
					     'cvterm_id' => $prop_cvterm->cvterm_id(),
					    }
			    );

	  if ($cvtermprop_search->count() > 1) {
	    die("More that one cvtermprop for trait $trait_name with property $prop_name\n");
	  }

	  #if the trait property already exists, update it overwrite is true or die if false
	  if ($cvtermprop_search->count() == 1) {
	    if ($self->get_overwrite()) {
	      my $found_cvtermprop = $cvtermprop_search->first();
	      $found_cvtermprop->update({value => $trait_prop_value});
	    } else {
	      die("A trait with property $prop_name already exists\n");
	    }
	  } else {
	    #create a new trait property
	    # $trait_cvterm
	    #   ->find_or_create_related('cvtermprops',{
	    # 					      'cvterm_id' => $prop_cvterm->cvterm_id(),
	    # 					      'value' => $trait_prop_value,
	    # 					      'type_id' => $cvterms->{'cv'}->cv_id(),
	    # 					     }
	    # 			       );
	    $trait_cvterm
	      ->find_or_create_related('cvtermprops',{
						      'value' => $trait_prop_value,
						      'type_id' => $prop_cvterm->cvterm_id(),
						     }
				       );

	  }
	}
      }
    }
  };

  my $transaction_error;

  try {
    $chado_schema->txn_do($coderef);
  } catch {
    $transaction_error =  $_;
  };

  if ($transaction_error) {
    print STDERR "Transaction error storing trait props: $transaction_error\n";
    return;
  }

  return 1;

}

#######
1;
#######
