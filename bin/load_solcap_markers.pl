 #!/usr/bin/perl

# basic script to load pcr marker information


# usage: load_marker_data.pl -H hostname D dbname  -i infile 

# copy and edit this file as necessary
# common changes include the following:
# experiment_type_id
# accession_id
# different column headings

=head1

 NAME

load_solcap_markers.pl - a script to load markers into the SGN database.

=head1 DESCRIPTION

usage: load_solcap_markers.pl

Options:

=over 5

=item -H

The hostname of the server hosting the database.

=item -D

the name of the database

=item -t

(optional) test mode. Rollback after the script terminates. Database should not be affected. Good for test runs.

=item p

protocol (e.g. SSR, SNP, Indel, dCAPs, etc)

=item -i

infile with the marker info



=back

The tab-delimited map file has the following columns:

 Marker
 Temp (annealing temperature)
 fwd (forward primer)
 rev (reverse primer)



=head1 AUTHORS

Naama Menda <nm249@cornell.edu>


=cut

use strict;

use CXGN::Tools::File::Spreadsheet;
use CXGN::Tools::Text;
use CXGN::Marker::Modifiable;
use CXGN::Marker::Tools;
use CXGN::Marker::Location;
use CXGN::Marker::PCR::Experiment;
use CXGN::Map::Version;
use CXGN::DB::Connection;
use CXGN::DB::InsertDBH;
use Data::Dumper;

use Getopt::Std;


our ($opt_H, $opt_D, $opt_i, $opt_t, $opt_p);

getopts('H:D:i:tp:');


my ($map_id, $map_file);

 my $dbh = CXGN::DB::InsertDBH->new({
                                             dbname => $opt_D,
                                             dbhost => $opt_H,
                                             dbschema => 'sgn',
                                             dbargs => {AutoCommit => 0,
                                                        RaiseError => 1}
                                    });
eval {

    # parameters for this specific instance
    my $experiment_type_id = 1; # 'mapping'

    my $accession_id ;#= '88x87'; # parent1 x parent2

    # make an object to give us the values from the spreadsheet
    my $ss = CXGN::Tools::File::Spreadsheet->new($opt_i);
    my @markers = $ss->row_labels(); # row labels are the marker names
    my @columns = $ss->column_labels(); # column labels are the headings for the data columns

    # make sure the spreadsheet is how we expect it to be
    @columns = qw | marker protocol Temp fwd rev  |
	or die"Column headings are not as expected";

    for my $marker_name (@markers) {

	print "marker: $marker_name\n";

        my @marker_ids =  CXGN::Marker::Tools::marker_name_to_ids($dbh,$marker_name);
        if (@marker_ids>1) { die "Too many IDs found for marker '$marker_name'" }
	# just get the first ID in the list (if the list is longer than 1, we've already died)
        my $marker_id = @marker_ids[0];

	if(!$marker_id) {
	    $marker_id = CXGN::Marker::Tools::insert_marker($dbh,$marker_name);
	    print "marker added: $marker_id\n";
	}
	else {  print "marker_id found: $marker_id\n" }

        # clean this up?
	my $annealing_temp =
	    ((grep {/temp/} @columns) && ($ss->value_at($marker_name,'temp')))
	    ? $ss->value_at($marker_name,'temp') : 55;
	print "temp: $annealing_temp\n";

	my $fwd = $ss->value_at($marker_name,'fwd')
	    or die "No foward primer found for $marker_name";
	print "fwd: $fwd\n";

	my $primer_id_fwd = CXGN::Marker::Tools::get_sequence_id($dbh,$fwd);
        $primer_id_fwd = CXGN::Marker::Tools::insert($dbh,"sequence","sequence_id",['sequence'], ($fwd)) if !$primer_id_fwd;
	print "primer_id_fwd: $primer_id_fwd\n";

	my $rev=$ss->value_at($marker_name,'rev')
	    or die"No reverse primer found for $marker_name";
	print "rev: $rev\n";
	my $primer_id_rev = CXGN::Marker::Tools::get_sequence_id($dbh,$rev);
          $primer_id_rev = CXGN::Marker::Tools::insert($dbh,"sequence","sequence_id",['sequence'], ($rev)) if !$primer_id_rev;
	print "primer_id_rev: $primer_id_rev\n";

	my $protocol = $opt_p;# $ss->value_at($marker_name,'protocol');
	my ($pd, $primer_id_pd, $indel, $indel_id, $snp, $snp_id, $aspe1, $aspe2, $aspe1_id, $aspe2_id, $seq5, $seq5_id, $seq3, $seq3_id);

	if (($protocol eq 'dCAPS') && ($pd = $ss->value_at($marker_name,'pd'))) {
	    print "pd: $pd\n";
	    $primer_id_pd = CXGN::Marker::Tools::get_sequence_id($dbh,$pd);
            $primer_id_pd = CXGN::Marker::Tools::insert($dbh,"sequence","sequence_id",['sequence'], ($pd)) if !$primer_id_pd;
	    print "primer_id_pd: $primer_id_pd\n";
	}############## add here sequences for different protocols
        if (($protocol eq 'Indel') && ($indel = $ss->value_at($marker_name,'Indel'))) {
	    print "indel: $indel\n";
	    $indel_id = CXGN::Marker::Tools::get_sequence_id($dbh,$indel);
            $indel_id = CXGN::Marker::Tools::insert($dbh,"sequence","sequence_id",['sequence'], ($indel)) if !$indel_id;
	    print "indel: $indel_id\n";
        }
        if (($protocol eq 'snp') && ($snp = $ss->value_at($marker_name,'SNP'))) {
	    print "snp: $snp\n";
	    $snp_id = CXGN::Marker::Tools::get_sequence_id($dbh,$snp);
            $snp_id = CXGN::Marker::Tools::insert($dbh,"sequence","sequence_id",['sequence'], ($snp)) if !$snp_id;
	    print "snp_id: $snp_id\n";

            $aspe1 = $ss->value_at($marker_name,'ASPE1');
            print "aspe1: $aspe1\n";
	    if ($aspe1) {
            $aspe1_id = CXGN::Marker::Tools::get_sequence_id($dbh,$aspe1);
            $aspe1_id = CXGN::Marker::Tools::insert($dbh,"sequence","sequence_id",['sequence'], ($aspe1)) if !$aspe1_id;
	    print "aspe1_id: $aspe1_id\n";
            }
            $aspe2 = $ss->value_at($marker_name,'ASPE2');
            if ($aspe2) {
            print "aspe2: $aspe2\n";
	    $aspe2_id = CXGN::Marker::Tools::get_sequence_id($dbh,$aspe2);
            $aspe2_id = CXGN::Marker::Tools::insert($dbh,"sequence","sequence_id",['sequence'], ($aspe2)) if !$aspe2_id;
	    print "aspe2_id: $aspe2_id\n";
            }
        }
        if ($protocol eq 'SNP' || $protocol eq 'Indel') {
            $seq3 = $ss->value_at($marker_name,'seq3');
            print "seq3: $seq3\n";
	    $seq3_id = CXGN::Marker::Tools::get_sequence_id($dbh,$seq3);
            $seq3_id = CXGN::Marker::Tools::insert($dbh,"sequence","sequence_id",['sequence'], ($seq3)) if !$seq3_id;
	    print "seq3_id: $seq3_id\n";

            $seq5 = $ss->value_at($marker_name,'seq5');
            print "seq5: $seq5\n";
	    $seq5_id = CXGN::Marker::Tools::get_sequence_id($dbh,$seq5);
            $seq5_id = CXGN::Marker::Tools::insert($dbh,"sequence","sequence_id",['sequence'], ($seq5)) if !$seq5_id;
	    print "seq5_id: $seq5_id\n";
        }

        # check if data already in pcr_experiment and marker_experiment, and if not, add it
	# there's a lot of stuff to check here.. I know these aren't in the database so will come back later

	my $names = ["marker_id", "annealing_temp", "primer_id_fwd",
		     "primer_id_rev", "experiment_type_id", "map_id","primer_id_pd","accession_id"];
	my @fields = ($marker_id,$annealing_temp,$primer_id_fwd,
		      $primer_id_rev,$experiment_type_id,$map_id,$primer_id_pd,$accession_id);

        # does this check if pcr_experiment already exists?
	my $pcr_experiment_id = CXGN::Marker::Tools::insert($dbh,"pcr_experiment","pcr_experiment_id",$names,@fields);
	print "pcr experiment added: $pcr_experiment_id\n";

        #new pcr_experiment object
        my $pcr_ex = CXGN::Marker::PCR::Experiment->new($dbh, $pcr_experiment_id);
        # set the sequence types
        $pcr_ex->store_sequence('forward primer', $fwd);
        $pcr_ex->store_sequence('reverse primer', $rev);
        $pcr_ex->store_sequence('aspe primer', $aspe1) if $aspe1;
        $pcr_ex->store_sequence('aspe primer', $aspe2) if $aspe2;
        $pcr_ex->store_sequence('indel', $indel) if $indel;
        $pcr_ex->store_sequence('snp nucleotide', $snp) if $snp;
        $pcr_ex->store_sequence('five prime flanking', $seq5) if $seq5;
        $pcr_ex->store_sequence('three prime flanking', $seq3) if $seq3;

        # check for existing marker_experiment and update if found
	my $q = "SELECT marker_experiment_id FROM marker_experiment "
	    . "JOIN marker_location USING (location_id) JOIN map_version "
	    . "USING (map_version_id) WHERE rflp_experiment_id is null "
	    . "AND map_id = ? AND marker_id = ? AND protocol = ?";

	my $sth = $dbh->prepare($q);
	$sth->execute($map_id,$marker_id,$protocol);
	my @exp_id;
	while (my $id = $sth->fetchrow_array()) { push (@exp_id,$id) }

	if (@exp_id) {
	    if (@exp_id > 1) { print join(', ', @exp_id) and exit() }
            # this really should not be the case
            # update
            my $marker_experiment_id = $exp_id[0];

	    my $u = "UPDATE marker_experiment set pcr_experiment_id = ? where marker_experiment_id = ?";
	    $sth = $dbh->prepare($u);
	    $sth->execute($pcr_experiment_id,$marker_experiment_id);

	    print "UPDATE $marker_experiment_id\n";
	}

        # if not loading map and experiments together, may want to match other protocols

        # if not, insert new marker_experiment
	else {
	    my $names = ["marker_id", "pcr_experiment_id", "protocol"];
	    my @fields = ($marker_id, $pcr_experiment_id, $protocol);
	    # 'SSR' or 'unknown'?

	    my $marker_experiment_id = CXGN::Marker::Tools::insert
		($dbh,"marker_experiment","marker_experiment_id",$names,@fields);
#	    print "marker experiment added: $marker_experiment_id\n";
            print "ADD $marker_experiment_id\n";
	}

    }
};

if ($@) {
    print $@;
    print "Failed; rolling back.\n";
    $dbh->rollback();
}
else {
    print"Succeeded.\n";
    if ($opt_t) {
        print"Rolling back.\n";
        $dbh->rollback();
    }
    else  {
        print"Committing.\n";
        $dbh->commit();
    }
}
