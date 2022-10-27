
package SGN::Controller::SimSearch;

use Moose;
use File::Temp "tempdir";
use File::Basename;

BEGIN { extends 'Catalyst::Controller'; }

sub simsearch : Path('/tools/simsearch') {
    my $self = shift;
    my $c = shift;

    $c->stash->{template} = '/tools/simsearch/index.mas';
}

sub upload_file : Path('/tools/simsearch/upload_file') {
    my $self = shift;
    my $c = shift;

    my $tempdir = $c->tempfiles_subdir("simsearch");
    my $tempfile = $c->tempfile( TEMPLATE => 'simsearch/simsearch-XXXXXX', UNLINK => 0 );

    
    my $upload = $c->request->upload('upload_vcf_file');

    my $filename = $upload->filename();
    
    print STDERR "UPLOAD FILENAME: $filename\n";

    my $tempname = $upload->tempname();
    print STDERR "TEMPNAME: $tempname\n";
    
    $c->stash->{filename} = $tempfile;
    $c->stash->{template} = '/tools/simsearch/upload_file.mas';

    my $simsearch_datadir = $c->config->{simsearch_datadir};

    print STDERR "SIMSEARCH DATADIR = $simsearch_datadir\n";

    $upload->copy_to($tempfile);
    
    my @files = glob "$simsearch_datadir/*";

    print STDERR "FILES: ".join(",",@files)."\n";

    
    
    my $pulldown = "<select id=\"reference_file\" >\n";
    foreach my $f (@files) {
	$pulldown .= "<option>".basename($f)."</option>";
    }
    $pulldown .="</select>";

    # -i required input file -r reference file (with -i only, input is also used as reference)
    # need to add a pull down with current genotypes for each protocol

    $c->stash->{reference_files_menu} = $pulldown;

}

sub process_file :Path('/tools/simsearch/process_file') :Args(0) {
    my $self = shift;
    my $c = shift;

    my $filename = $c->config->{basepath}."/".$c->req->param("filename");
    my $reference_file = $c->req->param("reference_file");

    my $reference_file_path = $c->config->{simsearch_datadir}."/".$reference_file;
    # do not specify -r option when there is no reference file
    #
    my $ref_option = "";
    if ($reference_file_path) {
	$ref_option = " -r $reference_file_path ";
    }
    
    my $cmd = "../gtsimsrch/src/simsearch -i $filename $ref_option -o $filename.out";

    print STDERR "running command $cmd...\n";
    system($cmd);


    system("perl ../gtsimsrch/src/agmr_cluster.pl < $filename.out > $filename.out.clusters");

    my $results;
    open(my $F , "<", $filename.".out.clusters") || die "Can't open file $filename.out";
    while(<$F>) {
	$results .= $_;
    }

    # plot the agmr score distribution histogram using the 6th column in $filename.out
    #
    # (use gnuplot or R)
    
    
    $c->res->body($results);
    
}

1;

