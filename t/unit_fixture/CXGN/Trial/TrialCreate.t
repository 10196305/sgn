
use strict;

use Test::More;
use lib 't/lib';
use SGN::Test::Fixture;
use JSON::Any;
use Data::Dumper;

my $fix = SGN::Test::Fixture->new();

is(ref($fix->config()), "HASH", 'hashref check');

BEGIN {use_ok('CXGN::Trial::TrialCreate');}
BEGIN {use_ok('CXGN::Trial::TrialLayout');}
BEGIN {use_ok('CXGN::Trial::TrialDesign');}
BEGIN {use_ok('CXGN::Trial::TrialLookup');}
ok(my $chado_schema = $fix->bcs_schema);
ok(my $phenome_schema = $fix->phenome_schema);
ok(my $dbh = $fix->dbh);

# create a location for the trial
ok(my $trial_location = "test_location_for_trial");
ok(my $location = $chado_schema->resultset('NaturalDiversity::NdGeolocation')
   ->new({
    description => $trial_location,
	 }));
ok($location->insert());

# create stocks for the trial
ok(my $accession_cvterm = $chado_schema->resultset("Cv::Cvterm")
   ->create_with({
       name   => 'accession',
       cv     => 'stock_type',
      
		 }));
my @stock_names;
for (my $i = 1; $i <= 10; $i++) {
    push(@stock_names, "test_stock_for_trial".$i);
}

#create stocks for genotyping trial
my @genotyping_stock_names;
for (my $i = 1; $i <= 10; $i++) {
    push(@genotyping_stock_names, "test_stock_for_genotyping_trial".$i);
}


ok(my $organism = $chado_schema->resultset("Organism::Organism")
   ->find_or_create( {
       genus => 'Test_genus',
       species => 'Test_genus test_species',
		     }, ));

# create some test stocks
foreach my $stock_name (@stock_names) {
    my $accession_stock = $chado_schema->resultset('Stock::Stock')
	->create({
	    organism_id => $organism->organism_id,
	    name       => $stock_name,
	    uniquename => $stock_name,
	    type_id     => $accession_cvterm->cvterm_id,
		 });
};

# create some genotyping test stocks
foreach my $stock_name (@genotyping_stock_names) {
    my $accession_stock = $chado_schema->resultset('Stock::Stock')
	->create({
	    organism_id => $organism->organism_id,
	    name       => $stock_name,
	    uniquename => $stock_name,
	    type_id     => $accession_cvterm->cvterm_id,
		 });
};


ok(my $trial_design = CXGN::Trial::TrialDesign->new(), "create trial design object");
ok($trial_design->set_trial_name("test_trial"), "set trial name");
ok($trial_design->set_stock_list(\@stock_names), "set stock list");
ok($trial_design->set_plot_start_number(1), "set plot start number");
ok($trial_design->set_plot_number_increment(1), "set plot increment");
ok($trial_design->set_number_of_blocks(2), "set block number");
ok($trial_design->set_design_type("RCBD"), "set design type");
ok($trial_design->calculate_design(), "calculate design");
ok(my $design = $trial_design->get_design(), "retrieve design");

ok(my $trial_create = CXGN::Trial::TrialCreate->new({
    chado_schema => $chado_schema,
    dbh => $dbh,
    user_name => "johndoe", #not implemented
    design => $design,	
    program => "test",
    trial_year => "2015",
    trial_description => "test description",
    trial_location => "test_location_for_trial",
    trial_name => "new_test_trial_name",
    design_type => "RCBD",
						    }), "create trial object");
ok($trial_create->save_trial(), "save trial");

ok(my $trial_lookup = CXGN::Trial::TrialLookup->new({
    schema => $chado_schema,
    trial_name => "new_test_trial_name",
						    }), "create trial lookup object");
ok(my $trial = $trial_lookup->get_trial());
ok(my $trial_id = $trial->project_id());
ok(my $trial_layout = CXGN::Trial::TrialLayout->new({
    schema => $chado_schema,
    trial_id => $trial_id,

						    }), "create trial layout object");

ok(my $accession_names = $trial_layout->get_accession_names(), "retrieve accession names1");

my %stocks = map { $_ => 1 } @stock_names;

foreach my $acc (@$accession_names) {
    ok(exists($stocks{$acc->{accession_name}}), "check accession names $acc->{accession_name}");
}



#create RCBD trial with one accession

@stock_names;
push @stock_names, "test_stock_for_trial1";

ok(my $trial_design = CXGN::Trial::TrialDesign->new(), "create trial design object");
ok($trial_design->set_trial_name("new_test_trial_name_single"), "set trial name");
ok($trial_design->set_stock_list(\@stock_names), "set stock list");
ok($trial_design->set_plot_start_number(1), "set plot start number");
ok($trial_design->set_plot_number_increment(1), "set plot increment");
ok($trial_design->set_number_of_reps(2), "set rep number");
ok($trial_design->set_design_type("CRD"), "set design type");
ok($trial_design->calculate_design(), "calculate design");
ok(my $design = $trial_design->get_design(), "retrieve design");

ok(my $trial_create = CXGN::Trial::TrialCreate->new({
    chado_schema => $chado_schema,
    dbh => $dbh,
    user_name => "johndoe", #not implemented
    design => $design,	
    program => "test",
    trial_year => "2015",
    trial_description => "test description",
    trial_location => "test_location_for_trial",
    trial_name => "new_test_trial_name_single",
    design_type => "RCBD",
						    }), "create trial object");
ok($trial_create->save_trial(), "save trial");

ok(my $trial_lookup = CXGN::Trial::TrialLookup->new({
    schema => $chado_schema,
    trial_name => "new_test_trial_name_single",
						    }), "create trial lookup object");
ok(my $trial = $trial_lookup->get_trial());
ok(my $trial_id = $trial->project_id());
ok(my $trial_layout = CXGN::Trial::TrialLayout->new({
    schema => $chado_schema,
    trial_id => $trial_id,

						    }), "create trial layout object");

ok(my $accession_names = $trial_layout->get_accession_names(), "retrieve accession names2");

my %stocks = map { $_ => 1 } @stock_names;

foreach my $acc (@$accession_names) {
    ok(exists($stocks{$acc->{accession_name}}), "check accession names $acc->{accession_name}");
}


# layout for genotyping experiment
# use data structure returned by brapi call for GDF:
# plates:[ { 'project_id' : 'project x', 
#            'plate_name' : 'required',
#            'plate_format': 'Plate_96' | 'tubes',
#            'sample_type' : 'DNA' | 'RNA' | 'Tissue'
#            'samples':[
# {
#    		'name': 'sample_name1', 
#     		'well': 'optional'
#               'concentration:
#'              'volume': 
#               'taxomony_id' : 
#               'tissue_type' : 
#               }
# ] 

my $plates = [ { 'project_id' => 'test',
		 'plate_name' => 'test_plate',
		 'plate_format' => 'Plate_96',
		 'sample_type' => 'DNA',
		 'samples' => 
		     [ 
		       {
			   'name' => 'test_accession1',
			   'well' => 'A1',
			   'concentration' => 1,
			   'volume' => 2,
			   'taxonomy_id' => 4226,
			   'tissue_type' => 'leaf',
		       },
		       {
			   'name' => 'test_accession2',
			   'well' => 'A2',
			   'concentration' => 1,
			   'volume' =>  2,
			   'taxonomy_id' => 4226,
			   'tissue_type' => 'leaf',
		       },
		       {
			   'name' => 'test_accession3',
			   'well' => 'A3',
			   'concentration' => 1,
			   'volume' => 2,
			   'taxonomy_id' => 4226,
			   'tissue_type' =>  'leaf',
		       },
		       {
			   'name' => 'test_accession4',
			   'well' => 'B1',
			   'concentration' => 1,
			   'volume' => 2,
			   'taxonomy_id' => 4226,
			   'tissue_type' => 'leaf',
		       },
		       {
			   'name' => 'BLANK',
			   'well' => 'B2',
			   'concentration' => 0,
			   'volume' => 0,
			   'taxonomy_id' => 0,
			   'tissue_type' => 'unknown',
			       }
		     ],
	       },
    ];
	       
my @stock_list = map { $_->{name} } @{$plates->[0]->{samples}};

my $design = CXGN::Trial::TrialDesign->new( { schema => $chado_schema } );
#$design->trial_name($plates->[0]->{plate_name});
#$design->stock_list(@stock_list);
#$design->number_of_rows = 8;
#$design->number_of_columns = 12;

$design->set_plate(JSON::Any->encode($plates->[0]));
$design->set_design_type("genotyping_plate");
$design->calculate_design();
my $geno_design = $design->get_design();

ok(my $genotyping_trial_create = CXGN::Trial::TrialCreate->new({
    chado_schema => $chado_schema,
    dbh => $dbh,
    is_genotyping => 1,
    user_name => "johndoe", #not implemented
    design => $geno_design,	
    program => "test",
    trial_year => "2015",
    trial_description => "test description",
    trial_location => "test_location_for_trial",
    trial_name => "test_genotyping_trial_name",
    design_type => "genotyping_plate",
							       }), "create genotyping trial");

ok($genotyping_trial_create->save_trial(), "save genotyping trial");

ok(my $genotyping_trial_lookup = CXGN::Trial::TrialLookup->new({
    schema => $chado_schema,
    trial_name => "test_genotyping_trial_name",
						    }), "lookup genotyping trial");
ok(my $genotyping_trial = $genotyping_trial_lookup->get_trial(), "retrieve genotyping trial");
ok(my $genotyping_trial_id = $genotyping_trial->project_id(), "retrive genotyping trial id");
ok(my $genotyping_trial_layout = CXGN::Trial::TrialLayout->new({
    schema => $chado_schema,
    trial_id => $genotyping_trial_id,

						    }), "create trial layout object for genotyping trial");
ok(my $genotyping_accession_names = $genotyping_trial_layout->get_accession_names(), "retrieve accession names3");
my %genotyping_stocks = map { $_ => 1 } @genotyping_stock_names;
foreach my $acc (@$genotyping_accession_names) { 
    ok(exists($genotyping_stocks{$acc->{accession_name}}), "check existence of accession names $acc->{accession_name}");
}

done_testing();
