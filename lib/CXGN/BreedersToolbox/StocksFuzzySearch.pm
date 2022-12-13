package CXGN::BreedersToolbox::StocksFuzzySearch;

=head1 NAME

CXGN::BreedersToolbox::StocksFuzzySearch - an object to find approximate matches in the database to a query list of stock names.

=head1 USAGE

 my $fuzzy_stock_search = CXGN::BreedersToolbox::StocksFuzzySearch->new({schema => $schema});
 my $fuzzy_search_result = $fuzzy_stock_search->get_matches(\@stock_list, $max_distance, $stock_type);

=head1 DESCRIPTION


=head1 AUTHORS

 Jeremy D. Edwards (jde22@cornell.edu)

=cut

use strict;
use warnings;
use Moose;
use MooseX::FollowPBP;
use Moose::Util::TypeConstraints;
use CXGN::String::FuzzyMatch;
use SGN::Model::Cvterm;
use Data::Dumper;

has 'schema' => (
    is       => 'rw',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);


sub get_matches {
    my $self = shift;
    my $stock_list_ref = shift;
    my $max_distance = shift;
    my $stock_type = shift;
    my $schema = $self->get_schema();
    my @stock_list = @{$stock_list_ref};
    my %synonym_uniquename_lookup;
    my $fuzzy_string_search = CXGN::String::FuzzyMatch->new( { case_insensitive => 0} );
    my @fuzzy_stocks;
    my @absent_stocks;
    my @found_stocks;
    my %results;
    my $error = '';
    print STDERR "StocksFuzzySearch 1".localtime()."\n";

    my $synonym_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'stock_synonym', 'stock_property')->cvterm_id();
    my $stock_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, $stock_type, 'stock_type')->cvterm_id();
    my $q = "SELECT stock.uniquename, stockprop.value, stockprop.type_id FROM stock LEFT JOIN stockprop USING(stock_id) WHERE stock.type_id=$stock_type_id";
    my $h = $schema->storage->dbh()->prepare($q);
    $h->execute();
    my %uniquename_hash;

    print STDERR "StocksFuzzySearch 2".localtime()."\n";

    while (my ($uniquename, $synonym, $type_id) = $h->fetchrow_array()) {
        $uniquename_hash{$uniquename}++;
        if ($type_id){
            if ($type_id == $synonym_type_id){
                push @{$synonym_uniquename_lookup{$synonym}}, $uniquename;
            }
        }
    }

    my @stock_names = keys %uniquename_hash;
    my @synonym_names = keys %synonym_uniquename_lookup;
    push (@stock_names, @synonym_names);

    my @lowercased_names;
    my %lowercase_name_lookup;
    foreach (@stock_names){
        push @lowercased_names, lc($_);
        $lowercase_name_lookup{lc($_)} = $_;
    }

    print STDERR "StocksFuzzySearch 3".localtime()."\n";

    my @lowercased_synonyms;
    my %lowercase_synonym_lookup;
    foreach (@synonym_names){
        push @lowercased_synonyms, lc($_);
        $lowercase_synonym_lookup{lc($_)} = $_;
    }
    print STDERR "StocksFuzzySearch 4".localtime()."\n";

    foreach my $stock_name (@stock_list) {
	#lookup case insensitive stock names#
	my $lc_name = lc($stock_name);
	if (exists($lowercase_name_lookup{$lc_name})){
	    my $uniquename = $lowercase_name_lookup{$lc_name};
            push @found_stocks, {matched_string => $stock_name, unique_name => $uniquename};
            next;
        }
	#lookup cases insensitive stock synonyms#
        if (exists($lowercase_synonym_lookup{$lc_name})){
            my %match_info;
            if (scalar(@{$lowercase_synonym_lookup{$lc_name}}) > 1){
                my $synonym_lookup_uniquename = join ',', @{$lowercase_synonym_lookup{$lc_name}};
                $error .= "This synonym $stock_name has more than one uniquename $synonym_lookup_uniquename. This should not happen!";
                next;
            } elsif (scalar(@{$lowercase_synonym_lookup{$lc_name}}) == 1){
                $match_info{matched_string} = $stock_name." (SYNONYM OF ".$lowercase_synonym_lookup{$lc_name}->[0].")";
                $match_info{is_synonym} = 1;
                $match_info{unique_name} = $lowercase_synonym_lookup{$lc_name}->[0];
            }
            push @found_stocks, \%match_info;
            next;
        }

        my @search_stock_names;
        foreach (@lowercased_names){
	    #if there is a difference in length greater than 10, it will not fuzzy search over that name
            if (abs(length($_) - length($stock_name)) <= 10){
                push @search_stock_names, $_;
            }
        }
       #####case-sensitive matches are exact_match
        my @stock_matches = @{$fuzzy_string_search->get_matches(lc($stock_name), \@search_stock_names, $max_distance)};

        if (scalar(@stock_matches) == 0) {
	    push (@absent_stocks, $stock_name);
        } else {
            my @matches;
            foreach (@stock_matches){
                my %match_info;
                my $matched_name = $_->{string};
                my $original_matched_name = $lowercase_name_lookup{$matched_name};
                $match_info{'name'} = $original_matched_name;
                $match_info{'distance'} = $_->{distance};
                my $synonym_lookup_of_matched_string = $synonym_uniquename_lookup{$original_matched_name} || [];
                if (scalar(@$synonym_lookup_of_matched_string) > 1){
                    my $synonym_lookup_uniquename = join ',', @$synonym_lookup_of_matched_string;
                    $error .= "This synonym $matched_name has more than one uniquename $synonym_lookup_uniquename. This should not happen!";
                    next;
                } elsif (scalar(@$synonym_lookup_of_matched_string) == 1){
                    $match_info{'unique_names'} = [$original_matched_name];
                    $match_info{'is_synonym'} = 1;
                    $match_info{'synonym_of'} = $synonym_lookup_of_matched_string->[0];
                } else {
                    $match_info{'unique_names'} = [$original_matched_name];
                }
                push @matches, \%match_info;
            }
            push @fuzzy_stocks, {
                name => $stock_name,
                matches => \@matches
            };
        }
    }
    print STDERR "StocksFuzzySearch 5".localtime()."\n";

    if ($error){
        print STDERR "FUZZY ERRORS: $error\n";
        $results{'error'} = $error;
    }

    $results{'found'} = \@found_stocks;
    $results{'fuzzy'} = \@fuzzy_stocks;
    $results{'absent'} = \@absent_stocks;
    return \%results;
}

###
1;
###
