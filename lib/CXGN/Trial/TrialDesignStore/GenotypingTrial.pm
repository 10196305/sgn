
package CXGN::Trial::TrialDesignStore::GenotypingTrial;

use Moose;

extends 'CXGN::Trial::TrialDesignStore::AbstractTrial';

sub validate_design {
    my $self = shift;

    print STDERR "validating design\n";

    my $chado_schema = $self->get_bcs_schema;
    my $design_type = $self->get_design_type;
    my %design = %{$self->get_design}; 
    my $error = '';

   if ($design_type ne 'genotyping_plate') {
        $error .= "is_genotyping is true; however design_type not equal to 'genotyping_plate'";
        return $error;
    }

    my @valid_properties = (
	'stock_name',
	'plot_name',
	'row_number',
	'col_number',
	'is_blank',
	'plot_number',
	'extraction',
	'dna_person',
	'concentration',
	'volume',
	'tissue_type',
	'notes',
	'acquisition_date',
	'ncbi_taxonomy_id'
        );
    #plot_name is tissue sample name in well. during store, the stock is saved as stock_type 'tissue_sample' with uniquename = plot_name

    
    my %allowed_properties = map {$_ => 1} @valid_properties;
    
    my %seen_stock_names;
    my %seen_source_names;
    my %seen_accession_names;
    foreach my $stock (keys %design){
        if ($stock eq 'treatments'){
            next;
        }
        foreach my $property (keys %{$design{$stock}}){
            if (!exists($allowed_properties{$property})) {
                $error .= "Property: $property not allowed! ";
            }
            if ($property eq 'stock_name') {
                my $stock_name = $design{$stock}->{$property};
                $seen_accession_names{$stock_name}++;
            }
            if ($property eq 'seedlot_name') {
                my $stock_name = $design{$stock}->{$property};
                if ($stock_name){
                    $seen_source_names{$stock_name}++;
                }
            }
            if ($property eq 'plot_name') {
                my $plot_name = $design{$stock}->{$property};
                $seen_stock_names{$plot_name}++;
            }
            if ($property eq 'plant_names') {
                my $plant_names = $design{$stock}->{$property};
                foreach (@$plant_names) {
                    $seen_stock_names{$_}++;
                }
            }
            if ($property eq 'subplots_names') {
                my $subplot_names = $design{$stock}->{$property};
                foreach (@$subplot_names) {
                    $seen_stock_names{$_}++;
                }
            }
        }
    }

    my @stock_names = keys %seen_stock_names;
    my @source_names = keys %seen_source_names;
    my @accession_names = keys %seen_accession_names;
    if(scalar(@stock_names)<1){
        $error .= "You cannot create a trial with less than one plot.";
    }
    #if(scalar(@source_names)<1){
    #	$error .= "You cannot create a trial with less than one seedlot.";
    #}
    if(scalar(@accession_names)<1){
        $error .= "You cannot create a trial with less than one accession.";
    }
    my $subplot_type_id = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'subplot', 'stock_type')->cvterm_id();
    my $accession_type_id = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'accession', 'stock_type')->cvterm_id();
    my $plot_type_id = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'plot', 'stock_type')->cvterm_id();
    my $plant_type_id = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'plant', 'stock_type')->cvterm_id();
    my $tissue_type_id = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'tissue_sample', 'stock_type')->cvterm_id();
    my $stocks = $chado_schema->resultset('Stock::Stock')->search({
        type_id=>$tissue_type_id,
        uniquename=>{-in=>\@stock_names}
    });
    while (my $s = $stocks->next()) {
        $error .= "Name $s->uniquename already exists in the database.";
    }

    # my $seedlot_validator = CXGN::List::Validate->new();
    # my @seedlots_missing = @{$seedlot_validator->validate($chado_schema,'seedlots',\@source_names)->{'missing'}};
    # if (scalar(@seedlots_missing) > 0) {
    #     $error .=  "The following seedlots are not in the database as uniquenames or synonyms: ".join(',',@seedlots_missing);
    # }

    my @source_stock_types = ($accession_type_id, $plot_type_id, $plant_type_id, $tissue_type_id);

    my $rs = $chado_schema->resultset('Stock::Stock')->search({
        'is_obsolete' => { '!=' => 't' },
        'type_id' => {-in=>\@source_stock_types},
        'uniquename' => {-in=>\@accession_names}
    });
    my %found_data;
    while (my $s = $rs->next()) {
        $found_data{$s->uniquename} = 1;
    }
    foreach (@accession_names){
        if (!$found_data{$_}){
            $error .= "The following name is not in the database: $_ .";
        }
    }

    return $error;
}


1;
