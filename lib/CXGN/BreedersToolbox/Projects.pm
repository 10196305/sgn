
package CXGN::BreedersToolbox::Projects;

use Moose;
use Data::Dumper;
use SGN::Model::Cvterm;
use CXGN::People::Roles;
use JSON;
use Encode;
use CXGN::BrAPI::v2::ExternalReferences;
use Try::Tiny;

has 'schema' => (
		 is       => 'rw',
		 isa      => 'DBIx::Class::Schema',
		);


sub trial_exists {
    my $self = shift;
    my $trial_id = shift;

    my $rs = $self->schema->resultset('Project::Project')->search( { project_id => $trial_id });

    if ($rs->count() == 0) {
	return 0;
    }
    return 1;
}

sub get_breeding_programs {
    my $self = shift;


    my $breeding_program_cvterm_id = $self->get_breeding_program_cvterm_id();

    my $rs = $self->schema->resultset('Project::Project')->search( { 'projectprops.type_id'=>$breeding_program_cvterm_id }, { join => 'projectprops' }  );

    my @projects;
    while (my $row = $rs->next()) {

        my @project_array = ($row->project_id);
        my $references = CXGN::BrAPI::v2::ExternalReferences->new({
            bcs_schema => $self->schema,
            table_name => 'project',
            table_id_key => 'project_id',
            id => \@project_array
        });
        my $external_references = $references->search();
        my @external_references_array;
        foreach my $values (values %{$external_references}) {
            push @external_references_array, $values;
        }

	    push @projects, [ $row->project_id, $row->name, $row->description, @external_references_array ];
    }

    return \@projects;
}

# deprecated. Use CXGN::Trial->get_breeding_program instead.
sub get_breeding_programs_by_trial {
    my $self = shift;
    my $trial_id = shift;

    my $breeding_program_cvterm_id = $self->get_breeding_program_cvterm_id();
    my $breeding_program_rel_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($self->schema, 'breeding_program_trial_relationship', 'project_relationship')->cvterm_id();

    my $trial_rs= $self->schema->resultset('Project::ProjectRelationship')->search({
        'subject_project_id' => $trial_id,
        'type_id' => $breeding_program_rel_cvterm_id
    });

    my $trial_row = $trial_rs -> first();
    my $rs;
    my @projects;

    if ($trial_row) {
	$rs = $self->schema->resultset('Project::Project')->search( { 'me.project_id' => $trial_row->object_project_id(), 'projectprops.type_id'=>$breeding_program_cvterm_id }, { join => 'projectprops' }  );

	while (my $row = $rs->next()) {
	    push @projects, [ $row->project_id, $row->name, $row->description ];
	}
    }
    return  \@projects;
}



sub get_breeding_program_by_name {
  my $self = shift;
  my $program_name = shift;
  my $breeding_program_cvterm_id = $self->get_breeding_program_cvterm_id();

  my $prs = $self->schema->resultset('Project::Project')->search( { 'name'=>$program_name, 'projectprops.type_id'=>$breeding_program_cvterm_id }, { join => 'projectprops' }  );
  my $rs = $prs->first;

  if (!$rs) {
    return;
  }
  print STDERR "**Projects.pm: found program_name $program_name id = " . $rs->project_id . "\n\n";

  return $rs;

}

sub _get_all_trials_by_breeding_program {
    my $self = shift;
    my $breeding_project_id = shift;
    my $dbh = $self->schema->storage->dbh();
    my $breeding_program_cvterm_id = $self->get_breeding_program_cvterm_id();

    my $trials = [];
    my $h;
    if ($breeding_project_id) {
	# need to convert to dbix class.... good luck!
	#my $q = "SELECT trial.project_id, trial.name, trial.description FROM project LEFT join project_relationship ON (project.project_id=object_project_id) LEFT JOIN project as trial ON (subject_project_id=trial.project_id) LEFT JOIN projectprop ON (trial.project_id=projectprop.project_id) WHERE (project.project_id=? AND (projectprop.type_id IS NULL OR projectprop.type_id != ?))";
	my $q = "SELECT trial.project_id, trial.name, trial.description, projectprop.type_id, projectprop.value FROM project LEFT join project_relationship ON (project.project_id=object_project_id) LEFT JOIN project as trial ON (subject_project_id=trial.project_id) LEFT JOIN projectprop ON (trial.project_id=projectprop.project_id) WHERE (project.project_id = ?)";

	$h = $dbh->prepare($q);
	#$h->execute($breeding_project_id, $cross_cvterm_id);
	$h->execute($breeding_project_id);

    }
    else {
	# get trials that are not associated with any project
	my $q = "SELECT project.project_id, project.name, project.description , projectprop.type_id, projectprop.value FROM project JOIN projectprop USING(project_id) LEFT JOIN project_relationship ON (subject_project_id=project.project_id) WHERE project_relationship_id IS NULL and projectprop.type_id != ?";
	$h = $dbh->prepare($q);
	$h->execute($breeding_program_cvterm_id);
    }

    return $h;
}

sub get_trials_by_breeding_program {
    my $self = shift;
    my $breeding_project_id = shift;

    my $field_trials;
    my $cross_trials;
    my $genotyping_trials;
    my $genotyping_data_projects;
    my $field_management_factor_projects;
    my $drone_run_projects;
    my $drone_run_band_projects;
    my $analyses_projects;
    my $sampling_trial_projects;

    my $h = $self->_get_all_trials_by_breeding_program($breeding_project_id);
    my $crossing_trial_cvterm_id = $self->get_crossing_trial_cvterm_id();
    my $project_year_cvterm_id = $self->get_project_year_cvterm_id();
    my $analysis_metadata_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($self->schema(), 'analysis_metadata_json', 'project_property')->cvterm_id();

    my %projects_that_are_crosses;
    my %project_year;
    my %project_name;
    my %project_description;
    my %projects_that_are_genotyping_trials;
    my %projects_that_are_treatment_trials; #Field Management Factors
    my %projects_that_are_genotyping_data_projects;
    my %projects_that_are_drone_run_projects;
    my %projects_that_are_drone_run_band_projects;
    my %projects_that_are_analyses;
    my %projects_that_are_sampling_trials;

    while (my ($id, $name, $desc, $prop, $propvalue) = $h->fetchrow_array()) {
        #print STDERR "PROP: $prop, $propvalue \n";
        #push @$trials, [ $id, $name, $desc ];
        if ($name) {
            $project_name{$id} = $name;
        }
        if ($desc) {
            $project_description{$id} = $desc;
        }
        if ($prop) {
            if ($prop == $crossing_trial_cvterm_id) {
                $projects_that_are_crosses{$id} = 1;
                $project_year{$id} = '';
            }
            if ($prop == $project_year_cvterm_id && $propvalue) {
                $project_year{$id} = $propvalue;
            }
            if ($prop == $analysis_metadata_cvterm_id) {
                $projects_that_are_analyses{$id} = 1;
            }
            if ($propvalue) {
                if ($propvalue eq "genotyping_plate") {
                    $projects_that_are_genotyping_trials{$id} = 1;
                }
                if ($propvalue eq "sampling_trial") {
                    $projects_that_are_sampling_trials{$id} = 1;
                }
                if ($propvalue eq "treatment") {
                    $projects_that_are_treatment_trials{$id} = 1;
                }
                if (($propvalue eq "genotype_data_project") || ($propvalue eq "pcr_genotype_data_project")) {
                    $projects_that_are_genotyping_data_projects{$id} = 1;
                }
                if ($propvalue eq "drone_run") {
                    $projects_that_are_drone_run_projects{$id} = 1;
                }
                if ($propvalue eq "drone_run_band") {
                    $projects_that_are_drone_run_band_projects{$id} = 1;
                }
            }
        }
    }

    my @sorted_by_year_keys = sort { $project_year{$a} cmp $project_year{$b} } keys(%project_year);

    foreach my $id_key (@sorted_by_year_keys) {
        if (!$projects_that_are_crosses{$id_key} && !$projects_that_are_genotyping_trials{$id_key} && !$projects_that_are_genotyping_trials{$id_key} && !$projects_that_are_treatment_trials{$id_key} && !$projects_that_are_genotyping_data_projects{$id_key} && !$projects_that_are_drone_run_projects{$id_key} && !$projects_that_are_drone_run_band_projects{$id_key} && !$projects_that_are_analyses{$id_key} && !$projects_that_are_sampling_trials{$id_key}) {
            push @$field_trials, [ $id_key, $project_name{$id_key}, $project_description{$id_key}];
        } elsif ($projects_that_are_crosses{$id_key}) {
            push @$cross_trials, [ $id_key, $project_name{$id_key}, $project_description{$id_key}];
        } elsif ($projects_that_are_genotyping_trials{$id_key}) {
            push @$genotyping_trials, [ $id_key, $project_name{$id_key}, $project_description{$id_key}];
        } elsif ($projects_that_are_genotyping_data_projects{$id_key}) {
            push @$genotyping_data_projects, [ $id_key, $project_name{$id_key}, $project_description{$id_key}];
        } elsif ($projects_that_are_treatment_trials{$id_key}) {
            push @$field_management_factor_projects, [ $id_key, $project_name{$id_key}, $project_description{$id_key}];
        } elsif ($projects_that_are_drone_run_projects{$id_key}) {
            push @$drone_run_projects, [ $id_key, $project_name{$id_key}, $project_description{$id_key}];
        } elsif ($projects_that_are_drone_run_band_projects{$id_key}) {
            push @$drone_run_band_projects, [ $id_key, $project_name{$id_key}, $project_description{$id_key}];
        } elsif ($projects_that_are_analyses{$id_key}) {
            push @$analyses_projects, [ $id_key, $project_name{$id_key}, $project_description{$id_key}];
        } elsif ($projects_that_are_sampling_trials{$id_key}) {
            push @$sampling_trial_projects, [ $id_key, $project_name{$id_key}, $project_description{$id_key}];
        }
    }

    return ($field_trials, $cross_trials, $genotyping_trials, $genotyping_data_projects, $field_management_factor_projects, $drone_run_projects, $drone_run_band_projects, $analyses_projects, $sampling_trial_projects);
}

sub get_genotyping_trials_by_breeding_program {
    my $self = shift;
    my $breeding_project_id = shift;
    my $trials;
    my $h = $self->_get_all_trials_by_breeding_program($breeding_project_id);
    my $cross_cvterm_id = $self->get_cross_cvterm_id();
    my $project_year_cvterm_id = $self->get_project_year_cvterm_id();

    my %projects_that_are_crosses;
    my %projects_that_are_genotyping_trials;
    my %project_year;
    my %project_name;
    my %project_description;

    while (my ($id, $name, $desc, $prop, $propvalue) = $h->fetchrow_array()) {
	if ($name) {
	    $project_name{$id} = $name;
	}
	if ($desc) {
	    $project_description{$id} = $desc;
	}
	if ($prop) {
	    if ($prop == $cross_cvterm_id) {
		$projects_that_are_crosses{$id} = 1;
	    }
	    if ($prop == $project_year_cvterm_id) {
		$project_year{$id} = $propvalue;
	    }

	    if ($propvalue eq "genotyping_plate") {
		$projects_that_are_genotyping_trials{$id} = 1;
	    }
	}

    }

    my @sorted_by_year_keys = sort { $project_year{$a} cmp $project_year{$b} } keys(%project_year);

    foreach my $id_key (@sorted_by_year_keys) {
      if (!$projects_that_are_crosses{$id_key}) {
	if ($projects_that_are_genotyping_trials{$id_key}) {
	  push @$trials, [ $id_key, $project_name{$id_key}, $project_description{$id_key}];
	}
      }
    }

    return $trials;

}

sub get_all_locations {
     my $self = shift;
     my $c = shift;

     my $rs = $self->schema() -> resultset("NaturalDiversity::NdGeolocation")->search( {}, { order_by => 'description' } );
     my @locations = ();

     foreach my $loc ($rs->all()) {
         push @locations, [ $loc->nd_geolocation_id(), $loc->description() ];
     }

     return \@locations;

 }


 sub get_all_locations_by_breeding_program {
     my $self = shift;

    my $q = "SELECT geo.description,
    breeding_program.name
    FROM nd_geolocation AS geo
    LEFT JOIN nd_geolocationprop AS breeding_program_id ON (geo.nd_geolocation_id = breeding_program_id.nd_geolocation_id AND breeding_program_id.type_id = (SELECT cvterm_id from cvterm where name = 'breeding_program') )
    LEFT JOIN project breeding_program ON (breeding_program.project_id=breeding_program_id.value::INT)
    GROUP BY 1,2 ORDER BY 1";

    my $h = $self->schema()->storage()->dbh()->prepare($q);
    $h->execute();
    my @locations;

    while (my @location_data = $h->fetchrow_array()) {
        #foreach my $d (@location_data) {     ### NOT NECESSARY - it's already UTF8
        #    $d = Encode::encode_utf8($d);
        #}
     	my ($name, $prog) = @location_data;
         push(@locations, {
             properties => {
                 Name => $name,
                 Program => $prog
             }
         });
     }

     my $json = JSON->new();
     $json->canonical(); # output sorted JSON
     return $json->encode(\@locations);
}


sub get_location_geojson {
    my $self = shift;

    my $project_location_type_id = $self ->schema->resultset('Cv::Cvterm')->search( { 'name' => 'project location' })->first->cvterm_id();
    my $noaa_station_id_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($self->schema, 'noaa_station_id', 'geolocation_property')->cvterm_id();

    my $q = "SELECT A,B,C,D,E,string_agg(F, ' & '),G,H,I,J,K,L
        FROM
            (SELECT geo.nd_geolocation_id as A,
                geo.description AS B,
                abbreviation.value AS C,
                country_name.value AS D,
                country_code.value AS E,
                breeding_program.name AS F,
                location_type.value AS G,
                noaa_station_id.value AS L,
                latitude AS H,
                longitude AS I,
                altitude AS J,
                count(distinct(projectprop.project_id)) AS K
            FROM nd_geolocation AS geo
            LEFT JOIN nd_geolocationprop AS abbreviation ON (geo.nd_geolocation_id = abbreviation.nd_geolocation_id AND abbreviation.type_id = (SELECT cvterm_id from cvterm where name = 'abbreviation') )
            LEFT JOIN nd_geolocationprop AS country_name ON (geo.nd_geolocation_id = country_name.nd_geolocation_id AND country_name.type_id = (SELECT cvterm_id from cvterm where name = 'country_name') )
            LEFT JOIN nd_geolocationprop AS country_code ON (geo.nd_geolocation_id = country_code.nd_geolocation_id AND country_code.type_id = (SELECT cvterm_id from cvterm where name = 'country_code') )
            LEFT JOIN nd_geolocationprop AS location_type ON (geo.nd_geolocation_id = location_type.nd_geolocation_id AND location_type.type_id = (SELECT cvterm_id from cvterm where name = 'location_type') )
            LEFT JOIN nd_geolocationprop AS noaa_station_id ON (geo.nd_geolocation_id = noaa_station_id.nd_geolocation_id AND noaa_station_id.type_id = $noaa_station_id_cvterm_id )
            LEFT JOIN nd_geolocationprop AS breeding_program_id ON (geo.nd_geolocation_id = breeding_program_id.nd_geolocation_id AND breeding_program_id.type_id = (SELECT cvterm_id from cvterm where name = 'breeding_program') )
            LEFT JOIN project breeding_program ON (breeding_program.project_id=breeding_program_id.value::INT)
            LEFT JOIN projectprop ON (projectprop.value::INT = geo.nd_geolocation_id AND projectprop.type_id=?)
            GROUP BY 1,2,3,4,5,6,7,8
            ORDER BY 2)
        AS T1
        GROUP BY 1,2,3,4,5,7,8,9,10,11,12";


	my $h = $self->schema()->storage()->dbh()->prepare($q);
	$h->execute($project_location_type_id);
    my @locations;
    while (my @location_data = $h->fetchrow_array()) {
	foreach my $d (@location_data) {
	    ###$d = Encode::encode_utf8($d);   ## not necessary, it's already utf8
	}
	my ($id, $name, $abbrev, $country_name, $country_code, $prog, $type, $latitude, $longitude, $altitude, $trial_count, $noaa_station_id) = @location_data;

        my $lat = $latitude ? $latitude + 0 : undef;
        my $long = $longitude ? $longitude + 0 : undef;
        my $alt = $altitude ? $altitude + 0 : undef;
        push(@locations, {
            type => "Feature",
            properties => {
                Id => $id,
                Name => $name,
                Abbreviation => $abbrev,
                Country => $country_name,
                Code => $country_code,
                Program => $prog,
                Type => $type,
                Latitude => $lat,
                Longitude => $long,
                Altitude => $alt,
                Trials => '<a href="/search/trials?location_id='.$id.'">'.$trial_count.' trials</a>',
                NOAAStationID => $noaa_station_id
            },
            geometry => {
                type => "Point",
                coordinates => [$long, $lat]
            }
        });
    }
    my $json = JSON->new();
    $json->canonical(); # output sorted JSON
    return $json->encode(\@locations);
}

sub get_locations {
    my $self = shift;

    my @rows = $self->schema()->resultset('NaturalDiversity::NdGeolocation')->all();

    my $type_id = $self->schema()->resultset('Cv::Cvterm')->search( { 'name'=>'plot' })->first->cvterm_id;


    my @locations = ();
    foreach my $row (@rows) {
	my $plot_count = "SELECT count(*) from stock join cvterm on(type_id=cvterm_id) join nd_experiment_stock using(stock_id) join nd_experiment using(nd_experiment_id)   where cvterm.name='plot' and nd_geolocation_id=?"; # and sp_person_id=?";
	my $sh = $self->schema()->storage()->dbh->prepare($plot_count);
	$sh->execute($row->nd_geolocation_id); #, $c->user->get_object->get_sp_person_id);

	my ($count) = $sh->fetchrow_array();

	#if ($count > 0) {

		push @locations,  [ $row->nd_geolocation_id,
				    $row->description,
				    $row->latitude,
				    $row->longitude,
				    $row->altitude,
				    $count, # number of experiments TBD

		];
    }
    return \@locations;

}

sub get_all_years {
    my $self = shift;
    my $year_cv_id = $self->get_project_year_cvterm_id();
    my $rs = $self->schema()->resultset("Project::Projectprop")->search( { type_id=>$year_cv_id }, { distinct => 1, +select => 'value', order_by => { -desc => 'value' }} );
    my @years;

    foreach my $y ($rs->all()) {
	push @years, $y->value();
    }
    return @years;


}

sub get_accessions_by_breeding_program {


}

sub new_breeding_program {
    my $self= shift;
    my $name = shift;
    my $description = shift;
    my $external_references = shift;

    my $type_id = $self->get_breeding_program_cvterm_id();

    my $rs = $self->schema()->resultset("Project::Project")->search(
	{
	    name => $name,
	});
    if ($rs->count() > 0) {
	return { error => "A breeding program with name '$name' already exists." };

    }
    my $project_id;

    my $coderef = sub {

		my $role = CXGN::People::Roles->new({bcs_schema=>$self->schema});
		my $error = $role->add_sp_role($name);
		if ($error){
			die $error;
		}

        my $row = $self->schema()->resultset("Project::Project")->create(
            {
            name => $name,
            description => $description,
            });

        $row->insert();
        $project_id = $row->project_id();

        my $prop_row = $self->schema()->resultset("Project::Projectprop")->create(
            {
            type_id => $type_id,
            project_id => $row->project_id(),

            });
        $prop_row->insert();

        # save external references if specified
        if ($external_references) {
            my $references = CXGN::BrAPI::v2::ExternalReferences->new({
                bcs_schema          => $self->schema,
                external_references => $external_references,
                table_name          => 'project',
                table_id_key         => 'project_id',
                id             => $project_id
            });

            $references->store();

            if ($references->{'error'}) {
                return { error => $references->{'error'} };
            }
        }

    };

    my $transaction_error;

    try {
        $self->schema()->txn_do($coderef);
    } catch {
        $transaction_error =  $_;
    };

    if ($transaction_error) {
        warn $transaction_error;
        return {error => "An error occurred while generating a new breeding program."}
    }

    print STDERR "The new breeding program $name was created with id $project_id\n";
    return { success => "The new breeding program $name was created.", id => $project_id };

}

sub delete_breeding_program {
    my $self = shift;
    my $project_id = shift;

    my $type_id = $self->get_breeding_program_cvterm_id();

    # check if this project entry is of type 'breeding program'
    my $prop = $self->schema->resultset("Project::Projectprop")->search({
	type_id => $type_id,
	project_id => $project_id,
	});

    if ($prop->count() == 0) {
	return 0; # wrong type, return 0.
    }

    $prop->delete();

    my $rs = $self->schema->resultset("Project::Project")->search({
	project_id => $project_id,
	});

    if ($rs->count() > 0) {
	my $pprs = $self->schema->resultset("Project::ProjectRelationship")->search({
	    object_project_id => $project_id,
	});

	if ($pprs->count()>0) {
	    $pprs->delete();
	}
	$rs->delete();
	return 1;
    }
    return 0;
}

sub get_breeding_program_with_trial {
    my $self = shift;
    my $trial_id = shift;

    my $rs = $self->schema->resultset("Project::ProjectRelationship")->search( { subject_project_id => $trial_id });

    my $breeding_projects = [];
    if (my $row = $rs->next()) {
	my $prs = $self->schema->resultset("Project::Project")->search( { project_id => $row->object_project_id() } );
	while (my $b = $prs->next()) {
	    push @$breeding_projects, [ $b->project_id(), $b->name(), $b->description() ];
	}
    }



    return $breeding_projects;
}

sub get_crossing_trials {
    my $self = shift;

    my $crossing_trial_cvterm_id = $self->get_crossing_trial_cvterm_id();

    my $rs = $self->schema->resultset('Project::Project')->search( { 'projectprops.type_id'=>$crossing_trial_cvterm_id }, { join => 'projectprops' }  );

    my @crossing_trials;
    while (my $row = $rs->next()) {
	push @crossing_trials, [ $row->project_id, $row->name, $row->description ];
    }

    return \@crossing_trials;
}

sub get_breeding_program_cvterm_id {
    my $self = shift;

    my $breeding_program_cvterm_rs = $self->schema->resultset('Cv::Cvterm')->search( { name => 'breeding_program' });

    my $row;

    if ($breeding_program_cvterm_rs->count() == 0) {
	$row = SGN::Model::Cvterm->get_cvterm_row($self->schema, 'breeding_program','project_property');

    }
    else {
	$row = $breeding_program_cvterm_rs->first();
    }

    return $row->cvterm_id();
}

sub get_breeding_trial_cvterm_id {
    my $self = shift;

     my $breeding_trial_cvterm = SGN::Model::Cvterm->get_cvterm_row($self->schema, 'breeding_program_trial_relationship',  'project_relationship');

    return $breeding_trial_cvterm->cvterm_id();

}

sub get_cross_cvterm_id {
    my $self = shift;

    my $cross_cvterm = SGN::Model::Cvterm->get_cvterm_row($self->schema, 'cross',  'stock_type');
    return $cross_cvterm->cvterm_id();
}

sub get_crossing_trial_cvterm_id {
  my $self = shift;

  my $crossing_trial_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($self->schema, 'crossing_trial',  'project_type');
  return $crossing_trial_cvterm_id->cvterm_id();
}

sub _get_design_trial_cvterm_id {
    my $self = shift;
     my $cvterm = $self->schema->resultset("Cv::Cvterm")
      ->find({
		     name   => 'design',

		    });
    return $cvterm->cvterm_id();
}

sub get_project_year_cvterm_id {
    my $self = shift;
    my $year_cvterm_row = $self->schema->resultset('Cv::Cvterm')->find( { name => 'project year' });
    return $year_cvterm_row->cvterm_id();
}

sub get_gt_protocols {
    my $self = shift;
    my $genotyping_protocol_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($self->schema, 'genotyping_experiment', 'experiment_type')->cvterm_id();
    my $rs = $self->schema->resultset("NaturalDiversity::NdProtocol")->search( { type_id => $genotyping_protocol_cvterm_id} );
    #print STDERR "NdProtocol resultset rows:\n";
    my @protocols;
    while (my $row = $rs->next()) {
	#print STDERR "Name: " . $row->name() . "\n";
	#print STDERR "Name: " . $row->nd_protocol_id() . "\n";
	#print STDERR $row;
	push @protocols, [ $row->nd_protocol_id(), $row->name()];
    }
    return \@protocols;
}


1;
