package CXGN::Genotype::ParseUpload::Plugin::IntertekCSV;

use Moose::Role;
use SGN::Model::Cvterm;
use Data::Dumper;
use Text::CSV;

# Check that all sample IDs are in the database already
sub _validate_with_plugin {
    my $self = shift;
    my $filename = $self->get_filename();
    my $marker_info_filename = $self->get_filename_intertek_marker_info();
    my $schema = $self->get_chado_schema();
    my %errors;
    my @error_messages;
    my %missing_accessions;

    my $csv = Text::CSV->new({ sep_char => ',' });

    my $F;

    # Open Marker Info File and get headers
    open($F, "<", $marker_info_filename) || die "Can't open file $marker_info_filename\n";

        my $header_row = <$F>;
        my @header_info;

        # Get first row, which is the header
        if ($csv->parse($header_row)) {
            @header_info = $csv->fields();
        }

    close($F);

    # Check that the columns in the marker info file are what we expect
    if ($header_info[0] ne 'IntertekSNPID'){
        push @error_messages, 'Column 1 header must be "IntertekSNPID" in the SNP Info File.';
    }
    if ($header_info[1] ne 'CustomerSNPID'){
        push @error_messages, 'Column 2 header must be "CustomerSNPID" in the SNP Info File.';
    }
    if ($header_info[2] ne 'Reference'){
        push @error_messages, 'Column 3 header must be "Reference" in the SNP Info File.';
    }
    if ($header_info[3] ne 'Alternate'){
        push @error_messages, 'Column 4 header must be "Alternate" in the SNP Info File.';
    }
    if ($header_info[4] ne 'Chromosome'){
        push @error_messages, 'Column 5 header must be "Chromosome" in the SNP Info File.';
    }
    if ($header_info[5] ne 'Position'){
        push @error_messages, 'Column 6 header must be "Position" in the SNP Info File.';
    }
    if ($header_info[6] ne 'Quality'){
        push @error_messages, 'Column 7 header must be "Quality" in the SNP Info File.';
    }
    if ($header_info[7] ne 'Filter'){
        push @error_messages, 'Column 8 header must be "Filter" in the SNP Info File.';
    }
    if ($header_info[8] ne 'Info'){
        push @error_messages, 'Column 9 header must be "Info" in the SNP Info File.';
    }
    if ($header_info[9] ne 'Format'){
        push @error_messages, 'Column 10 header must be "Format" in the SNP Info File.';
    }

    # Open GRID FILE and parse
    open($F, "<", $filename) || die "Can't open file $filename\n";

        $header_row = <$F>;
        @header_info;

        # Get first row, which is the header
        if ($csv->parse($header_row)) {
            @header_info = $csv->fields();
        }

        # Remove the first column from the header
        my $unneeded_first_column = shift @header_info;
        my @fields = ($unneeded_first_column);
        my @markers = @header_info;

        my @observation_unit_names;
        # Iterate over all rows to get the sample ID and labID
        while (my $line = <$F>) {
            my @line_info;
            if ($csv->parse($line)) {
                @line_info = $csv->fields();
            }
            my $sample_name = $line_info[0];
            chomp $sample_name;
            $sample_name =~ s/^\s+|\s+$//g;
            push @observation_unit_names, $sample_name;
        }

    close($F);
    print STDERR Dumper \@observation_unit_names;

    # Check that the first column in the header is equal to 'SampleName.LabID'
    if ($fields[0] ne 'SampleName.LabID'){
        push @error_messages, 'Column 1 header must be "SampleName.LabID" in the Grid File.';
    }

    my $number_observation_units = scalar(@observation_unit_names);
    print STDERR "Number observation units: $number_observation_units...\n";

    my @observation_units_names_trim;
    # Separates sample name from lab id
    foreach (@observation_unit_names) {
        my ($observation_unit_name_with_accession_name, $lab_id) = split(/\./, $_);
        $observation_unit_name_with_accession_name =~ s/^\s+|\s+$//g;
        my ($observation_unit_name, $accession_name) = split(/\|\|\|/, $observation_unit_name_with_accession_name);
        push @observation_units_names_trim, $observation_unit_name;
    }
    my $observation_unit_names = \@observation_units_names_trim;
    print STDERR Dumper $observation_unit_names;

    my $organism_id = $self->get_organism_id;
    my $accession_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'accession', 'stock_type')->cvterm_id();

    # Validate that the sample names are in the database already
    my $stock_type = $self->get_observation_unit_type_name;
    my @missing_stocks;
    my $validator = CXGN::List::Validate->new();
    if ($stock_type eq 'tissue_sample'){
        @missing_stocks = @{$validator->validate($schema,'tissue_samples',$observation_unit_names)->{'missing'}};
    } elsif ($stock_type eq 'accession'){
        @missing_stocks = @{$validator->validate($schema,'accessions',$observation_unit_names)->{'missing'}};
    } else {
        push @error_messages, "You can only upload genotype data for a tissue_sample OR accession (including synonyms)!"
    }

    my %unique_stocks;
    foreach (@missing_stocks){
        $unique_stocks{$_}++;
    }

    @missing_stocks = sort keys %unique_stocks;
    my @missing_stocks_return;
    # Optionally the missing sample ids can be created in the database as new accessions, but that is not recommended 
    foreach (@missing_stocks){
        if (!$self->get_create_missing_observation_units_as_accessions){
            push @missing_stocks_return, $_;
            print STDERR "WARNING! Observation unit name $_ not found for stock type $stock_type. You can pass an option to automatically create accessions.\n";
        } else {
            my $stock = $schema->resultset("Stock::Stock")->create({
                organism_id => $organism_id,
                name       => $_,
                uniquename => $_,
                type_id     => $accession_cvterm_id,
            });
        }
    }

    # If there are missing sample names, they will be returned along with an error message
    if (scalar(@missing_stocks_return)>0){
        $errors{'missing_stocks'} = \@missing_stocks_return;
        push @error_messages, "The following stocks are not in the database: ".join(',',@missing_stocks_return);
    }

    #store any errors found in the parsed file to parse_errors accessor
    if (scalar(@error_messages) >= 1) {
        $errors{'error_messages'} = \@error_messages;
        $self->_set_parse_errors(\%errors);
        return;
    }

    return 1; #returns true if validation is passed
}

# After validation, the file data is actually parsed into the expected object
sub _parse_with_plugin {
    my $self = shift;
    my $filename = $self->get_filename();
    my $marker_info_filename = $self->get_filename_intertek_marker_info();
    my $schema = $self->get_chado_schema();
    my $stock_type = $self->get_observation_unit_type_name;

    print STDERR "Reading VCF to parse\n";

    my %protocolprop_info;
    $protocolprop_info{'header_information_lines'} = [];
    $protocolprop_info{'sample_observation_unit_type_name'} = $stock_type;

    my $csv = Text::CSV->new({ sep_char => ',' });

    my $F;
    # Open Marker Info File and parse into the %marker_info for later use
    open($F, "<", $marker_info_filename) || die "Can't open file $marker_info_filename\n";

        my $header_row = <$F>;
        my @header_info;

        # Get first row, which is the header
        if ($csv->parse($header_row)) {
            @header_info = $csv->fields();
        }

        my %marker_info;
        my %marker_info_lookup;
        # Iterate over all rows to get all the marker's info
        while (my $line = <$F>) {
            my @line_info;
            if ($csv->parse($line)) {
                @line_info = $csv->fields();
            }
            my $intertek_snp_id = $line_info[0];
            my $customer_snp_id = $line_info[1];
            my $ref = $line_info[2];
            my $alt = $line_info[3];
            my $chromosome = $line_info[4];
            my $position = $line_info[5];
            my $quality = $line_info[6];
            my $filter = $line_info[7];
            my $info = $line_info[8];
            my $format = $line_info[9];
            my %marker = (
                ref => $ref,
                alt => $alt,
                intertek_name => $intertek_snp_id,
                chrom => $chromosome,
                pos => $position,
                name => $customer_snp_id,
                qual => $quality,
                filter => $filter,
                info => $info,
                format => $format,
            );
            push @{$protocolprop_info{'marker_names'}}, $customer_snp_id;
            push @{$protocolprop_info{'markers_array'}}, \%marker;

            $marker_info{$customer_snp_id} = \%marker;
            $marker_info_lookup{$intertek_snp_id} = \%marker;
        }

    close($F);
    print STDERR Dumper \%marker_info_lookup;
    $protocolprop_info{'markers'} = \%marker_info;

    # Open GRID FILE and parse
    open($F, "<", $filename) || die "Can't open file $filename\n";

        $header_row = <$F>;
        @header_info;

        # Get first row, which is the header
        if ($csv->parse($header_row)) {
            @header_info = $csv->fields();
        }

        # Remove the first column from the header
        my $unneeded_first_column = shift @header_info;
        my @fields = ($unneeded_first_column);
        my @markers = @header_info;

        my %genotype_info;
        my @observation_unit_names;
        # Iterate over all rows in file
        while (my $line = <$F>) {
            my @line_info;
            if ($csv->parse($line)) {
                @line_info = $csv->fields();
            }

            # Get sample id and collect then in an array
            my $sample_id_with_lab_id = shift @line_info;
            chomp $sample_id_with_lab_id;
            $sample_id_with_lab_id =~ s/^\s+|\s+$//g;
            push @observation_unit_names, $sample_id_with_lab_id;

            my $counter = 0;
            foreach my $intertek_snp_id (@markers){
                my $genotype = $line_info[$counter];
                $counter++;
                my @alleles = split ":", $genotype;
                #print STDERR Dumper \@alleles;
                #print STDERR Dumper $marker_info_lookup{$intertek_snp_id};

                my $ref = $marker_info_lookup{$intertek_snp_id}->{ref};
                my $alt = $marker_info_lookup{$intertek_snp_id}->{alt};
                my $marker_name = $marker_info_lookup{$intertek_snp_id}->{name};

                my @vcf_genotype; # should look like the vcf genotype call e.g. 0/1 or 0/0 or ./. or missing data
                foreach my $a (@alleles){
                    if ($a eq $ref) {
                        push @vcf_genotype, '0';
                    }
                    if ($a eq $alt) {
                        push @vcf_genotype, '1';
                    }
                }
                my $vcf_genotype_string = join '/', @vcf_genotype;

                $genotype_info{$sample_id_with_lab_id}->{$marker_name} = { 'GT' => $vcf_genotype_string };
            }
        }

    close($F);

    my %parsed_data = (
        protocol_info => \%protocolprop_info,
        genotypes_info => \%genotype_info,
        observation_unit_uniquenames => \@observation_unit_names
    );

    $self->_set_parsed_data(\%parsed_data);

    return 1;
}

1;
