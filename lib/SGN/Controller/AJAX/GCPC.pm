use strict;

package SGN::Controller::AJAX::GCPC;

use Moose;
use Data::Dumper;
use File::Temp qw | tempfile |;
use File::Slurp;
use File::Spec qw | catfile|;
use File::Basename qw | basename |;
use File::Copy;
use CXGN::Dataset;
use CXGN::Dataset::File;
use CXGN::Tools::Run;
use CXGN::Page::UserPrefs;
use CXGN::Tools::List qw/distinct evens/;
use CXGN::Blast::Parse;
use CXGN::Blast::SeqQuery;
use Cwd qw(cwd);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON' },
    );


sub shared_phenotypes: Path('/ajax/gcpc/shared_phenotypes') : {
    my $self = shift;
    my $c = shift;
    my $dataset_id = $c->req->param('dataset_id');
    my $people_schema = $c->dbic_schema("CXGN::People::Schema");
    my $schema = $c->dbic_schema("Bio::Chado::Schema", "sgn_chado");
    my $ds = CXGN::Dataset->new(people_schema => $people_schema, schema => $schema, sp_dataset_id => $dataset_id);
    my $traits = $ds->retrieve_traits();
    
    $c->tempfiles_subdir("gcpc_files");
    my ($fh, $tempfile) = $c->tempfile(TEMPLATE=>"gcpc_files/trait_XXXXX");
    $people_schema = $c->dbic_schema("CXGN::People::Schema");
    $schema = $c->dbic_schema("Bio::Chado::Schema", "sgn_chado");
    my $temppath = $c->config->{basepath}."/".$tempfile;
    my $ds2 = CXGN::Dataset::File->new(people_schema => $people_schema, schema => $schema, sp_dataset_id => $dataset_id, file_name => $temppath, quotes => 0);
    my $phenotype_data_ref = $ds2->retrieve_phenotypes();

    print STDERR Dumper($traits);
    $c->stash->{rest} = {
        options => $traits,
        tempfile => $tempfile."_phenotype.txt",
#        tempfile => $file_response,
    };
}

my $method_id;
sub get_method: Path('/ajax/gcpc/get_method') : {
    my $self = shift;
    my $c = shift;
    my $method_1 = $c->req->param('method_id');
    print STDERR Dumper($method_1);
    $method_id = $method_1;
    print "The vairable method_id is $method_id \n";
}


sub extract_trait_data :Path('/ajax/gcpc/getdata') Args(0) {
    my $self = shift;
    my $c = shift;

    my $file = $c->req->param("file");
    my $trait = $c->req->param("trait");

    $file = basename($file);

    my $temppath = File::Spec->catfile($c->config->{basepath}, "static/documents/tempfiles/gcpc_files/".$file);
    print STDERR Dumper($temppath);

    my $F;
    if (! open($F, "<", $temppath)) {
	$c->stash->{rest} = { error => "Can't find data." };
	return;
    }
    
    
    open(my $G, ">", $temppath.".hmp") || die "Can't open $temppath.hmp"; 
    
    my $header = <$F>;
    chomp($header);
    print STDERR Dumper($header);
    my @keys = split("\t", $header);
    print STDERR Dumper($keys[1]);
    for(my $n=0; $n <@keys; $n++) {
        if ($keys[$n] =~ /\|CO\_/) {
        $keys[$n] =~ s/\|CO\_.*//;
        }
    }
    my @data = ();

    my %nuconv = (
	'A/A' => 'A',
	'G/G' => 'G',
	'T/T' => 'T',
	'C/C' => 'C',
	'A/G' => 'R',
	'G/A' => 'R',
	'C/T' => 'Y',
	'T/C' => 'Y',
	'G/C' => 'S',
	'C/G' => 'S',
	'A/T' => 'W',
	'T/A' => 'W',
	'G/T' => 'K',
	'T/G' => 'K',
	'A/C' => 'M',
	'C/A' => 'M',
	'./.' => 'N',
	);

	

    while (<$F>) {
	chomp;
	my %line;    
	my @fields = split /\t/;

	for(my $n=0; $n <@keys; $n++) {
	    if (exists($fields[$n]) && defined($fields[$n])) {
		$line{$keys[$n]}=$fields[$n];
	    }
	}
	push @data, \%line;
    }

    print STDERR Dumper(\%line);

    foreach my $line (@data) {
	my @formats = split /\:/, $line->{FORMAT};
	my $gtindex = 0;
	for(my $n =0; $n<@formats; $n++) {
	    if ($format[$n] eq 'GT') {
		$gtindex=$n;
	    }
	}

	for(my $gt = 0; $gt < @keys; $gt++) {
	    my @scores = split /\:/, $fields[$gt];
	    my $genotype;
	    if ($scores[$gtindex] eq '0/0') {
		$genotype = $line->{REF}."/".$line->{REF};
	    }
	    if ($scores[$gtindex] eq '0/1') {
		$genotype = $line->{REF}."/".$line->{ALT};
	    }
	    if ($scores[$gtindex] eq '1/1') {
		$genotype = $line->{ALT}."/".$line->{ALT};
	    }

	    my $genotype_hmp = $nuconv{$genotype};
	}
	
	print $G $line->{ID}."\n";
    
    }
    $c->stash->{rest} = { data => \@data, trait => $trait};
}

sub generate_results: Path('/ajax/gcpc/generate_results') : {
    my $self = shift;
    my $c = shift;
    my $dataset_id = $c->req->param('dataset_id');
    #my $method = $c->req->param('method_id');
    my $trait_id = $c->req->param('trait_id');
    
    print STDERR "DATASET_ID: $dataset_id\n";
    print STDERR "TRAIT ID: $trait_id\n";
    #print STDERR "Method: ".Dumper($method);

    $c->tempfiles_subdir("gcpc_files");
    my $gcpc_tmp_output = $c->config->{cluster_shared_tempdir}."/gcpc_files";
    mkdir $gcpc_tmp_output if ! -d $gcpc_tmp_output;
    my ($tmp_fh, $tempfile) = tempfile(
      "gcpc_download_XXXXX",
      DIR=> $gcpc_tmp_output,
    );

    my $pheno_filepath = $tempfile . "_phenotype.txt";
    my $geno_filepath  = $tempfile . "_genotype.txt";
    
    my $people_schema = $c->dbic_schema("CXGN::People::Schema");
    my $schema = $c->dbic_schema("Bio::Chado::Schema", "sgn_chado");

    #my $temppath = $stability_tmp_output . "/" . $tempfile;
    my $temppath =  $tempfile;

    my $ds = CXGN::Dataset::File->new(people_schema => $people_schema, schema => $schema, sp_dataset_id => $dataset_id, file_name => $temppath, quotes => 0);

    my $phenotype_data_ref = $ds->retrieve_phenotypes($pheno_filepath);

    my $newtrait = $trait_id;
    $newtrait =~ s/\s/\_/g;
    $newtrait =~ s/\//\_/g;
    $trait_id =~ tr/ /./;
    $trait_id =~ tr/\//./;

    my $genotype_data_ref = $ds->retrieve_genotypes($geno_filepath);

    open(my $F, "<", $geno_filepath) || die "Can't open file $geno_filepath\n";
    open(my $G, ">", $geno_filepath.".hmp") || die "Can't open ".$geno_filepath.".hmp for writing\n";


	 
	 
    #CHROM POS ID REF ALT QUAL FILTER INFO FORMAT
    while(my $line = <$F>) { 
	chomp($line);

	if ($line =~ m/^\#\#/) {
	    next();
	}

	if ($line =~ m/\#CHROM/) {
	    my($chrom_header, $pos_header, $id_header, $ref_header, $alt_header, $qual_header, $filter_header, $info_header, $format_header, @genotype_ids) = split /\t/, $line;
	    
	    print $G join("\t", (qw | rs allels chrom pos strand assembly center protLSID assayLSID panelLSID QCcode |, @genotype_ids))."\n";
	}

	else { 
	    my($chrom, $pos, $id, $ref, $alt, $qual, $filter, $info, $format, @genotypes) = split /\t/, $line;
	    
	    my @formats = split /\:/, $format;
	    
	    my $gt_index = -1;
	    for(my $n=0; $n++; $n<@formats) {
		if ($n eq "GT") {
		    $gt_index = $n;
		}
	    }
	    if ($gt_index == -1) { die "Can't find GT for line with id $id.\n"; }
	    
	    print $G join("\t", ($chrom."_".$pos, $ref."/".$alt, $chrom, $pos, '+', 'NA', 'NA', 'NA'))."\n";
	}
    }

    
    my $AMMIFile = $tempfile . "_" . "AMMIFile.png";
    my $figure1file = $tempfile . "_" . "figure1.png";
    my $figure2file = $tempfile . "_" . "figure2.png";

    $trait_id =~ tr/ /./;
    $trait_id =~ tr/\//./;

    my $cmd = CXGN::Tools::Run->new({
            backend => $c->config->{backend},
            submit_host=>$c->config->{cluster_host},
            temp_base => $c->config->{cluster_shared_tempdir} . "/gcpc_files",
            queue => $c->config->{'web_cluster_queue'},
            do_cleanup => 0,
            # don't block and wait if the cluster looks full
            max_cluster_jobs => 1_000_000_000,
        });

    $cmd->run_cluster(
            "Rscript ",
            $c->config->{basepath} . "/R/gcpc/run_gcpc.R",
	$pheno_filepath,
	$geno_filepath,
            $trait_id,
            $figure1file,
            $figure2file,
            $AMMIFile,
            #$method
    );

    while ($cmd->alive) { 
	sleep(1);
    }

    my $error;

    if (! -e $AMMIFile) { 
	$error = "The analysis could not be completed. The factors may not have sufficient numbers of levels to complete the analysis. Please choose other parameters."
    }

    my $figure_path = $c->config->{basepath} . "/static/documents/tempfiles/stability_files/";

    copy($AMMIFile, $figure_path);
    copy($figure1file, $figure_path);
    copy($figure2file, $figure_path);

    my $AMMIFilebasename = basename($AMMIFile);
    my $AMMIFile_response = "/documents/tempfiles/stability_files/" . $AMMIFilebasename;
    
    my $figure1basename = basename($figure1file);
    my $figure1_response = "/documents/tempfiles/stability_files/" . $figure1basename;
    
    my $figure2basename = basename($figure2file);
    my $figure2_response = "/documents/tempfiles/stability_files/" . $figure2basename;
        
    $c->stash->{rest} = {
        AMMITable => $AMMIFile_response,
        figure1 => $figure1_response,
        figure2 => $figure2_response,
        dummy_response => $dataset_id
        # dummy_response2 => $trait_id,
    };
}

1

