package CXGN::Stock::Seedlot::ParseUpload::Plugin::SeedlotXLS;

use Moose::Role;
use Spreadsheet::ParseExcel;
use CXGN::Stock::StockLookup;
use SGN::Model::Cvterm;
use Data::Dumper;
use CXGN::List::Validate;

sub _validate_with_plugin {
    my $self = shift;

    my $filename = $self->get_filename();
    my $schema = $self->get_chado_schema();
    my $parser = Spreadsheet::ParseExcel->new();
    my @error_messages;
    my %errors;
    my %missing_accessions;

    #try to open the excel file and report any errors
    my $excel_obj = $parser->parse($filename);
    if (!$excel_obj) {
        push @error_messages, $parser->error();
        $errors{'error_messages'} = \@error_messages;
        $self->_set_parse_errors(\%errors);
        return;
    }

    my $worksheet = ( $excel_obj->worksheets() )[0]; #support only one worksheet
    if (!$worksheet) {
        push @error_messages, "Spreadsheet must be on 1st tab in Excel (.xls) file";
        $errors{'error_messages'} = \@error_messages;
        $self->_set_parse_errors(\%errors);
        return;
    }
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();
    if (($col_max - $col_min)  < 2 || ($row_max - $row_min) < 1 ) { #must have header and at least one row of plot data
        push @error_messages, "Spreadsheet is missing header or contains no rows";
        $errors{'error_messages'} = \@error_messages;
        $self->_set_parse_errors(\%errors);
        return;
    }

    #get column headers
    my $seedlot_name_head;
    my $contents_head;
    my $source_head;
    my $operator_name_head;
    my $amount_head;
    my $weight_head;
    my $description_head;
    my $box_name_head;

    if ($worksheet->get_cell(0,0)) {
        $seedlot_name_head  = $worksheet->get_cell(0,0)->value();
    }
    if ($worksheet->get_cell(0,1)) {
        $contents_head  = $worksheet->get_cell(0,1)->value();
    }
    if ($worksheet->get_cell(0,2)) {
        $source_head  = $worksheet->get_cell(0,2)->value();
    }
    if ($worksheet->get_cell(0,3)) {
        $operator_name_head  = $worksheet->get_cell(0,3)->value();
    }
    if ($worksheet->get_cell(0,4)) {
        $amount_head  = $worksheet->get_cell(0,4)->value();
    }
    if ($worksheet->get_cell(0,5)) {
        $weight_head  = $worksheet->get_cell(0,5)->value();
    }
    if ($worksheet->get_cell(0,6)) {
        $description_head  = $worksheet->get_cell(0,6)->value();
    }
    if ($worksheet->get_cell(0,7)) {
        $box_name_head  = $worksheet->get_cell(0,7)->value();
    }

    if (!$seedlot_name_head || $seedlot_name_head ne 'seedlot_name' ) {
        push @error_messages, "Cell A1: seedlot_name is missing from the header";
    }
    if (!$contents_head || $contents_head ne 'contents') {
        push @error_messages, "Cell B1: contents is missing from the header";
    }
    if (!$source_head || $source_head ne 'source') {
        push @error_messages, "Cell C1: source is missing from the header";
    }
    if (!$operator_name_head || $operator_name_head ne 'operator_name') {
        push @error_messages, "Cell D1: operator_name is missing from the header";
    }
    if (!$amount_head || $amount_head ne 'amount') {
        push @error_messages, "Cell E1: amount is missing from the header";
    }
    if (!$weight_head || $weight_head ne 'weight(g)') {
        push @error_messages, "Cell F1: weight(g) is missing from the header";
    }
    if (!$description_head || $description_head ne 'description') {
        push @error_messages, "Cell G1: description is missing from the header";
    }
    if (!$box_name_head || $box_name_head ne 'box_name') {
        push @error_messages, "Cell H1: box_name is missing from the header";
    }

    my %seen_seedlot_names;
    my %seen_contents;
    my %seen_sources;
    for my $row ( 1 .. $row_max ) {
        my $row_name = $row+1;
        my $seedlot_name;
        my $contents;
        my $source;
        my $operator_name;
        my $amount = 'NA';
        my $weight = 'NA';
        my $description;
        my $box_name;

        if ($worksheet->get_cell($row,0)) {
            $seedlot_name = $worksheet->get_cell($row,0)->value();
        }
        if ($worksheet->get_cell($row,1)) {
            $contents = $worksheet->get_cell($row,1)->value();
        }
        if ($worksheet->get_cell($row,2)) {
            $source = $worksheet->get_cell($row,2)->value();
        }
        if ($worksheet->get_cell($row,3)) {
            $operator_name = $worksheet->get_cell($row,3)->value();
        }
        if ($worksheet->get_cell($row,4)) {
            $amount =  $worksheet->get_cell($row,4)->value();
        }
        if ($worksheet->get_cell($row,5)) {
            $weight =  $worksheet->get_cell($row,5)->value();
        }
        if ($worksheet->get_cell($row,6)) {
            $description =  $worksheet->get_cell($row,6)->value();
        }
        if ($worksheet->get_cell($row,7)) {
            $box_name =  $worksheet->get_cell($row,7)->value();
        }

        if (!$seedlot_name || $seedlot_name eq '' ) {
            push @error_messages, "Cell A$row_name: seedlot_name missing.";
        }
        elsif ($seedlot_name =~ /\s/ || $seedlot_name =~ /\// || $seedlot_name =~ /\\/ ) {
            push @error_messages, "Cell A$row_name: seedlot_name must not contain spaces or slashes.";
        }
        else {
            #file must not contain duplicate plot names
            if ($seen_seedlot_names{$seedlot_name}) {
                push @error_messages, "Cell A$row_name: duplicate seedlot_name at cell A".$seen_seedlot_names{$seedlot_name}.": $seedlot_name";
            }
            $seedlot_name =~ s/^\s+|\s+$//g; #trim whitespace from front and end...
            $seen_seedlot_names{$seedlot_name}=$row_name;
        }

        if (!$contents || $contents eq '') {
            push @error_messages, "Cell B:$row_name: you must provide an accession_name for the contents of the seedlot.";
        } else {
            if ($contents){
                $contents =~ s/^\s+|\s+$//g; #trim whitespace from front and end...
                $seen_contents{$contents}++;
            }
        }

        if ($source) {
            $seen_sources{$source}++;
        }

        if (!defined($operator_name) || $operator_name eq '') {
            push @error_messages, "Cell D$row_name: operator_name missing";
        }

        if (!defined($amount) || $amount eq '') {
            push @error_messages, "Cell E$row_name: amount missing";
        }
        if (!defined($weight) || $weight eq '') {
            push @error_messages, "Cell F$row_name: weight(g) missing";
        }
        if ($amount eq 'NA' && $weight eq 'NA') {
            push @error_messages, "On row:$row_name you must provide either a weight in grams or a seed count amount.";
        }

        if (!defined($box_name) || $box_name eq '') {
            push @error_messages, "Cell H$row_name: box_name missing";
        }
    }

    my $validator = CXGN::List::Validate->new();

    my @accessions = keys %seen_contents;
    my @accessions_missing = @{$validator->validate($schema,'accessions',\@accessions)->{'missing'}};

    if (scalar(@accessions_missing) > 0) {
        push @error_messages, "The following accessions are not in the database as uniquenames or synonyms: ".join(',',@accessions_missing);
        $errors{'missing_accessions'} = \@accessions_missing;
    }

    # Should be more specific than stock . . . tangible_stocks? observation_units?
    my @tangible_stocks = keys %seen_sources;
    my @tangible_stocks_missing = @{$validator->validate($schema,'tangible_stocks',\@tangible_stocks)->{'missing'}};

    if (scalar(@tangible_stocks_missing) > 0) {
        push @error_messages, "The following sources are not in the database as stock uniquenames or synonyms: ".join(',',@tangible_stocks_missing);
        $errors{'missing_sources'} = \@tangible_stocks_missing;
    }

    # Not checking if seedlot name already exists because the database will just update the seedlot entries
    # my @seedlots = keys %seen_seedlot_names;
    # my $rs = $schema->resultset("Stock::Stock")->search({
    #     'is_obsolete' => { '!=' => 't' },
    #     'uniquename' => { -in => \@seedlots }
    # });
    # while (my $r=$rs->next){
    #     push @error_messages, "Cell A".$seen_seedlot_names{$r->uniquename}.": seedlot name already exists in database: ".$r->uniquename;
    # }

    #store any errors found in the parsed file to parse_errors accessor
    if (scalar(@error_messages) >= 1) {
        $errors{'error_messages'} = \@error_messages;
        $self->_set_parse_errors(\%errors);
        return;
    }

    return 1; #returns true if validation is passed
}


sub _parse_with_plugin {
    my $self = shift;
    my $filename = $self->get_filename();
    my $schema = $self->get_chado_schema();
    my $parser   = Spreadsheet::ParseExcel->new();
    my $excel_obj;
    my $worksheet;
    my %parsed_seedlots;

    $excel_obj = $parser->parse($filename);
    if ( !$excel_obj ) {
        return;
    }

    $worksheet = ( $excel_obj->worksheets() )[0];
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();

    my %seen_seedlot_names;
    my %seen_contents;
    for my $row ( 1 .. $row_max ) {
        my $seedlot_name;
        my $contents;
        my $source;
        if ($worksheet->get_cell($row,0)) {
            $seedlot_name = $worksheet->get_cell($row,0)->value();
            $seedlot_name =~ s/^\s+|\s+$//g; #trim whitespace from front and end...
            $seen_seedlot_names{$seedlot_name}++;
        }
        if ($worksheet->get_cell($row,1)) {
            $contents = $worksheet->get_cell($row,1)->value();
            $contents =~ s/^\s+|\s+$//g; #trim whitespace from front and end...
            $seen_contents{$contents}++;
        }
        if ($worksheet->get_cell($row,2)) {
            $source = $worksheet->get_cell($row,2)->value();
            $source =~ s/^\s+|\s+$//g; #trim whitespace from front and end...
            $seen_sources{$source}++;
        }

    }
    my $accession_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'accession', 'stock_type')->cvterm_id();
    my $seedlot_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'seedlot', 'stock_type')->cvterm_id();
    my $synonym_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'stock_synonym', 'stock_property')->cvterm_id();

    my @accessions = keys %seen_contents;
    my $rs = $schema->resultset("Stock::Stock")->search({
        'is_obsolete' => { '!=' => 't' },
        'uniquename' => { -in => \@accessions },
        'type_id' => $accession_cvterm_id,
    });
    my %accession_lookup;
    while (my $r=$rs->next){
        $accession_lookup{$r->uniquename} = $r->stock_id;
    }
    my $acc_synonym_rs = $schema->resultset("Stock::Stock")->search({
        'me.is_obsolete' => { '!=' => 't' },
        'stockprops.value' => { -in => \@accessions},
        'me.type_id' => $accession_cvterm_id,
        'stockprops.type_id' => $synonym_cvterm_id
    },{join => 'stockprops', '+select'=>['stockprops.value'], '+as'=>['synonym']});
    my %acc_synonyms_lookup;
    while (my $r=$acc_synonym_rs->next){
        $acc_synonyms_lookup{$r->get_column('synonym')}->{$r->uniquename} = $r->stock_id;
    }

    my @seedlots = keys %seen_seedlot_names;
    my $seedlot_rs = $schema->resultset("Stock::Stock")->search({
        'is_obsolete' => { '!=' => 't' },
        'uniquename' => { -in => \@seedlots },
        'type_id' => $seedlot_cvterm_id
    });
    my %seedlot_lookup;
    while (my $r=$seedlot_rs->next){
        $seedlot_lookup{$r->uniquename} = $r->stock_id;
    }

    # Do tangible_stock/observation_unit lookup for source

    for my $row ( 1 .. $row_max ) {
        my $seedlot_name;
        my $contents;
        my $source;
        my $operator_name;
        my $amount = 'NA';
        my $weight = 'NA';
        my $description;
        my $box_name;

        if ($worksheet->get_cell($row,0)) {
            $seedlot_name = $worksheet->get_cell($row,0)->value();
        }
        if ($worksheet->get_cell($row,1)) {
            $contents = $worksheet->get_cell($row,1)->value();
        }
        if ($worksheet->get_cell($row,2)) {
            $source =  $worksheet->get_cell($row,2)->value();
        }
        if ($worksheet->get_cell($row,3)) {
            $operator_name =  $worksheet->get_cell($row,3)->value();
        }
        if ($worksheet->get_cell($row,4)) {
            $amount =  $worksheet->get_cell($row,4)->value();
        }
        if ($worksheet->get_cell($row,5)) {
            $weight =  $worksheet->get_cell($row,5)->value();
        }
        if ($worksheet->get_cell($row,6)) {
            $description =  $worksheet->get_cell($row,6)->value();
        }
        if ($worksheet->get_cell($row,7)) {
            $box_name =  $worksheet->get_cell($row,7)->value();
        }

        $seedlot_name =~ s/^\s+|\s+$//g; #trim whitespace from front and end...
        $contents =~ s/^\s+|\s+$//g; #trim whitespace from front and end...

        #skip blank lines
        if (!$seedlot_name && !$contents && !$description) {
            next;
        }

        my $accession_stock_id;
        if ($acc_synonyms_lookup{$contents}){
            my @accession_names = keys %{$acc_synonyms_lookup{$contents}};
            if (scalar(@accession_names)>1){
                print STDERR "There is more than one uniquename for this synonym $accession_name. this should not happen!\n";
            }
            $accession_stock_id = $acc_synonyms_lookup{$contents}->{$accession_names[0]};
            $contents = $accession_names[0];
        } else {
            $accession_stock_id = $accession_lookup{$contents};
        }

        $parsed_seedlots{$seedlot_name} = {
            seedlot_id => $seedlot_lookup{$seedlot_name}, #If seedlot name already exists, this will allow us to update information for the seedlot
            contents => $contents,
            source => $source,
            accession_stock_id => $accession_stock_id,
            cross_name => undef,
            cross_stock_id => undef,
            amount => $amount,
            weight_gram => $weight,
            description => $description,
            box_name => $box_name,
            operator_name => $operator_name
        };
    }
    #print STDERR Dumper \%parsed_seedlots;

    $self->_set_parsed_data(\%parsed_seedlots);
    return 1;
}


1;
