package CXGN::BrAPI::v1::Studies;

use Moose;
use Data::Dumper;
use SGN::Model::Cvterm;
use CXGN::Trial;
use CXGN::Trial::Search;
use CXGN::Trial::TrialLayout;
use CXGN::Trait;
use CXGN::BrAPI::Pagination;

has 'bcs_schema' => (
	isa => 'Bio::Chado::Schema',
	is => 'rw',
	required => 1,
);

has 'metadata_schema' => (
	isa => 'CXGN::Metadata::Schema',
	is => 'rw',
	required => 1,
);

has 'phenome_schema' => (
	isa => 'CXGN::Phenome::Schema',
	is => 'rw',
	required => 1,
);

has 'page_size' => (
	isa => 'Int',
	is => 'rw',
	required => 1,
);

has 'page' => (
	isa => 'Int',
	is => 'rw',
	required => 1,
);

has 'status' => (
	isa => 'ArrayRef[Maybe[HashRef]]',
	is => 'rw',
	required => 1,
);

sub seasons {
	my $self = shift;
	my $page_size = $self->page_size;
	my $page = $self->page;
	my $status = $self->status;

	my @data;
    my $total_count = 0;
    my $year_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($self->bcs_schema,'project year', 'project_property')->cvterm_id();
    my $project_years_rs = $self->bcs_schema()->resultset("Project::Project")->search_related('projectprops', {'projectprops.type_id'=>$year_cvterm_id});
	my %unique_years;
    while (my $p_year = $project_years_rs->next()) {
		$unique_years{$p_year->value} = $p_year->projectprop_id;
    }
	my @sorted_years;
	foreach (sort keys %unique_years){
		push @sorted_years, [$_, $unique_years{$_}];
	}

	my $start = $page_size*$page;
	my $end = $page_size*($page+1)-1;
	for( my $i = $start; $i <= $end; $i++ ) {
		if ($sorted_years[$i]) {
			push @data, {
	            seasonsDbId=>$sorted_years[$i]->[1],
	            season=>'',
	            year=>$sorted_years[$i]->[0]
	        };
		}
	}
    my %result = (data=>\@data);
    $total_count = scalar(@sorted_years);
	push @$status, { 'success' => 'Seasons result constructed' };
	my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
	my $response = { 
		'status' => $status,
		'pagination' => $pagination,
		'result' => \%result,
		'datafiles' => []
	};
	return $response;
}

sub study_types {
	my $self = shift;
	my $page_size = $self->page_size;
	my $page = $self->page;
	my $status = $self->status;
	my @data;
	my @project_type_ids = CXGN::Trial::get_all_project_types($self->bcs_schema());
    foreach (@project_type_ids){
        push @data, {
            studyTypeDbId=>$_->[0],
            name=>$_->[1],
            description=>$_->[2],
        }
    }
    my %result = (data=>\@data);
    my $total_count = scalar(@project_type_ids);
	push @$status, { 'success' => 'StudyTypes result constructed' };
	my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
	my $response = { 
		'status' => $status,
		'pagination' => $pagination,
		'result' => \%result,
		'datafiles' => []
	};
	return $response;
}

sub studies_search {
	my $self = shift;
	my $search_params = shift;
	my $page_size = $self->page_size;
	my $page = $self->page;
	my $status = $self->status;
	my $schema = $self->bcs_schema;
    #my $auth = _authenticate_user($c);

    my @program_dbids = $search_params->{programDbIds} ? @{$search_params->{programDbIds}} : ();
    my @program_names = $search_params->{programNames} ? @{$search_params->{programNames}} : ();
    my @study_dbids = $search_params->{studyDbIds} ? @{$search_params->{studyDbIds}} : ();
    my @study_names = $search_params->{studyNames} ? @{$search_params->{studyNames}} : ();
    my @location_ids = $search_params->{studyLocationDbIds} ? @{$search_params->{studyLocationDbIds}} : ();
    my @location_names = $search_params->{studyLocationNames} ? @{$search_params->{studyLocationNames}} : ();
    my @study_type_list = $search_params->{studyTypeName} ? @{$search_params->{studyTypeName}} : ();
    #my @germplasm_dbids = @{$search_params->{germplasmDbIds}};
    #my @germplasm_names = @{$search_params->{germplasmNames}};
    #my @obs_variable_ids = @{$search_params->{observationVariableDbIds}};
    #my @obs_variable_names = @{$search_params->{observationVariableNames}};
    #my $sort_by = $c->req->param("sortBy");
    #my $sort_order = $c->req->param("sortOrder");

	#$self->bcs_schema->storage->debug(1);
    my $trial_search = CXGN::Trial::Search->new({
        bcs_schema=>$schema,
        location_list=>\@location_names,
        location_id_list=>\@location_ids,
        trial_type_list=>\@study_type_list,
        trial_id_list=>\@study_dbids,
        trial_name_list=>\@study_names,
        trial_name_is_exact=>1,
        program_list=>\@program_names,
        program_id_list=>\@program_dbids,
    });
    my $data = $trial_search->search();
    my @data_window;
    my $start = $page_size*$page;
    my $end = $page_size*($page+1)-1;
    for( my $i = $start; $i <= $end; $i++ ) {
        if (@$data[$i]) {
            my %additional_info = (
                design => @$data[$i]->{design},
                description => @$data[$i]->{description},
            );
            my %data_obj = (
                studyDbId => @$data[$i]->{trial_id},
                studyName => @$data[$i]->{trial_name},
                trialDbId => @$data[$i]->{folder_id},
                trialName => @$data[$i]->{folder_name},
                studyType => @$data[$i]->{trial_type},
                seasons => [@$data[$i]->{year}],
                locationDbId => @$data[$i]->{location_id},
                locationName => @$data[$i]->{location_name},
                programDbId => @$data[$i]->{breeding_program_id},
                programName => @$data[$i]->{breeding_program_name},
                startDate => @$data[$i]->{harvest_date},
                endDate => @$data[$i]->{planting_date},
                active=>'',
                additionalInfo=>\%additional_info
            );
            push @data_window, \%data_obj;
        }
    }
    #print STDERR Dumper \@data_window;

    my %result = (data=>\@data_window);
    my $total_count = scalar(@$data);
	push @$status, { 'success' => 'Studies-search result constructed' };
	my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
	my $response = {
		'status' => $status,
		'pagination' => $pagination,
		'result' => \%result,
		'datafiles' => []
	};
	return $response;
}

sub studies_germplasm {
	my $self = shift;
	my $study_id = shift;
	my $page_size = $self->page_size;
	my $page = $self->page;
	my $status = $self->status;
	my $schema = $self->bcs_schema;

	my $total_count = 0;

    my $tl = CXGN::Trial->new({ bcs_schema => $schema, trial_id => $study_id });
    my $accessions = $tl->get_accessions();
    my @germplasm_data;

    if ($accessions) {
        $total_count = scalar(@$accessions);
        my $start = $page_size*$page;
        my $end = $page_size*($page+1)-1;
        for( my $i = $start; $i <= $end; $i++ ) {
            if (@$accessions[$i]) {
				my $stockprop_hash = CXGN::Chado::Stock->new($self->bcs_schema, @$accessions[$i]->{stock_id})->get_stockprop_hash();
                push @germplasm_data, {
                    germplasmDbId=>@$accessions[$i]->{stock_id},
                    germplasmName=>@$accessions[$i]->{accession_name},
                    entryNumber=>'',
                    accessionNumber=>$stockprop_hash->{'accession number'} ? join ',', @{$stockprop_hash->{'accession number'}} : '',
                    germplasmPUI=>$stockprop_hash->{'PUI'} ? join ',', @{$stockprop_hash->{'PUI'}} : '',
                    pedigree=>$self->germplasm_pedigree_string(@$accessions[$i]->{stock_id}),
                    seedSource=>$stockprop_hash->{'seed source'} ? join ',', @{$stockprop_hash->{'seed source'}} : '',
                    synonyms=>$stockprop_hash->{'stock_synonym'} ? join ',', @{$stockprop_hash->{'stock_synonym'}} : '',
                };
            }
        }
    }

    my %result = (
        studyDbId=>$study_id,
        studyName=>$tl->get_name,
        data =>\@germplasm_data
    );
	push @$status, { 'success' => 'Studies-germplasm result constructed' };
	my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
	my $response = {
		'status' => $status,
		'pagination' => $pagination,
		'result' => \%result,
		'datafiles' => []
	};
	return $response;
}

sub studies_detail {
	my $self = shift;
	my $study_id = shift;
	my $page_size = $self->page_size;
	my $page = $self->page;
	my $status = $self->status;

	my $total_count = 0;
	my %result;
	my $t = CXGN::Trial->new({ bcs_schema => $self->bcs_schema, trial_id => $study_id });
	if ($t) {
		$total_count = 1;
		my $folder = CXGN::Trial::Folder->new( { folder_id => $study_id, bcs_schema => $self->bcs_schema } );
		if ($folder->folder_type eq 'trial') {

			my @years = ($t->get_year());
			my %additional_info = ();
			my $project_type = '';
			if ($t->get_project_type()) {
				$project_type = $t->get_project_type()->[1];
			}
			my $location_id = '';
			my $location_name = '';
			if ($t->get_location()) {
				$location_id = $t->get_location()->[0];
				$location_name = $t->get_location()->[1];
			}
			my $planting_date = '';
			if ($t->get_planting_date()) {
				$planting_date = $t->get_planting_date();
				my $t = Time::Piece->strptime($planting_date, "%Y-%B-%d");
				$planting_date = $t->strftime("%Y-%m-%d");
			}
			my $harvest_date = '';
			if ($t->get_harvest_date()) {
				$harvest_date = $t->get_harvest_date();
				my $t = Time::Piece->strptime($harvest_date, "%Y-%B-%d");
				$harvest_date = $t->strftime("%Y-%m-%d");
			}
			my $contacts = $t->get_trial_contacts();
			my $brapi_contacts;
			foreach (@$contacts){
				push @$brapi_contacts, {
					contactDbId => $_->{sp_person_id},
					name => $_->{salutation}." ".$_->{first_name}." ".$_->{last_name},
					email => $_->{email},
					type => '',
					orcid => ''
				};
			}
			my $location = CXGN::Trial::get_all_locations($self->bcs_schema, $location_id)->[0];
			%result = (
				studyDbId=>$t->get_trial_id(),
				studyName=>$t->get_name(),
				trialDbId=>$folder->project_parent->project_id(),
				trialName=>$folder->project_parent->name(),
				studyType=>$project_type,
				seasons=>\@years,
				locationDbId=>$location_id,
				locationName=>$location_name,
				programDbId=>$folder->breeding_program->project_id(),
				programName=>$folder->breeding_program->name(),
				startDate => $planting_date,
				endDate => $harvest_date,
				additionalInfo=>\%additional_info,
				active=>'',
				location=> {
					locationDbId => $location->[0],
	                locationType=>'',
	                name=> $location->[1],
	                abbreviation=>'',
	                countryCode=> $location->[6],
	                countryName=> $location->[5],
	                latitude=>$location->[2],
	                longitude=>$location->[3],
	                altitude=>$location->[4],
	                additionalInfo=> $location->[7]
				},
				contacts=>$brapi_contacts
			);
		}
	} else {
		push @$status, { 'error' => "StudyDbId not found." };
	}
	push @$status, { 'success' => 'Studies detail result constructed' };
	my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
	my $response = {
		'status' => $status,
		'pagination' => $pagination,
		'result' => \%result,
		'datafiles' => []
	};
	return $response;
}

sub studies_observation_variables {
	my $self = shift;
	my $study_id = shift;
	my $page_size = $self->page_size;
	my $page = $self->page;
	my $status = $self->status;

	my $total_count = 0;
	my %result;
	$result{studyDbId} = $study_id;
	my @data;
	my $t = CXGN::Trial->new({ bcs_schema => $self->bcs_schema, trial_id => $study_id });
	if ($t) {
		my $traits_assayed = $t->get_traits_assayed();
		$total_count = scalar(@$traits_assayed);
		my $start = $page_size*$page;
		my $end = $page_size*($page+1)-1;
		for( my $i = $start; $i <= $end; $i++ ) {
			if (@$traits_assayed[$i]) {
				my $trait = CXGN::Trait->new({bcs_schema=>$self->bcs_schema, cvterm_id=>@$traits_assayed[$i]->[0]});
				my $categories = $trait->categories;
				my @brapi_categories = split '/', $categories;
				push @data, {
					observationVariableDbId => $trait->cvterm_id,
					name => $trait->display_name,
					ontologyDbId => $trait->db_id,
					ontologyName => $trait->db,
					trait => {
						traitDbId => $trait->cvterm_id,
						name => $trait->name,
						description => $trait->definition,
					},
					method => {},
					scale => {
						scalreDbId =>'',
						name =>'',
						datatype=>$trait->format,
						decimalPlaces=>'',
						xref=>'',
						validValues=> {
							min=>$trait->minimum,
							max=>$trait->maximum,
							categories=>\@brapi_categories
						}
					},
					xref => $trait->term,
					defaultValue => $trait->default_value
				};
			}
		}
		$result{data} = \@data;
	}
	push @$status, { 'success' => 'Studies observation variables result constructed' };
	my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
	my $response = {
		'status' => $status,
		'pagination' => $pagination,
		'result' => \%result,
		'datafiles' => []
	};
	return $response;
}

sub studies_layout {
	my $self = shift;
	my $study_id = shift;
	my $page_size = $self->page_size;
	my $page = $self->page;
	my $status = $self->status;
	my $tl = CXGN::Trial::TrialLayout->new({ schema => $self->bcs_schema, trial_id => $study_id });
	my $design = $tl->get_design();

	my $plot_data = [];
	my $formatted_plot = {};
	my %additional_info;
	my $check_id;
	my $type;
	my $count = 0;
	my $offset = $page*$page_size;
	my $limit = $page_size*($page+1)-1;
	foreach my $plot_number (sort keys %$design) {
		if ($count >= $offset && $count <= ($offset+$limit)){
			$check_id = $design->{$plot_number}->{is_a_control} ? 1 : 0;
			if ($check_id == 1) {
				$type = 'Check';
			} else {
				$type = 'Test';
			}
			if ($design->{$plot_number}->{plant_names}){
				$additional_info{plantNames} = $design->{$plot_number}->{plant_names};
			}
			if ($design->{$plot_number}->{plant_ids}){
				$additional_info{plantDbIds} = $design->{$plot_number}->{plant_ids};
			}
			$formatted_plot = {
				studyDbId => $study_id,
				observationUnitDbId => $design->{$plot_number}->{plot_id},
				observationUnitName => $design->{$plot_number}->{plot_name},
				observationLevel => 'plot',
				replicate => $design->{$plot_number}->{replicate} ? $design->{$plot_number}->{replicate} : '',
				blockNumber => $design->{$plot_number}->{block_number} ? $design->{$plot_number}->{block_number} : '',
				X => $design->{$plot_number}->{row_number} ? $design->{$plot_number}->{row_number} : '',
				Y => $design->{$plot_number}->{col_number} ? $design->{$plot_number}->{col_number} : '',
				entryType => $type,
				germplasmName => $design->{$plot_number}->{accession_name},
				germplasmDbId => $design->{$plot_number}->{accession_id},
				additionalInfo => \%additional_info
			};
			push @$plot_data, $formatted_plot;
		}
		$count++;
	}
	my %result = (data=>$plot_data);
	push @$status, { 'success' => 'Studies layout result constructed' };
	my $pagination = CXGN::BrAPI::Pagination->pagination_response($count,$page_size,$page);
	my $response = {
		'status' => $status,
		'pagination' => $pagination,
		'result' => \%result,
		'datafiles' => []
	};
	return $response;
}


sub germplasm_pedigree_string {
	my $self = shift;
	my $stock_id = shift;
    my $s = CXGN::Chado::Stock->new($self->bcs_schema, $stock_id);
    my $pedigree_root = $s->get_parents('1');
    my $pedigree_string = $pedigree_root->get_pedigree_string('1');
    return $pedigree_string;
}

1;
