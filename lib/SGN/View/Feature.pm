package SGN::View::Feature;
use strict;
use warnings;

use base 'Exporter';

use HTML::Entities;
use List::Util qw/ sum /;
use List::MoreUtils qw/ any /;

use Bio::Seq;

use CXGN::Tools::Text qw/commify_number/;
use CXGN::Tools::Identifiers;


our @EXPORT_OK = qw/
    related_stats feature_table
    feature_link
    cvterm_link
    organism_link feature_length
    mrna_and_protein_sequence
    description_featureprop_types
    get_description
    location_list_html
    location_string
    location_string_with_strand
    type_name
/;

sub type_name {
    cvterm_name( shift->type, @_ );
}

sub cvterm_name {
    my ($cvt, $caps) = @_;
    ( my $n = $cvt->name ) =~ s/_/ /g;
    if( $caps ) {
        $n =~ s/(\S+)/lc($1) eq $1 ? ucfirst($1) : $1/e;
    }
    return $n;
}

sub description_featureprop_types {
    shift->result_source->schema
         ->resultset('Cv::Cvterm')
         ->search({
             name => [ 'Note',
                       'functional_description',
                       'Description',
                       'description',
                     ],
           })
}

sub get_description {
    my ($feature) = @_;

    my $desc_types =
        description_featureprop_types( $feature )
            ->get_column('cvterm_id')
            ->as_query;

    my $description =
        $feature->search_related('featureprops', {
            type_id => { -in => $desc_types },
        })->get_column('value')
          ->first;

    return unless $description;

    $description =~ s/(\S+)/my $id = $1; CXGN::Tools::Identifiers::link_identifier($id) || $id/ge;

    return $description;
}

sub location_string {
    my ( $id, $start, $end, $strand ) = @_;
    if( @_ == 1 ) {
        my $loc = shift;
        $id     = feature_link($loc->srcfeature);
        $start  = $loc->fmin+1;
        $end    = $loc->fmax;
        $strand = $loc->strand;
    }
    ( $start, $end ) = ( $end, $start ) if $strand && $strand == -1;
    return "$id:$start..$end";
}

sub location_string_with_strand {
    location_string( @_ )
}

sub location_list_html {
    my ($feature, $featurelocs) = @_;
    my @coords = map { location_string($_) }
        ( $featurelocs ? $featurelocs->all
                       : $feature->featureloc_features->all)
        or return '<span class="ghosted">none</span>';
    return @coords;
}
sub location_list {
    my ($feature, $featurelocs) = @_;
    return map { ($_->srcfeature ? $_->srcfeature->name : '<span class="ghosted">null</span>') . ':' . ($_->fmin+1) . '..' . $_->fmax }
        ( $featurelocs ? $featurelocs->all
                       : $feature->featureloc_features->all );
}

sub related_stats {
    my ($features) = @_;
    my $stats = { };
    my $total = scalar @$features;
    for my $f (@$features) {
            $stats->{cvterm_link($f->type)}++;
    }
    my $data = [ ];
    for my $k (sort keys %$stats) {
        push @$data, [ $stats->{$k}, $k ];
    }
    if( 1 < scalar keys %$stats ) {
        push @$data, [ $total, "<b>Total</b>" ];
    }
    return $data;
}

sub feature_table {
    my ($features,$reference_sequence) = @_;
    my @data;
    my $na_html = '<span class="ghosted">n/a</span>';

    for my $f (sort { $a->name cmp $b->name } @$features) {
        my @ref_condition =
            $reference_sequence ? ( srcfeature_id => $reference_sequence->feature_id )
                                : ();

        my @locations = $f->search_related('featureloc_features', {
            @ref_condition,
           },
           { order_by => 'feature_id' }
          );

        if( @locations ) {
        # Add a row for every featureloc
            for my $loc (@locations) {
                my $ref = $loc->srcfeature;
                my ($start,$end) = ($loc->fmin+1, $loc->fmax);
                push @data, [
                    cvterm_link($f->type),
                    feature_link($f),
                    ($ref ? $ref->name : '<span class="ghosted">null</span>').":$start..$end",
                    commify_number( feature_length( $f, $loc ) ) || $na_html,
                    $loc->strand ? ( $loc->strand == 1 ? '+' : '-' ) : $na_html,
                    $loc->phase || $na_html,
                    ];
            }
        }
        else {
            my $nl = 'not located';
            if( $reference_sequence ) {
                $nl .= " on ".encode_entities( $reference_sequence->name )
            }
            push @data, [
                cvterm_link($f->type),
                feature_link($f),
                qq|<span class="ghosted">$nl</span>|,
                commify_number( feature_length( $f, undef ) ) || $na_html,
                ($na_html)x2,
            ];
        }
    }
    return \@data;
}

# try to figure out the "length" of a feature, which will vary for different features
sub feature_length {
    my ( $feature, $location ) = @_;

    $location = $location->first
        if $location && $location->isa('DBIx::Class::ResultSet');

    my $type      = $feature->type;
    my $type_name = $type->name;

    # firstly, for any feature, trust the length of its residues if it has them
    if( my $seqlen = $feature->seqlen || $feature->residues && length $feature->residues ) {
        return $seqlen;
    }
    # for some features, can say that its length is the length of its location
    elsif( any { $type_name eq $_ } qw( exon gene ) ) {
        return unless $location;
        return $location->fmax - $location->fmin;
    }
    return;
}

sub _feature_search_string {
    my ($fl) = @_;
    return '' unless $fl;
    return ($fl->srcfeature ? $fl->srcfeature->name : '<span class="ghosted">null</span>') . ':'. ($fl->fmin+1) . '..' . $fl->fmax;
}


### XXX TODO: A lot of these _link and sequence functions need to be
### moved to controller code.

sub feature_link {
    my ($feature) = @_;
    return '<span class="ghosted">null</span>' unless $feature;
    my $id   = $feature->feature_id;
    my $name = $feature->name;
    return qq{<a href="/feature/view/id/$id">$name</a>};
}

sub organism_link {
    my ($organism) = @_;
    my $id      = $organism->organism_id;
    my $species = $organism->species;
    return qq{<a class="species_binomial" href="/chado/organism.pl?organism_id=$id">$species</a>};
}

sub cvterm_link {
    my ( $cvt, $caps ) = @_;
    my $name = cvterm_name( $cvt, $caps );
    my $id   = $cvt->id;
    return qq{<a href="/chado/cvterm.pl?cvterm_id=$id">$name</a>};
}

sub mrna_and_protein_sequence {
    my ($mrna_feature) = @_;

    # if we were actually passed a polypeptide, get its mrna(s) and
    # recurse
    if( $mrna_feature->type->name eq 'polypeptide' ) {
        return
            map mrna_and_protein_sequence( $_ ),
            $mrna_feature->search_related('feature_relationship_subjects',
                    { 'me.type_id' => {
                        -in => $mrna_feature->result_source->schema
                                            ->resultset('Cv::Cvterm')
                                            ->search({name => 'derives_from'})
                                            ->get_column('cvterm_id')
                                            ->as_query,
                    },
                  },
               )
               ->search_related('object');
    }

    my $peptide = _peptides_rs( $mrna_feature )->first;

    # just return the mrna and peptide rows if they both have their
    # own sequences (because the rows can act as Bio::PrimarySeqI's
    return [ $mrna_feature, $peptide ] if $peptide && $peptide->subseq(1,1) && $mrna_feature && $mrna_feature->subseq(1,1);

    # if there *is* no peptide, just return the mrna feature
    return [ $mrna_feature ] if !$peptide && $mrna_feature && $mrna_feature->subseq(1,1);

    my @exon_locations = _exon_rs( $mrna_feature )->all
        or return;

    my $mrna_seq = Bio::PrimarySeq->new(
        -id   => $mrna_feature->name,
        -desc => 'spliced cDNA sequence',
        -seq  => join( '', map {
            $_->srcfeature->subseq( $_->fmin+1, $_->fmax ),
         } @exon_locations
        ),
    );

    return unless $mrna_seq->length > 0;

    my $peptide_loc = $peptide && _peptide_loc($peptide)->first
        or return [ $mrna_seq ];

    my $protein_seq = Bio::PrimarySeq->new(
        -id   => $mrna_feature->name,
        -desc => 'protein sequence',
        -seq  => $mrna_seq->seq,
       );
    my ( $trim_fmin, $trim_fmax ) = _calculate_cdna_utr_lengths(
        $peptide_loc->to_range,
        [ map $_->to_range, @exon_locations ],
     );

    if( $trim_fmin || $trim_fmax ) {
        $protein_seq = $protein_seq->trunc( 1+$trim_fmin, $mrna_seq->length - $trim_fmax );
    }

    if( $exon_locations[0]->strand == -1 ) {
        $_ = $_->revcom for $mrna_seq, $protein_seq;
    }

    $protein_seq = $protein_seq->translate;

    return [ $mrna_seq, $protein_seq ];
}

# given the range of the peptide and the ranges of each of the exons
# (as Bio::RangeI's), calculate how many bases should be trimmed off
# of each end of the cDNA (i.e. mRNA) seq to get the CDS seq
sub _calculate_cdna_utr_lengths {
    my ( $peptide, $exons ) = @_;

    my ( $trim_fmin, $trim_fmax ) = ( 0, 0 );

    # calculate trim_fmin if necessary
    if( $exons->[0]->start < $peptide->start ) {

        $trim_fmin =
            sum
            map {
                $_->overlaps($peptide)
                    ? $peptide->start - $_->start
                    : $_->length
            }
            grep $_->start < $peptide->start, # find exons that overlap the UTR
            @$exons
    }

    # calculate trim_fmax if necessary
    if( $exons->[-1]->end > $peptide->end ) {
        $trim_fmax =
            sum
            map {
                $_->overlaps($peptide)
                    ? $_->end - $peptide->end
                    : $_->length
            }
            grep $_->end > $peptide->end, # find exons that overlap the UTR
            @$exons
    }

    return ( $trim_fmin, $trim_fmax );
}

sub _peptides_rs {
    my ( $mrna_feature ) = @_;

    $mrna_feature
        ->feature_relationship_objects({
            'me.type_id' => {
                -in => _cvterm_rs( $mrna_feature, 'relationship', 'derives_from' )
                         ->get_column('cvterm_id')
                         ->as_query,
            },
          })
        ->search_related( 'subject', {
            'subject.type_id' => {
                -in => _cvterm_rs( $mrna_feature, 'sequence', 'polypeptide' )
                         ->get_column('cvterm_id')
                         ->as_query,
            },
           })
    }
sub _peptide_loc {
    shift->search_related( 'featureloc_features', {
            srcfeature_id => { -not => undef },
          },
          { prefetch => 'srcfeature',
            order_by => 'fmin',
          },
         );
}

sub _exon_rs {
    my ( $mrna_feature ) = @_;

    $mrna_feature
        ->feature_relationship_objects({
            'me.type_id' => {
                -in => _cvterm_rs( $mrna_feature, 'relationship', 'part_of' )
                         ->get_column('cvterm_id')
                         ->as_query,
            },
          },
          {
              prefetch => 'type',
          })
        ->search_related( 'subject', {
            'subject.type_id' => {
                -in => _cvterm_rs( $mrna_feature, 'sequence', 'exon' )
                         ->get_column('cvterm_id')
                         ->as_query,
            },
           },
           {
               prefetch => 'featureloc_features',
           })
        ->search_related( 'featureloc_features', {
            srcfeature_id => { -not => undef },
          },
          {
            prefetch => 'srcfeature',
            order_by => 'fmin',
          },
         )
}

sub _cvterm_rs {
    my ( $row, $cv, $cvt ) = @_;

    return $row->result_source->schema
               ->resultset('Cv::Cv')
               ->search({ 'me.name' => $cv })
               ->search_related('cvterms', {
                   'cvterms.name' => $cvt,
                 });
}

1;
