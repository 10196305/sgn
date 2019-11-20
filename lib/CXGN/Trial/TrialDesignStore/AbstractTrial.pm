

package CXGN::Trial::TrialDesignStore::AbstractTrial;

has 'bcs_schema' => (
    is       => 'rw',
    isa      => 'DBIx::Class::Schema',
    predicate => 'has_chado_schema',
    required => 1,
);

has 'trial_id' => (isa => 'Int', is => 'rw', predicate => 'has_trial_id', required => 1);

has 'trial_name' => (isa => 'Str', is => 'rw', predicate => 'has_trial_name', required => 0);

has 'nd_experiment_id' => (isa => 'Int', is => 'rw', predicate => 'has_nd_experiment_id', required => 0);

has 'nd_geolocation_id' => (isa => 'Int', is => 'rw', predicate => 'has_nd_geolocation_id', required => 1);

has 'design_type' => (isa => 'Str', is => 'rw', predicate => 'has_design_type', required => 1);

has 'design' => (isa => 'HashRef[HashRef]|Undef', is => 'rw', predicate => 'has_design', required => 1);

has 'is_genotyping' => (isa => 'Bool', is => 'rw', required => 0, default => 0);

has 'layout_type' => (isa => 'Str', is => 'rw', default => "phentoyping_trial"); # either field_trial, genotyping_trial, or analysis

has 'stocks_exist' => (isa => 'Bool', is => 'rw', required => 0, default => 0);

has 'new_treatment_has_plant_entries' => (isa => 'Maybe[Int]', is => 'rw', required => 0, default => 0);

has 'new_treatment_has_subplot_entries' => (isa => 'Maybe[Int]', is => 'rw', required => 0, default => 0);

has 'new_treatment_has_tissue_sample_entries' => (isa => 'Maybe[Int]', is => 'rw', required => 0, default => 0);

has 'new_treatment_date' => (isa => 'Maybe[Str]', is => 'rw', required => 0, default => 0);

has 'new_treatment_year' => (isa => 'Maybe[Str]', is => 'rw', required => 0, default => 0);

has 'new_treatment_type' => (isa => 'Maybe[Str]', is => 'rw', required => 0, default => 0);

has 'operator' => (isa => 'Str', is => 'rw', required => 1);

has 'nd_experiment_type_id' => (isa => 'Int', is => 'rw');

has 'stock_relationship_type_id' => (isa => 'Int', is => 'rw');

has 'stock_type_id' => (isa => 'Int', is => 'rw');

has 'seedlot_cvterm_id'  => (isa => 'Int', is => 'rw');

has 'accession_cvterm_id'  => (isa => 'Int', is => 'rw');

has 'tissue_sample_cvterm_id'  => (isa => 'Int', is => 'rw');

has 'tissue_sample_of_cvterm_id'  => (isa => 'Int', is => 'rw');

has 'plot_cvterm_id' => (isa => 'Int', is => 'rw');

has 'lot_of_cvterm_id' => (isa => 'Int', is => 'rw');

has 'plant_cvterm_id' => (isa => 'Int', is => 'rw');

has 'subplot_cvterm_id' => (isa => 'Int', is => 'rw');

has 'subplot_of_cvterm_id' => (isa => 'Int', is => 'rw');

has 'plant_of_subplot_cvterm_id' => (isa => 'Int', is => 'rw');

has 'subplot_index_number_cvterm_id' => (isa => 'Int', is => 'rw');

has 'plant_of_cvterm_id' => (isa => 'Int', is => 'rw');

has 'plant_index_number_cvterm_id' => (isa => 'Int', is => 'rw');

has 'replicate_cvterm_id' => (isa => 'Int', is => 'rw');

has 'block_cvterm_id' => (isa => 'Int', is => 'rw');
has 'plot_number_cvterm_id' => (isa => 'Int', is => 'rw');

has 'is_control_cvterm_id' => (isa => 'Int', is => 'rw');

has 'range_cvterm_id' => (isa => 'Int', is => 'rw');

has 'row_number_cvterm_id' => (isa => 'Int', is => 'rw');

has 'col_number_cvterm_id' => (isa => 'Int', is => 'rw');

has 'is_blank_cvterm_id' => (isa => 'Int', is => 'rw');

has 'concentration_cvterm_id' => (isa => 'Int', is => 'rw');

has 'volume_cvterm_id' => (isa => 'Int', is => 'rw');

has 'dna_person_cvterm_id' => (isa => 'Int', is => 'rw');

has 'extraction_cvterm_id' => (isa => 'Int', is => 'rw');

has 'tissue_type_cvterm_id' => (isa => 'Int', is => 'rw');

has 'acquisition_date_cvterm_id' => (isa => 'Int', is => 'rw');

has 'ncbi_taxonomy_id_cvterm_id' => (isa => 'Int', is => 'rw');

has 'notes_cvterm_id' => (isa => 'Int', is => 'rw');

has 'treatment_nd_experiment_type_id' => (isa => 'Int', is => 'rw');

has 'project_design_cvterm_id' => (isa => 'Int', is => 'rw');

has 'management_factor_year_cvterm_id' => (isa => 'Int', is => 'rw');

has 'management_factor_date_cvterm_id' => (isa => 'Int', is => 'rw');

has 'management_factor_type_cvterm_id' => (isa => 'Int', is => 'rw');

has 'trial_treatment_relationship_cvterm_id' => (isa => 'Int', is => 'rw');

has 'has_plants_cvterm' => (isa => 'Int', is => 'rw');

has 'has_subplots_cvterm' => (isa => 'Int', is => 'rw');

has 'has_tissues_cvterm' => (isa => 'Int', is => 'rw');

sub BUILD {
    my $self = shift;
    $self->seedlot_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'seedlot', 'stock_type')->cvterm_id());
    $self->accession_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'accession', 'stock_type')->cvterm_id());
    $self->tissue_sample_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'tissue_sample', 'stock_type')->cvterm_id());
    $self->tissue_sample_of_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'tissue_sample_of', 'stock_relationship')->cvterm_id());
    $self->plot_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'plot', 'stock_type')->cvterm_id());
    $self->plot_of_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'plot_of', 'stock_relationship')->cvterm_id());
    $self->plant_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'plant', 'stock_type')->cvterm_id());
    $self->subplot_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'subplot', 'stock_type')->cvterm_id());
    $self->subplot_of_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'subplot_of', 'stock_relationship')->cvterm_id());
    $self->plant_of_subplot_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'plant_of_subplot', 'stock_relationship')->cvterm_id());
    $self->subplot_index_number_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'subplot_index_number', 'stock_property')->cvterm_id());
    $self->plant_of_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'plant_of', 'stock_relationship')->cvterm_id());
    $self->plant_index_number_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'plant_index_number', 'stock_property')->cvterm_id());
    $self->replicate_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'replicate', 'stock_property')->cvterm_id());
    $self->block_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'block', 'stock_property')->cvterm_id());
    $self->plot_number_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'plot number', 'stock_property')->cvterm_id());
    $self->is_control_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'is a control', 'stock_property')->cvterm_id());
    $self->range_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'range', 'stock_property')->cvterm_id());
    $self->row_number_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'row_number', 'stock_property')->cvterm_id());
    $self->col_number_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'col_number', 'stock_property')->cvterm_id());
    $self->is_blank_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'is_blank', 'stock_property')->cvterm_id());
    $self->concentration_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'concentration', 'stock_property')->cvterm_id());
    $self->volume_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'volume', 'stock_property')->cvterm_id());
    $self->dna_person_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'dna_person', 'stock_property')->cvterm_id());
    $self->extraction_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'extraction', 'stock_property')->cvterm_id());
    $self->tissue_type_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'tissue_type', 'stock_property')->cvterm_id());
    $self->acquisition_date_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'acquisition date', 'stock_property')->cvterm_id());
    $self->ncbi_taxonomy_id_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'ncbi_taxonomy_id', 'stock_property')->cvterm_id());
    $self->notes_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'notes', 'stock_property')->cvterm_id());
    $self->treatment_nd_experiment_type_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'treatment_experiment', 'experiment_type')->cvterm_id());
    $self->project_design_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'design', 'project_property')->cvterm_id());
    $self->management_factor_year_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'project year', 'project_property')->cvterm_id());
    $self->management_factor_date_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'management_factor_date', 'project_property')->cvterm_id());
    $self->management_factor_type_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'management_factor_type', 'project_property')->cvterm_id());
    $self->trial_treatment_relationship_cvterm_id(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'trial_treatment_relationship', 'project_relationship')->cvterm_id());
    $self->has_plants_cvterm(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'project_has_plant_entries', 'project_property')->cvterm_id());
    $self->has_subplots_cvterm(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'project_has_subplot_entries', 'project_property')->cvterm_id());
    $self->has_tissues_cvterm(SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'project_has_tissue_sample_entries', 'project_property')->cvterm_id());
}

sub validate_design {
    print STDERR "Implement validate_design in subclass\n";
}

sub store {
    print STDERR "Saving design ".localtime()."\n";
    my $self = shift;
    my $chado_schema = $self->get_bcs_schema;
    my $design_type = $self->get_design_type;
    my %design = %{$self->get_design};
    my $trial_id = $self->get_trial_id;
    my $nd_geolocation_id = $self->get_nd_geolocation_id;


    my $nd_experiment_type_id;
    my $stock_type_id;
    my $stock_rel_type_id;
    my @source_stock_types;
    if (!$self->get_is_genotyping) {
        $nd_experiment_type_id = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'field_layout', 'experiment_type')->cvterm_id();
        $stock_type_id = $plot_cvterm_id;
        $stock_rel_type_id = $plot_of_cvterm_id;
        @source_stock_types = ($accession_cvterm_id);
    } else {
        $nd_experiment_type_id = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'genotyping_layout', 'experiment_type')->cvterm_id();
        $stock_type_id = $tissue_sample_cvterm_id;
        $stock_rel_type_id = $tissue_sample_of_cvterm_id;
        @source_stock_types = ($accession_cvterm_id, $plot_cvterm_id, $plant_cvterm_id, $tissue_sample_cvterm_id);
    }

    #$chado_schema->storage->debug(1);
    my $nd_experiment_id;
    if ($self->has_nd_experiment_id){
        $nd_experiment_id = $self->get_nd_experiment_id();
    } else {
        my $nd_experiment_project;
        my $nd_experiment_project_rs = $chado_schema->resultset('NaturalDiversity::NdExperimentProject')->search(
            {
                'me.project_id'=>$trial_id,
                'nd_experiment.type_id'=>$nd_experiment_type_id,
                'nd_experiment.nd_geolocation_id'=>$nd_geolocation_id
            },
            { join => 'nd_experiment'}
        );

        if ($nd_experiment_project_rs->count < 1) {
            my $nd_experiment = $chado_schema->resultset('NaturalDiversity::NdExperiment')
            ->create({
                nd_geolocation_id => $self->get_nd_geolocation_id,
                type_id => $nd_experiment_type_id,
            });
            $nd_experiment_project = $nd_experiment->find_or_create_related('nd_experiment_projects', {project_id => $trial_id} );
        } elsif ($nd_experiment_project_rs->count > 1) {
            print STDERR "ERROR: More than one nd_experiment of type=$nd_experiment_type_id for project=$trial_id\n";
            $nd_experiment_project = $nd_experiment_project_rs->first;
        } elsif ($nd_experiment_project_rs->count == 1) {
            print STDERR "OKAY: NdExperimentProject type=$nd_experiment_type_id for project$trial_id\n";
            $nd_experiment_project = $nd_experiment_project_rs->first;
        }
        if ($nd_experiment_project){
            $nd_experiment_id = $nd_experiment_project->nd_experiment_id();
        }
    }

    my %seen_accessions_hash;
    my %seen_seedlots_hash;
    foreach my $key (keys %design) {
        if ($design{$key}->{stock_name}) {
            my $stock_name = $design{$key}->{stock_name};
            $seen_accessions_hash{$stock_name}++;
        }
        if ($design{$key}->{seedlot_name}) {
            my $stock_name = $design{$key}->{seedlot_name};
            $seen_seedlots_hash{$stock_name}++;
        }
    }
    my @seen_accessions = keys %seen_accessions_hash;
    my @seen_seedlots = keys %seen_seedlots_hash;

    my $seedlot_rs = $chado_schema->resultset('Stock::Stock')->search({
        'is_obsolete' => { '!=' => 't' },
        'type_id' => $seedlot_cvterm_id,
        'uniquename' => {-in=>\@seen_seedlots}
    });
    my %seedlot_data;
    while (my $s = $seedlot_rs->next()) {
        $seedlot_data{$s->uniquename} = $s->stock_id;
    }

    my $rs = $chado_schema->resultset('Stock::Stock')->search({
        'is_obsolete' => { '!=' => 't' },
        'type_id' => {-in=>\@source_stock_types},
        'uniquename' => {-in=>\@seen_accessions}
    });
    my %stock_data;
    while (my $s = $rs->next()) {
        $stock_data{$s->uniquename} = [$s->stock_id, $s->organism_id, $s->type_id];
    }

    my $stock_id_checked;
    my $stock_name_checked;
    my $organism_id_checked;
    my $stock_type_checked;
    my $timestamp = localtime();

    my $coderef = sub {

        #print STDERR Dumper \%design;
        my %new_stock_ids_hash;
        my $stock_rs = $chado_schema->resultset("Stock::Stock");

        foreach my $key (keys %design) {

            if ($key eq 'treatments'){
                next;
            }

            my $plot_name;
            if ($design{$key}->{plot_name}) {
                $plot_name = $design{$key}->{plot_name};
            }
            my $plot_number;
            if ($design{$key}->{plot_number}) {
                $plot_number = $design{$key}->{plot_number};
            } else {
                $plot_number = $key;
            }
            my $plant_names;
            if ($design{$key}->{plant_names}) {
                $plant_names = $design{$key}->{plant_names};
            }
            my $subplot_names;
            if ($design{$key}->{subplots_names}) {
                $subplot_names = $design{$key}->{subplots_names};
            }
            my $subplots_plant_names;
            if ($design{$key}->{subplots_plant_names}) {
                $subplots_plant_names = $design{$key}->{subplots_plant_names};
            }
            my $stock_name;
            if ($design{$key}->{stock_name}) {
                $stock_name = $design{$key}->{stock_name};
            }
            my $seedlot_name;
            my $seedlot_stock_id;
            if ($design{$key}->{seedlot_name}) {
                $seedlot_name = $design{$key}->{seedlot_name};
                $seedlot_stock_id = $seedlot_data{$seedlot_name};
            }
            my $num_seed_per_plot;
            if($design{$key}->{num_seed_per_plot}){
                $num_seed_per_plot = $design{$key}->{num_seed_per_plot};
            }
            my $weight_gram_seed_per_plot;
            if($design{$key}->{weight_gram_seed_per_plot}){
                $weight_gram_seed_per_plot = $design{$key}->{weight_gram_seed_per_plot};
            }
            my $block_number;
            if ($design{$key}->{block_number}) { #set block number to 1 if no blocks are specified
                $block_number = $design{$key}->{block_number};
            } else {
                $block_number = 1;
            }
            my $rep_number;
            if ($design{$key}->{rep_number}) { #set rep number to 1 if no reps are specified
                $rep_number = $design{$key}->{rep_number};
            } else {
                $rep_number = 1;
            }
            my $is_a_control;
            if ($design{$key}->{is_a_control}) {
                $is_a_control = $design{$key}->{is_a_control};
            }
            my $row_number;
            if ($design{$key}->{row_number}) {
                $row_number = $design{$key}->{row_number};
            }
            my $col_number;
            if ($design{$key}->{col_number}) {
                $col_number = $design{$key}->{col_number};
            }
            my $range_number;
            if ($design{$key}->{range_number}) {
                $range_number = $design{$key}->{range_number};
            }
            my $well_is_blank;
            if ($design{$key}->{is_blank}) {
                $well_is_blank = $design{$key}->{is_blank};
            }
            my $well_concentration;
            if ($design{$key}->{concentration}) {
                $well_concentration = $design{$key}->{concentration};
            }
            my $well_volume;
            if ($design{$key}->{volume}) {
                $well_volume = $design{$key}->{volume};
            }
            my $well_dna_person;
            if ($design{$key}->{dna_person}) {
                $well_dna_person = $design{$key}->{dna_person};
            }
            my $well_extraction;
            if ($design{$key}->{extraction}) {
                $well_extraction = $design{$key}->{extraction};
            }
            my $well_tissue_type;
            if ($design{$key}->{tissue_type}) {
                $well_tissue_type = $design{$key}->{tissue_type};
            }
            my $acquisition_date;
            if ($design{$key}->{acquisition_date}) {
                $acquisition_date = $design{$key}->{acquisition_date};
            }
            my $notes;
            if ($design{$key}->{notes}) {
                $notes = $design{$key}->{notes};
            }
            my $ncbi_taxonomy_id;
            if ($design{$key}->{ncbi_taxonomy_id}) {
                $ncbi_taxonomy_id = $design{$key}->{ncbi_taxonomy_id};
            }

            #check if stock_name exists in database by checking if stock_name is key in %stock_data. if it is not, then check if it exists as a synonym in the database.
            if ($stock_data{$stock_name}) {
                $stock_id_checked = $stock_data{$stock_name}[0];
                $organism_id_checked = $stock_data{$stock_name}[1];
                $stock_type_checked = $stock_data{$stock_name}[2];
                $stock_name_checked = $stock_name;
            } else {
                my $parent_stock;
                my $stock_lookup = CXGN::Stock::StockLookup->new(schema => $chado_schema);
                $stock_lookup->set_stock_name($stock_name);
                $parent_stock = $stock_lookup->get_stock($accession_cvterm_id);

                if (!$parent_stock) {
                    die ("Error while saving trial layout: no stocks found matching $stock_name");
                }

                $stock_id_checked = $parent_stock->stock_id();
                $stock_name_checked = $parent_stock->uniquename;
                $stock_type_checked = $parent_stock->type_id;
                $organism_id_checked = $parent_stock->organism_id();
            }

            #create the plot, if plot given
            my $new_plot_id;
            if ($plot_name) {
                my @plot_stock_props = (
                    { type_id => $replicate_cvterm_id, value => $rep_number },
                    { type_id => $block_cvterm_id, value => $block_number },
                    { type_id => $plot_number_cvterm_id, value => $plot_number }
                );
                if ($is_a_control) {
                    push @plot_stock_props, { type_id => $is_control_cvterm_id, value => $is_a_control };
                }
                if ($range_number) {
                    push @plot_stock_props, { type_id => $range_cvterm_id, value => $range_number };
                }
                if ($row_number) {
                    push @plot_stock_props, { type_id => $row_number_cvterm_id, value => $row_number };
                }
                if ($col_number) {
                    push @plot_stock_props, { type_id => $col_number_cvterm_id, value => $col_number };
                }
                if ($well_is_blank) {
                    push @plot_stock_props, { type_id => $is_blank_cvterm_id, value => $well_is_blank };
                }
                if ($well_concentration) {
                    push @plot_stock_props, { type_id => $concentration_cvterm_id, value => $well_concentration };
                }
                if ($well_volume) {
                    push @plot_stock_props, { type_id => $volume_cvterm_id, value => $well_volume };
                }
                if ($well_extraction) {
                    push @plot_stock_props, { type_id => $extraction_cvterm_id, value => $well_extraction };
                }
                if ($well_tissue_type) {
                    push @plot_stock_props, { type_id => $tissue_type_cvterm_id, value => $well_tissue_type };
                }
                if ($well_dna_person) {
                    push @plot_stock_props, { type_id => $dna_person_cvterm_id, value => $well_dna_person };
                }
                if ($acquisition_date) {
                    push @plot_stock_props, { type_id => $acquisition_date_cvterm_id, value => $acquisition_date };
                }
                if ($notes) {
                    push @plot_stock_props, { type_id => $notes_cvterm_id, value => $notes };
                }
                if ($ncbi_taxonomy_id) {
                    push @plot_stock_props, { type_id => $ncbi_taxonomy_id_cvterm_id, value => $ncbi_taxonomy_id };
                }

                my @plot_subjects;
                my @plot_objects;

                my $parent_stock;
                push @plot_subjects, { type_id => $stock_rel_type_id, object_id => $stock_id_checked };

                # For genotyping plate, if the well tissue_sample is sourced from a plot, then we store relationships between the tissue_sample and the plot, and the tissue sample and the plot's accession if it exists.
                if ($stock_type_checked == $plot_cvterm_id){
                    my $parent_plot_accession_rs = $chado_schema->resultset("Stock::StockRelationship")->search({
                        'me.subject_id'=>$stock_id_checked,
                        'me.type_id'=>$plot_of_cvterm_id,
                        'object.type_id'=>$accession_cvterm_id
                    }, {join => 'object'});
                    if ($parent_plot_accession_rs->count > 1){
                        die "Plot $stock_id_checked is linked to more than one accession!\n"
                    }
                    if ($parent_plot_accession_rs->count == 1){
                        push @plot_subjects, { type_id => $stock_rel_type_id, object_id => $parent_plot_accession_rs->first->object_id };
                    }
                }
                # For genotyping plate, if the well tissue_sample is sourced from a plant, then we store relationships between the tissue_sample and the plant, and the tissue_sample and the plant's plot if it exists, and the tissue sample and the plant's accession if it exists.
                if ($stock_type_checked == $plant_cvterm_id){
                    my $parent_plant_accession_rs = $chado_schema->resultset("Stock::StockRelationship")->search({
                        'me.subject_id'=>$stock_id_checked,
                        'me.type_id'=>$plant_of_cvterm_id,
                        'object.type_id'=>$accession_cvterm_id
                    }, {join => "object"});
                    if ($parent_plant_accession_rs->count > 1){
                        die "Plant $stock_id_checked is linked to more than one accession!\n"
                    }
                    if ($parent_plant_accession_rs->count == 1){
                        push @plot_subjects, { type_id => $stock_rel_type_id, object_id => $parent_plant_accession_rs->first->object_id };
                    }
                    my $parent_plot_of_plant_rs = $chado_schema->resultset("Stock::StockRelationship")->search({
                        'me.subject_id'=>$stock_id_checked,
                        'me.type_id'=>$plant_of_cvterm_id,
                        'object.type_id'=>$plot_cvterm_id
                    }, {join => "object"});
                    if ($parent_plot_of_plant_rs->count > 1){
                        die "Plant $stock_id_checked is linked to more than one plot!\n"
                    }
                    if ($parent_plot_of_plant_rs->count == 1){
                        push @plot_subjects, { type_id => $stock_rel_type_id, object_id => $parent_plot_of_plant_rs->first->object_id };
                    }
                }
                # For genotyping plate, if the well tissue_sample is sourced from another tissue_sample, then we store relationships between the new tissue_sample and the source tissue_sample, and the new tissue_sample and the tissue_sample's plant if it exists, and the new tissue_sample and the tissue_sample's plot if it exists, and the new tissue sample and the tissue_sample's accession if it exists.
                if ($stock_type_checked == $tissue_sample_cvterm_id){
                    my $parent_tissue_sample_accession_rs = $chado_schema->resultset("Stock::StockRelationship")->search({
                        'me.subject_id'=>$stock_id_checked,
                        'me.type_id'=>$tissue_sample_of_cvterm_id,
                        'object.type_id'=>$accession_cvterm_id
                    }, {join => "object"});
                    if ($parent_tissue_sample_accession_rs->count > 1){
                        die "Tissue_sample $stock_id_checked is linked to more than one accession!\n"
                    }
                    if ($parent_tissue_sample_accession_rs->count == 1){
                        push @plot_subjects, { type_id => $stock_rel_type_id, object_id => $parent_tissue_sample_accession_rs->first->object_id };
                    }
                    my $parent_plot_of_tissue_sample_rs = $chado_schema->resultset("Stock::StockRelationship")->search({
                        'me.subject_id'=>$stock_id_checked,
                        'me.type_id'=>$tissue_sample_of_cvterm_id,
                        'object.type_id'=>$plot_cvterm_id
                    }, {join => "object"});
                    if ($parent_plot_of_tissue_sample_rs->count > 1){
                        die "Tissue_sample $stock_id_checked is linked to more than one plot!\n"
                    }
                    if ($parent_plot_of_tissue_sample_rs->count == 1){
                        push @plot_subjects, { type_id => $stock_rel_type_id, object_id => $parent_plot_of_tissue_sample_rs->first->object_id };
                    }
                    my $parent_plant_of_tissue_sample_rs = $chado_schema->resultset("Stock::StockRelationship")->search({
                        'me.subject_id'=>$stock_id_checked,
                        'me.type_id'=>$tissue_sample_of_cvterm_id,
                        'object.type_id'=>$plant_cvterm_id
                    }, {join => "object"});
                    if ($parent_plant_of_tissue_sample_rs->count > 1){
                        die "Tissue_sample $stock_id_checked is linked to more than one plant!\n"
                    }
                    if ($parent_plant_of_tissue_sample_rs->count == 1){
                        push @plot_subjects, { type_id => $stock_rel_type_id, object_id => $parent_plant_of_tissue_sample_rs->first->object_id };
                    }
                }

                my @plot_nd_experiment_stocks = (
                    { nd_experiment_id => $nd_experiment_id, type_id => $nd_experiment_type_id }
                );

                my $plot = $stock_rs->create({
                    organism_id => $organism_id_checked,
                    name       => $plot_name,
                    uniquename => $plot_name,
                    type_id => $stock_type_id,
                    stockprops => \@plot_stock_props,
                    stock_relationship_subjects => \@plot_subjects,
                    stock_relationship_objects => \@plot_objects,
                    nd_experiment_stocks => \@plot_nd_experiment_stocks,
                });
                $new_plot_id = $plot->stock_id();
                $new_stock_ids_hash{$plot_name} = $new_plot_id;

                if ($seedlot_stock_id && $seedlot_name){
                    my $transaction = CXGN::Stock::Seedlot::Transaction->new(schema => $chado_schema);
                    $transaction->from_stock([$seedlot_stock_id, $seedlot_name]);
                    $transaction->to_stock([$plot->stock_id(), $plot->uniquename()]);
                    if ($num_seed_per_plot){
                        $transaction->amount($num_seed_per_plot);
                    }
                    if ($weight_gram_seed_per_plot){
                        $transaction->weight_gram($weight_gram_seed_per_plot);
                    }
                    $transaction->timestamp($timestamp);
                    my $description = "Created Trial: ".$self->get_trial_name." Plot: ".$plot->uniquename;
                    $transaction->description($description);
                    $transaction->operator($self->get_operator);
                    my $transaction_id = $transaction->store();
                    my $sl = CXGN::Stock::Seedlot->new(schema=>$chado_schema, seedlot_id=>$seedlot_stock_id);
                    $sl->set_current_count_property();
                    $sl->set_current_weight_property();
                }
            }

            #Create plant entry if given. Currently this is for the greenhouse trial creation and splitplot trial creation.
            if ($plant_names) {
                my $plant_index_number = 1;
                foreach my $plant_name (@$plant_names) {

                    my @plant_stock_props = (
                        { type_id => $plant_index_number_cvterm_id, value => $plant_index_number },
                        { type_id => $replicate_cvterm_id, value => $rep_number },
                        { type_id => $block_cvterm_id, value => $block_number },
                        { type_id => $plot_number_cvterm_id, value => $plot_number }
                    );
                    if ($is_a_control) {
                        push @plant_stock_props, { type_id => $is_control_cvterm_id, value => $is_a_control };
                    }
                    if ($range_number) {
                        push @plant_stock_props, { type_id => $range_cvterm_id, value => $range_number };
                    }
                    if ($row_number) {
                        push @plant_stock_props, { type_id => $row_number_cvterm_id, value => $row_number };
                    }
                    if ($col_number) {
                        push @plant_stock_props, { type_id => $col_number_cvterm_id, value => $col_number };
                    }

                    my @plant_objects = (
                        { type_id => $plant_of_cvterm_id, subject_id => $new_plot_id }
                    );
                    my @plant_subjects = (
                        { type_id => $plant_of_cvterm_id, object_id => $stock_id_checked }
                    );
                    my @plant_nd_experiment_stocks = (
                        { type_id => $nd_experiment_type_id, nd_experiment_id => $nd_experiment_id }
                    );

                    my $plant = $stock_rs->create({
                        organism_id => $organism_id_checked,
                        name       => $plant_name,
                        uniquename => $plant_name,
                        type_id => $plant_cvterm_id,
                        stockprops => \@plant_stock_props,
                        stock_relationship_subjects => \@plant_subjects,
                        stock_relationship_objects => \@plant_objects,
                        nd_experiment_stocks => \@plant_nd_experiment_stocks,
                    });
                    $new_stock_ids_hash{$plant_name} = $plant->stock_id();
                    $plant_index_number++;
                }
            }
            #Create subplot entry if given. Currently this is for the splitplot trial creation.
            if ($subplot_names) {
                my $subplot_index_number = 1;
                foreach my $subplot_name (@$subplot_names) {
                    my @subplot_stockprops = (
                        { type_id => $subplot_index_number_cvterm_id, value => $subplot_index_number },
                        { type_id => $replicate_cvterm_id, value => $rep_number },
                        { type_id => $block_cvterm_id, value => $block_number },
                        { type_id => $plot_number_cvterm_id, value => $plot_number }
                    );
                    if ($is_a_control) {
                        push @subplot_stockprops, { type_id => $is_control_cvterm_id, value => $is_a_control };
                    }
                    if ($range_number) {
                        push @subplot_stockprops, { type_id => $range_cvterm_id, value => $range_number };
                    }
                    if ($row_number) {
                        push @subplot_stockprops, { type_id => $row_number_cvterm_id, value => $row_number };
                    }
                    if ($col_number) {
                        push @subplot_stockprops, { type_id => $col_number_cvterm_id, value => $col_number };
                    }

                    my @subplot_objects = (
                        { type_id => $subplot_of_cvterm_id, subject_id => $new_plot_id }
                    );
                    my @subplot_subjects = (
                        { type_id => $subplot_of_cvterm_id, object_id => $stock_id_checked }
                    );
                    my @subplot_nd_experiment_stocks = (
                        { type_id => $nd_experiment_type_id, nd_experiment_id => $nd_experiment_id }
                    );

                    if ($subplots_plant_names){
                        my $subplot_plants = $subplots_plant_names->{$subplot_name};
                        foreach (@$subplot_plants) {
                            my $plant_stock_id = $new_stock_ids_hash{$_};
                            push @subplot_objects, { type_id => $plant_of_subplot_cvterm_id, subject_id => $plant_stock_id };
                        }
                    }

                    my $subplot = $stock_rs->create({
                        organism_id => $organism_id_checked,
                        name       => $subplot_name,
                        uniquename => $subplot_name,
                        type_id => $subplot_cvterm_id,
                        stockprops => \@subplot_stockprops,
                        stock_relationship_subjects => \@subplot_subjects,
                        stock_relationship_objects => \@subplot_objects,
                        nd_experiment_stocks => \@subplot_nd_experiment_stocks,
                    });
                    $new_stock_ids_hash{$subplot_name} = $subplot->stock_id();
                    $subplot_index_number++;

                }
            }
        }

        if (exists($design{treatments})){
            print STDERR "Saving treatments\n";
            while(my($treatment_name, $stock_names) = each(%{$design{treatments}})){

                my @treatment_nd_experiment_stocks;
                foreach (@$stock_names){
                    my $stock_id;
                    if (exists($new_stock_ids_hash{$_})){
                        $stock_id = $new_stock_ids_hash{$_};
                    } else {
                        $stock_id = $chado_schema->resultset("Stock::Stock")->find({uniquename=>$_})->stock_id();
                    }
                    push @treatment_nd_experiment_stocks, { type_id => $treatment_nd_experiment_type_id, stock_id => $stock_id };
                }

                my $nd_experiment = $chado_schema->resultset('NaturalDiversity::NdExperiment')->create({
                    nd_geolocation_id => $nd_geolocation_id,
                    type_id => $treatment_nd_experiment_type_id,
                    nd_experiment_stocks => \@treatment_nd_experiment_stocks
                });

                my @treatment_project_props = (
                    { type_id => $project_design_cvterm_id, value => 'treatment' }
                );

                if ($self->get_new_treatment_has_plant_entries){
                    push @treatment_project_props, { type_id => $has_plants_cvterm, value => $self->get_new_treatment_has_plant_entries };
                }
                if ($self->get_new_treatment_has_subplot_entries){
                    push @treatment_project_props, { type_id => $has_subplots_cvterm, value => $self->get_new_treatment_has_subplot_entries };
                }
                if ($self->get_new_treatment_has_tissue_sample_entries){
                    push @treatment_project_props, { type_id => $has_tissues_cvterm, value => $self->get_new_treatment_has_tissue_sample_entries };
                }
                if ($self->get_new_treatment_type){
                    push @treatment_project_props, { type_id => $management_factor_type_cvterm_id, value => $self->get_new_treatment_type };
                }
                if ($self->get_new_treatment_year){
                    push @treatment_project_props, { type_id => $management_factor_year_cvterm_id, value => $self->get_new_treatment_year };
                } else {
                    my $t = CXGN::Trial->new({
                        bcs_schema => $chado_schema,
                        trial_id => $self->get_trial_id
                    });
                    push @treatment_project_props, { type_id => $management_factor_year_cvterm_id, value => $t->get_year() };
                }

                my @treatment_nd_experiment_project = (
                    { nd_experiment_id => $nd_experiment->nd_experiment_id }
                );

                my @treatment_relationships = (
                    { type_id => $trial_treatment_relationship_cvterm_id, object_project_id => $self->get_trial_id }
                );

                #Create a project for each treatment_name
                my $project_treatment_name = $self->get_trial_name()."_".$treatment_name;
                my $treatment_project = $chado_schema->resultset('Project::Project')->create({
                    name => $project_treatment_name,
                    description => '',
                    projectprops => \@treatment_project_props,
                    project_relationship_subject_projects => \@treatment_relationships,
                    nd_experiment_projects => \@treatment_nd_experiment_project
                });

                if ($self->get_new_treatment_date()) {
                    my $management_factor_t = CXGN::Trial->new({
                        bcs_schema => $chado_schema,
                        trial_id => $treatment_project->project_id()
                    });
                    $management_factor_t->set_management_factor_date($self->get_new_treatment_date() );
                }
            }
        }

        print STDERR "Design Stored ".localtime."\n";
    };

    my $transaction_error;
    try {
        $chado_schema->txn_do($coderef);
    } catch {
        print STDERR "Transaction Error: $_\n";
        $transaction_error =  $_;
    };
    return $transaction_error;
}



1;


