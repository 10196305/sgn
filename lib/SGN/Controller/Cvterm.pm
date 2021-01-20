
package SGN::Controller::Cvterm;

use CXGN::Chado::Cvterm; #DEPRECATE this !! 
use CXGN::Cvterm;
use URI::FromHash 'uri';
use Moose;

BEGIN { extends 'Catalyst::Controller' };
with 'Catalyst::Component::ApplicationAttribute';

has 'schema' => (
    is       => 'rw',
    isa      => 'DBIx::Class::Schema',
    lazy_build => 1,
);
sub _build_schema {
    shift->_app->dbic_schema( 'Bio::Chado::Schema', 'sgn_chado' )
}


=head2 view_cvterm

Public path: /cvterm/<cvterm_id>/view

View a cvterm detail page.

Chained off of L</get_cvterm> below.

=cut

sub view_cvterm : Chained('get_cvterm') PathPart('view') Args(0) {
    my ( $self, $c, $action) = @_;
    my $cvterm = $c->stash->{cvterm};
    my $cvterm_id = $cvterm ? $cvterm->cvterm_id : undef ;

    if (!$c->user()) {
        # redirect to login page
        $c->res->redirect( uri( path => '/user/login', query => { goto_url => $c->req->uri->path_query } ) );
        return;
    }

    my $bcs_cvterm = $cvterm->cvterm;
       
    my $logged_user = $c->user;
    my $person_id = $logged_user->get_object->get_sp_person_id if $logged_user;
    my $user_role = 1 if $logged_user;
    my $curator   = $logged_user->check_roles('curator') if $logged_user;
    my $submitter = $logged_user->check_roles('submitter') if $logged_user;
    my $sequencer = $logged_user->check_roles('sequencer') if $logged_user;
    my $props = $self->_cvtermprops($cvterm);
    my $editable_cvterm_props = "trait_format,trait_default_value,trait_minimum,trait_maximum,trait_details,trait_categories";
   
    
    $c->stash(
	template => '/chado/cvterm.mas',
	cvterm   => $cvterm, #deprecate this maybe? 
	cvtermref => {
	    cvterm    => $bcs_cvterm,
	    curator   => $curator,
            submitter => $submitter,
            sequencer => $sequencer,
            person_id => $person_id,
	    props     => $props,
	    editable_cvterm_props => $editable_cvterm_props,
	}
	);
    
}


=head2 get_cvterm

Chain root for fetching a cvterm object to operate on.

Path part: /cvterm/<cvterm_id>

=cut

sub get_cvterm : Chained('/')  PathPart('cvterm')  CaptureArgs(1) {
    my ($self, $c, $cvterm_id) = @_;

    my $identifier_type = $c->stash->{identifier_type}
        || $cvterm_id =~ /[^-\d]/ ? 'accession' : 'cvterm_id';
    
    my $cvterm;
    if( $identifier_type eq 'cvterm_id' ) {
	$cvterm = CXGN::Cvterm->new({ schema=>$self->schema, cvterm_id => $cvterm_id } );
    } elsif ( $identifier_type eq 'accession' )  {
	$cvterm = CXGN::Cvterm->new({ schema=>$self->schema, accession=>$cvterm_id } ) ;
    }
    my $found_cvterm = $cvterm->cvterm 
	or $c->throw_404( "Cvterm $cvterm_id not found" );
    
    $c->stash->{cvterm}     = $cvterm; 
    
    return 1;
}



sub _cvtermprops {
    my ($self,$cvterm) = @_;

    my $properties ;
    if ($cvterm) {
	my $bcs_cvterm = $cvterm->cvterm;
	if (!$bcs_cvterm) { return undef ; } 
        my $cvtermprops = $bcs_cvterm->search_related("cvtermprops");
        while ( my $prop =  $cvtermprops->next ) {
            push @{ $properties->{$prop->type->name} } ,   $prop->value ;
        }
    }
    return $properties;
}
####
1;##
####
