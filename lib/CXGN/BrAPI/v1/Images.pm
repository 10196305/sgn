package CXGN::BrAPI::v1::Images;

use Moose;
use Data::Dumper;
use File::Basename;
use File::Slurp qw | slurp |;
use Image::Size;
use SGN::Model::Cvterm;
use SGN::Image;
use CXGN::Image::Search;

extends 'CXGN::BrAPI::v1::Common';

sub search {
    my $self = shift;
    my $params = shift;
    my $page_size = $self->page_size;
    my $page = $self->page;
    my $status = $self->status;
    my @data_files;

    my $image_ids_arrayref = $params->{imageDbId} || ($params->{imageDbIds} || ());
    my $image_names_arrayref = $params->{imageName} || ($params->{imageNames} || ());
    my $stock_ids_arrayref = $params->{observationUnitDbId} || ($params->{observationUnitDbIds} || ());
    my $phenotype_ids_arrayref = $params->{observationDbId} || ($params->{observationDbIds} || ());
    my $descriptors_arrayref = $params->{descriptiveOntologyTerm} || ($params->{descriptiveOntologyTerms} || ());

    my $image_search = CXGN::Image::Search->new({
        bcs_schema=>$self->bcs_schema(),
        people_schema=>$self->people_schema(),
        phenome_schema=>$self->phenome_schema(),
        image_name_list=>$image_names_arrayref,
        original_filename_list=>$descriptors_arrayref,
        description_list=>$descriptors_arrayref,
        stock_name_list=>$stock_ids_arrayref,
        # still need to implement in the search
        # phenotype_id_list=>$phenotype_ids_arrayref,
        # image_id_list=>$image_ids_arrayref
    });
    my ($result, $total_count) = $image_search->search();

    my @data;
    foreach (@$result){
        #process results
    }

    my %result = (data => \@data);
    my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
    return CXGN::BrAPI::JSONResponse->return_success(\%result, $pagination, \@data_files, $status, 'Image-search result constructed');
}

sub detail {
    my $self = shift;
    my $inputs = shift;

    my $page_size = $self->page_size;
    my $page = $self->page;
    my $status = $self->status;

    my $image = SGN::Image->new($self->bcs_schema()->storage->dbh(), $inputs->{image_id});

    my $observation_unit_db_id;
    if (my @stocks = $image->get_stocks()) {
	       $observation_unit_db_id = $stocks[0]->stock_id();
    }

    my @descriptive_ontology_terms = $image->get_cvterms();

    my ($width, $height) = imgsize($image->get_filename());

     my %result = (
    	imageDbId => $image->get_image_id(),
    	imageName => $image->get_name(),
    	imageFilename => $image->get_original_filename(),
    	imageType => $image->get_file_ext(),
    	description => $image->get_description(),
    	imageURL => $image->get_image_url(),
    	observationUnitDbId => $observation_unit_db_id,
    	descriptiveOntologyTerms => \@descriptive_ontology_terms,
    	imageFileSize => stat(($image->get_filename())[7]),
    	imageWidth => $width,
    	imageHeight => $height,
	);

    my @data_files;
    my $total_count = 1;
    my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
    return CXGN::BrAPI::JSONResponse->return_success(\%result, $pagination, \@data_files, $status, 'Image detail constructed');
}

 sub image_metadata_store {
    my $self = shift;
    my $image_dir = shift;
    my $inputs = shift;

    print STDERR "inputs to image metadata store: ".Dumper($inputs);
    my $image = CXGN::Image->new(dbh=>$self->bcs_schema()->storage()->dbh(), image_dir => $image_dir);
    my $imageName = "";
    my $description = "";
    if (defined($inputs->{imageName})) { $imageName = $inputs->{imageName}->[0] }
    if (defined($inputs->{description})) { $description = $inputs->{description}->[0] }
    $image->set_name($imageName);
    $image->set_description($description);
    my $image_id = $image->store();

    my $pagination = CXGN::BrAPI::Pagination->pagination_response(1, 10, 0);
    return CXGN::BrAPI::JSONResponse->return_success( { image_id => $image_id }, $pagination, undef, $self->status());
}


 sub image_data_store {
    my $self = shift;
    my $image_dir = shift;
    my $image_id = shift;
    my $inputs = shift;

    print STDERR "Image ID: $image_id. inputs to image metadata store: ".Dumper($inputs);

    my $tempfile = $inputs->filename();

    print STDERR "TEMP FILE : $tempfile\n";

    # process image data through CXGN::Image...
    #
    my $image = CXGN::Image->new(dbh=>$self->bcs_schema()->storage()->dbh(), image_dir => $image_dir, image_id => $image_id);

    eval {
	       $image->process_image($tempfile);
    };

    if ($@) {
	       print STDERR "An error occurred during image processing... $@\n";
    }
    else {
	       print STDERR "Image processed successfully.\n";
    }

    my $pagination = CXGN::BrAPI::Pagination->pagination_response(1, 10, 0);
    return CXGN::BrAPI::JSONResponse->return_success( { image_id => $image_id }, $pagination, [], $self->status());
}

1;
