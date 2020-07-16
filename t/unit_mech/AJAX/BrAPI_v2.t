
use strict;
use warnings;

#use lib 't/lib';
#use SGN::Test::Fixture;
use Test::More;
use Test::WWW::Mechanize;

#Needed to update IO::Socket::SSL
use Data::Dumper;
use JSON;
local $Data::Dumper::Indent = 0;

my $mech = Test::WWW::Mechanize->new;
my $response; my $searchId;

$mech->get_ok('http://localhost:3010/brapi/v2/serverinfo');
$response = decode_json $mech->content;
print STERR Dumper $response;
is_deeply($response, {'metadata' => {'status' => [{'message' => 'BrAPI base call found with page=0, pageSize=10','messageType' => 'INFO'},{'messageType' => 'INFO','message' => 'Loading CXGN::BrAPI::v2::ServerInfo'},{'messageType' => 'INFO','message' => 'Calls result constructed'}],'datafiles' => [],'pagination' => {'totalPages' => 1,'currentPage' => 0,'totalCount' => 116,'pageSize' => 1000}},'result' => {'calls' => [{'service' => 'serverinfo','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'versions' => ['2.0'],'methods' => ['GET'],'datatypes' => ['application/json'],'service' => 'commoncropnames'},{'datatypes' => ['application/json'],'service' => 'lists','versions' => ['2.0'],'methods' => ['GET','POST']},{'versions' => ['2.0'],'methods' => ['GET','PUT'],'datatypes' => ['application/json'],'service' => 'lists/{listDbId}'},{'methods' => ['POST'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'lists/{listDbId}/items'},{'service' => 'search/lists','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['POST']},{'service' => 'search/lists/{searchResultsDbId}','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'service' => 'locations','datatypes' => ['application/json'],'methods' => ['GET','POST'],'versions' => ['2.0']},{'service' => 'locations/{locationDbId}','datatypes' => ['application/json'],'methods' => ['GET','PUT'],'versions' => ['2.0']},{'versions' => ['2.0'],'methods' => ['POST'],'datatypes' => ['application/json'],'service' => 'search/locations'},{'methods' => ['GET'],'versions' => ['2.0'],'service' => 'search/locations/{searchResultsDbId}','datatypes' => ['application/json']},{'datatypes' => ['application/json'],'service' => 'people','versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'people/{peopleDbId}','versions' => ['2.0'],'methods' => ['GET']},{'versions' => ['2.0'],'methods' => ['POST'],'datatypes' => ['application/json'],'service' => 'search/people'},{'datatypes' => ['application/json'],'service' => 'search/people/{searchResultsDbId}','methods' => ['GET'],'versions' => ['2.0']},{'methods' => ['GET','POST'],'versions' => ['2.0'],'service' => 'programs','datatypes' => ['application/json']},{'datatypes' => ['application/json'],'service' => 'programs/{programDbId}','versions' => ['2.0'],'methods' => ['GET','PUT']},{'versions' => ['2.0'],'methods' => ['POST'],'service' => 'search/programs','datatypes' => ['application/json']},{'datatypes' => ['application/json'],'service' => 'search/programs/{searchResultsDbId}','methods' => ['GET'],'versions' => ['2.0']},{'datatypes' => ['application/json'],'service' => 'seasons','versions' => ['2.0'],'methods' => ['GET']},{'methods' => ['GET'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'seasons/{seasonDbId}'},{'service' => 'search/seasons','datatypes' => ['application/json'],'methods' => ['POST'],'versions' => ['2.0']},{'datatypes' => ['application/json'],'service' => 'search/seasons/{searchResultsDbId}','versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'studies','methods' => ['GET','POST'],'versions' => ['2.0']},{'versions' => ['2.0'],'methods' => ['GET','PUT'],'datatypes' => ['application/json'],'service' => 'studies/{studyDbId}'},{'methods' => ['POST'],'versions' => ['2.0'],'service' => 'search/studies','datatypes' => ['application/json']},{'versions' => ['2.0'],'methods' => ['GET'],'datatypes' => ['application/json'],'service' => 'search/studies/{searchResultsDbId}'},{'service' => 'studytypes','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'datatypes' => ['application/json'],'service' => 'trials','versions' => ['2.0'],'methods' => ['GET','POST']},{'datatypes' => ['application/json'],'service' => 'trials/{trialDbId}','versions' => ['2.0'],'methods' => ['GET','PUT']},{'datatypes' => ['application/json'],'service' => 'search/trials','methods' => ['POST'],'versions' => ['2.0']},{'service' => 'search/trials/{searchResultsDbId}','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'images','versions' => ['2.0'],'methods' => ['GET','POST']},{'methods' => ['GET','PUT'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'images/{imageDbId}'},{'service' => 'images/{imageDbId}/imagecontent','datatypes' => ['application/json'],'methods' => ['PUT'],'versions' => ['2.0']},{'datatypes' => ['application/json'],'service' => 'search/images','versions' => ['2.0'],'methods' => ['POST']},{'datatypes' => ['application/json'],'service' => 'search/images/{searchResultsDbId}','versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'observations','versions' => ['2.0'],'methods' => ['GET','POST','PUT']},{'methods' => ['GET','PUT'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'observations/{observationDbId}'},{'service' => 'observations/table','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'search/observations','methods' => ['POST'],'versions' => ['2.0']},{'datatypes' => ['application/json'],'service' => 'search/observations/{searchResultsDbId}','methods' => ['GET'],'versions' => ['2.0']},{'service' => 'observationlevels','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'methods' => ['GET','POST','PUT'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'observationunits'},{'methods' => ['GET','PUT'],'versions' => ['2.0'],'service' => 'observationunits/{observationUnitDbId}','datatypes' => ['application/json']},{'datatypes' => ['application/json'],'service' => 'search/observationunits','versions' => ['2.0'],'methods' => ['POST']},{'service' => 'search/observationunits/{searchResultsDbId}','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'service' => 'ontologies','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'service' => 'traits','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'datatypes' => ['application/json'],'service' => 'traits/{traitDbId}','versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'variables','versions' => ['2.0'],'methods' => ['GET']},{'methods' => ['GET'],'versions' => ['2.0'],'service' => 'variables/{observationVariableDbId}','datatypes' => ['application/json']},{'datatypes' => ['application/json'],'service' => 'search/variables','methods' => ['POST'],'versions' => ['2.0']},{'service' => 'search/variables/{searchResultsDbId}','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'methods' => ['GET'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'calls'},{'versions' => ['2.0'],'methods' => ['POST'],'service' => 'search/calls','datatypes' => ['application/json']},{'versions' => ['2.0'],'methods' => ['GET'],'service' => 'search/calls/{searchResultsDbId}','datatypes' => ['application/json']},{'service' => 'callsets','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'methods' => ['GET'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'callsets/{callSetDbId}'},{'datatypes' => ['application/json'],'service' => 'callsets/{callSetDbId}/calls','versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'search/callsets','versions' => ['2.0'],'methods' => ['POST']},{'datatypes' => ['application/json'],'service' => 'search/callsets/{searchResultsDbId}','versions' => ['2.0'],'methods' => ['GET']},{'service' => 'maps','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'versions' => ['2.0'],'methods' => ['GET'],'service' => 'maps/{mapDbId}','datatypes' => ['application/json']},{'datatypes' => ['application/json'],'service' => 'maps/{mapDbId}/linkagegroups','versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'markerpositions','versions' => ['2.0'],'methods' => ['GET']},{'versions' => ['2.0'],'methods' => ['POST'],'datatypes' => ['application/json'],'service' => 'search/markerpositions'},{'service' => 'search/markerpositions/{searchResultsDbId}','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'versions' => ['2.0'],'methods' => ['GET'],'service' => 'references','datatypes' => ['application/json']},{'methods' => ['GET'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'references/{referenceDbId}'},{'versions' => ['2.0'],'methods' => ['POST'],'service' => 'search/references','datatypes' => ['application/json']},{'versions' => ['2.0'],'methods' => ['GET'],'datatypes' => ['application/json'],'service' => 'search/references/{searchResultsDbId}'},{'service' => 'referencesets','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'methods' => ['GET'],'versions' => ['2.0'],'service' => 'referencesets/{referenceSetDbId}','datatypes' => ['application/json']},{'service' => 'search/referencesets','datatypes' => ['application/json'],'methods' => ['POST'],'versions' => ['2.0']},{'datatypes' => ['application/json'],'service' => 'search/referencesets/{searchResultsDbId}','methods' => ['GET'],'versions' => ['2.0']},{'service' => 'samples','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'service' => 'samples/{sampleDbId}','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'versions' => ['2.0'],'methods' => ['POST'],'datatypes' => ['application/json'],'service' => 'search/samples'},{'datatypes' => ['application/json'],'service' => 'search/samples/{searchResultsDbId}','methods' => ['GET'],'versions' => ['2.0']},{'datatypes' => ['application/json'],'service' => 'variants','versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'variants/{variantDbId}','methods' => ['GET'],'versions' => ['2.0']},{'service' => 'variants/{variantDbId}/calls','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'versions' => ['2.0'],'methods' => ['POST'],'service' => 'search/variants','datatypes' => ['application/json']},{'service' => 'search/variants/{searchResultsDbId}','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'variantsets','versions' => ['2.0'],'methods' => ['GET']},{'datatypes' => ['application/json'],'service' => 'variantsets/extract','methods' => ['GET'],'versions' => ['2.0']},{'versions' => ['2.0'],'methods' => ['GET'],'service' => 'variantsets/{variantSetDbId}','datatypes' => ['application/json']},{'versions' => ['2.0'],'methods' => ['GET'],'service' => 'variantsets/{variantSetDbId}/calls','datatypes' => ['application/json']},{'methods' => ['GET'],'versions' => ['2.0'],'service' => 'variantsets/{variantSetDbId}/callsets','datatypes' => ['application/json']},{'methods' => ['GET'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'variantsets/{variantSetDbId}/variants'},{'methods' => ['POST'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'search/variantsets'},{'service' => 'search/variantsets/{searchResultsDbId}','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'versions' => ['2.0'],'methods' => ['GET','POST'],'datatypes' => ['application/json'],'service' => 'germplasm'},{'versions' => ['2.0'],'methods' => ['GET','PUT'],'datatypes' => ['application/json'],'service' => 'germplasm/{germplasmDbId}'},{'versions' => ['2.0'],'methods' => ['GET'],'service' => 'germplasm/{germplasmDbId}/pedigree','datatypes' => ['application/json']},{'methods' => ['GET'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'germplasm/{germplasmDbId}/progeny'},{'service' => 'germplasm/{germplasmDbId}/mcpd','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']},{'versions' => ['2.0'],'methods' => ['POST'],'datatypes' => ['application/json'],'service' => 'search/germplasm'},{'versions' => ['2.0'],'methods' => ['GET'],'service' => 'search/germplasm/{searchResultsDbId}','datatypes' => ['application/json']},{'service' => 'attributes','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'methods' => ['GET'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'attributes/categories'},{'methods' => ['GET'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'attributes/{attributeDbId}'},{'datatypes' => ['application/json'],'service' => 'search/attributes','versions' => ['2.0'],'methods' => ['POST']},{'versions' => ['2.0'],'methods' => ['GET'],'datatypes' => ['application/json'],'service' => 'search/attributes/{searchResultsDbId}'},{'methods' => ['GET'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'attributevalues'},{'service' => 'attributevalues/{attributeValueDbId}','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'methods' => ['POST'],'versions' => ['2.0'],'datatypes' => ['application/json'],'service' => 'search/attributevalues'},{'service' => 'search/attributevalues/{searchResultsDbId}','datatypes' => ['application/json'],'methods' => ['GET'],'versions' => ['2.0']},{'service' => 'crossingprojects','datatypes' => ['application/json'],'methods' => ['GET','POST'],'versions' => ['2.0']},{'methods' => ['GET','PUT'],'versions' => ['2.0'],'service' => 'crossingprojects/{crossingProjectDbId}','datatypes' => ['application/json']},{'versions' => ['2.0'],'methods' => ['GET','POST'],'service' => 'crosses','datatypes' => ['application/json']},{'versions' => ['2.0'],'methods' => ['GET','POST'],'service' => 'seedlots','datatypes' => ['application/json']},{'versions' => ['2.0'],'methods' => ['GET','POST'],'datatypes' => ['application/json'],'service' => 'seedlots/transactions'},{'versions' => ['2.0'],'methods' => ['GET','PUT'],'service' => 'seedlots/{seedLotDbId}','datatypes' => ['application/json']},{'service' => 'seedlots/{seedLotDbId}/transactions','datatypes' => ['application/json'],'versions' => ['2.0'],'methods' => ['GET']}],'serverName' => 'localhost','organizationURL' => 'http://localhost:3010/','permissions' => {'PUT' => 'curator','POST' => 'curator','GET' => 'any'},'location' => 'USA','organizationName' => 'Boyce Thompson Institute','contactEmail' => 'lam87@cornell.edu','documentationURL' => 'https://solgenomics.github.io/sgn/','serverDescription' => 'BrAPI v2.0 compliant server'}});
$mech->post_ok('http://localhost:3010/brapi/v2/token', [ "username"=> "janedoe", "password"=> "secretpw", "grant_type"=> "password" ]);
$response = decode_json $mech->content;
print STDERR Dumper $response;
is($response->{'metadata'}->{'status'}->[2]->{'message'}, 'Login Successfull');
is($response->{'userDisplayName'}, 'Jane Doe');
is($response->{'expires_in'}, '7200');

$mech->delete_ok('http://localhost:3010/brapi/v2/token');
$response = decode_json $mech->content;
print STDERR Dumper $response;
is($response->{'metadata'}->{'status'}->[2]->{'message'}, 'User Logged Out');

$mech->post_ok('http://localhost:3010/brapi/v2/token', [ "username"=> "janedoe", "password"=> "secretpw", "grant_type"=> "password" ]);
$response = decode_json $mech->content;
print STDERR Dumper $response;
is($response->{'metadata'}->{'status'}->[2]->{'message'}, 'Login Successfull');
is($response->{'userDisplayName'}, 'Jane Doe');
is($response->{'expires_in'}, '7200');
my $access_token = $response->{access_token};

# Phenotyping

$mech->get_ok('http://localhost:3010/brapi/v2/observationlevels');
$response = decode_json $mech->content;
print STDERR Dumper $response;
is_deeply($response, {'result' => {'data' => [{'levelName' => 'replicate','levelOrder' => 0},{'levelName' => 'block','levelOrder' => 1},{'levelName' => 'plot','levelOrder' => 2},{'levelName' => 'subplot','levelOrder' => 3},{'levelName' => 'plant','levelOrder' => 4},{'levelName' => 'tissue_sample','levelOrder' => 5}]},'metadata' => {'pagination' => {'totalPages' => 1,'pageSize' => 6,'totalCount' => 6,'currentPage' => 0},'datafiles' => [],'status' => [{'message' => 'BrAPI base call found with page=0, pageSize=10','messageType' => 'INFO'},{'messageType' => 'INFO','message' => 'Loading CXGN::BrAPI::v2::ObservationVariables'},{'messageType' => 'INFO','message' => 'Observation Levels result constructed'}]}});

$mech->get_ok('http://localhost:3010/brapi/v2/observationunits');
$response = decode_json $mech->content;
print STDERR Dumper $response;
is_deeply($response, {'metadata' => {'status' => [{'messageType' => 'INFO','message' => 'BrAPI base call found with page=0, pageSize=10'},{'message' => 'Loading CXGN::BrAPI::v2::ObservationUnits','messageType' => 'INFO'},{'messageType' => 'INFO','message' => 'Observation Units search result constructed'}],'datafiles' => [],'pagination' => {'totalPages' => 196,'pageSize' => 10,'totalCount' => 1954,'currentPage' => 0}},'result' => {'data' => [{'observationUnitDbId' => '41284','locationDbId' => '23','locationName' => 'test_location','studyName' => 'CASS_6Genotypes_Sampling_2015','observationUnitName' => 'CASS_6Genotypes_103','trialName' => undef,'observations' => [],'additionalInfo' => {},'programDbId' => '134','germplasmName' => 'IITA-TMS-IBA980581','programName' => 'test','externalReferences' => [],'treatments' => [{'modality' => '','factor' => 'No ManagementFactor'}],'observationUnitPosition' => {'positionCoordinateYType' => 'GRID_ROW','positionCoordinateX' => undef,'observationLevelRelationships' => [{'levelCode' => '1','levelName' => 'replicate','levelOrder' => 0},{'levelOrder' => 1,'levelName' => 'block','levelCode' => '1'},{'levelName' => 'plot','levelCode' => '103','levelOrder' => 2},{'levelCode' => undef,'levelName' => 'plant','levelOrder' => 4}],'observationLevel' => {'levelCode' => '103','levelName' => 'plot','levelOrder' => 2},'positionCoordinateY' => undef,'entryType' => 'test','positionCoordinateXType' => 'GRID_COL','geoCoordinates' => ''},'germplasmDbId' => '41283','trialDbId' => '','studyDbId' => '165','observationUnitPUI' => '103'},{'programName' => 'test','externalReferences' => [],'observationUnitPosition' => {'positionCoordinateYType' => 'GRID_ROW','positionCoordinateX' => undef,'observationLevelRelationships' => [{'levelCode' => '1','levelName' => 'replicate','levelOrder' => 0},{'levelOrder' => 1,'levelCode' => '1','levelName' => 'block'},{'levelCode' => '104','levelName' => 'plot','levelOrder' => 2},{'levelOrder' => 4,'levelName' => 'plant','levelCode' => undef}],'geoCoordinates' => '','observationLevel' => {'levelName' => 'plot','levelCode' => '104','levelOrder' => 2},'positionCoordinateY' => undef,'entryType' => 'test','positionCoordinateXType' => 'GRID_COL'},'treatments' => [{'modality' => '','factor' => 'No ManagementFactor'}],'trialDbId' => '','germplasmDbId' => '41282','studyDbId' => '165','observationUnitPUI' => '104','observationUnitDbId' => '41295','locationName' => 'test_location','locationDbId' => '23','observationUnitName' => 'CASS_6Genotypes_104','studyName' => 'CASS_6Genotypes_Sampling_2015','programDbId' => '134','germplasmName' => 'IITA-TMS-IBA980002','observations' => [],'trialName' => undef,'additionalInfo' => {}},{'programName' => 'test','externalReferences' => [],'observationUnitPosition' => {'observationLevel' => {'levelName' => 'plot','levelCode' => '105','levelOrder' => 2},'positionCoordinateXType' => 'GRID_COL','positionCoordinateY' => undef,'entryType' => 'test','geoCoordinates' => '','positionCoordinateX' => undef,'positionCoordinateYType' => 'GRID_ROW','observationLevelRelationships' => [{'levelOrder' => 0,'levelCode' => '1','levelName' => 'replicate'},{'levelName' => 'block','levelCode' => '1','levelOrder' => 1},{'levelName' => 'plot','levelCode' => '105','levelOrder' => 2},{'levelOrder' => 4,'levelCode' => undef,'levelName' => 'plant'}]},'treatments' => [{'modality' => '','factor' => 'No ManagementFactor'}],'germplasmDbId' => '41279','trialDbId' => '','studyDbId' => '165','observationUnitPUI' => '105','observationUnitDbId' => '41296','locationName' => 'test_location','locationDbId' => '23','observationUnitName' => 'CASS_6Genotypes_105','studyName' => 'CASS_6Genotypes_Sampling_2015','observations' => [],'trialName' => undef,'additionalInfo' => {},'programDbId' => '134','germplasmName' => 'IITA-TMS-IBA30572'},{'observationUnitDbId' => '41297','locationDbId' => '23','locationName' => 'test_location','studyName' => 'CASS_6Genotypes_Sampling_2015','observationUnitName' => 'CASS_6Genotypes_106','additionalInfo' => {},'observations' => [],'trialName' => undef,'germplasmName' => 'IITA-TMS-IBA011412','programDbId' => '134','programName' => 'test','observationUnitPosition' => {'observationLevelRelationships' => [{'levelName' => 'replicate','levelCode' => '1','levelOrder' => 0},{'levelName' => 'block','levelCode' => '1','levelOrder' => 1},{'levelName' => 'plot','levelCode' => '106','levelOrder' => 2},{'levelOrder' => 4,'levelCode' => undef,'levelName' => 'plant'}],'positionCoordinateX' => undef,'positionCoordinateYType' => 'GRID_ROW','geoCoordinates' => '','positionCoordinateXType' => 'GRID_COL','positionCoordinateY' => undef,'entryType' => 'test','observationLevel' => {'levelCode' => '106','levelName' => 'plot','levelOrder' => 2}},'treatments' => [{'factor' => 'No ManagementFactor','modality' => ''}],'externalReferences' => [],'germplasmDbId' => '41281','trialDbId' => '','observationUnitPUI' => '106','studyDbId' => '165'},{'studyDbId' => '165','observationUnitPUI' => '107','germplasmDbId' => '41280','trialDbId' => '','externalReferences' => [],'treatments' => [{'factor' => 'No ManagementFactor','modality' => ''}],'observationUnitPosition' => {'geoCoordinates' => '','observationLevel' => {'levelName' => 'plot','levelCode' => '107','levelOrder' => 2},'entryType' => 'test','positionCoordinateY' => undef,'positionCoordinateXType' => 'GRID_COL','positionCoordinateYType' => 'GRID_ROW','positionCoordinateX' => undef,'observationLevelRelationships' => [{'levelName' => 'replicate','levelCode' => '1','levelOrder' => 0},{'levelName' => 'block','levelCode' => '1','levelOrder' => 1},{'levelCode' => '107','levelName' => 'plot','levelOrder' => 2},{'levelOrder' => 4,'levelCode' => undef,'levelName' => 'plant'}]},'programName' => 'test','trialName' => undef,'observations' => [],'additionalInfo' => {},'germplasmName' => 'TMEB693','programDbId' => '134','observationUnitName' => 'CASS_6Genotypes_107','studyName' => 'CASS_6Genotypes_Sampling_2015','locationName' => 'test_location','locationDbId' => '23','observationUnitDbId' => '41298'},{'trialName' => undef,'observations' => [],'additionalInfo' => {},'programDbId' => '134','germplasmName' => 'BLANK','studyName' => 'CASS_6Genotypes_Sampling_2015','observationUnitName' => 'CASS_6Genotypes_201','locationDbId' => '23','locationName' => 'test_location','observationUnitDbId' => '41299','studyDbId' => '165','observationUnitPUI' => '201','germplasmDbId' => '40326','trialDbId' => '','externalReferences' => [],'observationUnitPosition' => {'positionCoordinateX' => undef,'positionCoordinateYType' => 'GRID_ROW','observationLevelRelationships' => [{'levelOrder' => 0,'levelName' => 'replicate','levelCode' => '1'},{'levelName' => 'block','levelCode' => '2','levelOrder' => 1},{'levelOrder' => 2,'levelName' => 'plot','levelCode' => '201'},{'levelName' => 'plant','levelCode' => undef,'levelOrder' => 4}],'geoCoordinates' => '','observationLevel' => {'levelName' => 'plot','levelCode' => '201','levelOrder' => 2},'positionCoordinateXType' => 'GRID_COL','entryType' => 'test','positionCoordinateY' => undef},'treatments' => [{'modality' => '','factor' => 'No ManagementFactor'}],'programName' => 'test'},{'observationUnitPosition' => {'observationLevelRelationships' => [{'levelName' => 'replicate','levelCode' => '1','levelOrder' => 0},{'levelOrder' => 1,'levelName' => 'block','levelCode' => '2'},{'levelCode' => '202','levelName' => 'plot','levelOrder' => 2},{'levelName' => 'plant','levelCode' => undef,'levelOrder' => 4}],'positionCoordinateX' => undef,'positionCoordinateYType' => 'GRID_ROW','positionCoordinateXType' => 'GRID_COL','entryType' => 'test','positionCoordinateY' => undef,'observationLevel' => {'levelCode' => '202','levelName' => 'plot','levelOrder' => 2},'geoCoordinates' => ''},'treatments' => [{'modality' => '','factor' => 'No ManagementFactor'}],'externalReferences' => [],'programName' => 'test','observationUnitPUI' => '202','studyDbId' => '165','germplasmDbId' => '41280','trialDbId' => '','locationDbId' => '23','locationName' => 'test_location','observationUnitDbId' => '41300','additionalInfo' => {},'observations' => [],'trialName' => undef,'programDbId' => '134','germplasmName' => 'TMEB693','studyName' => 'CASS_6Genotypes_Sampling_2015','observationUnitName' => 'CASS_6Genotypes_202'},{'locationDbId' => '23','locationName' => 'test_location','observationUnitDbId' => '41301','germplasmName' => 'IITA-TMS-IBA980002','programDbId' => '134','additionalInfo' => {},'trialName' => undef,'observations' => [],'observationUnitName' => 'CASS_6Genotypes_203','studyName' => 'CASS_6Genotypes_Sampling_2015','treatments' => [{'modality' => '','factor' => 'No ManagementFactor'}],'observationUnitPosition' => {'geoCoordinates' => '','observationLevel' => {'levelOrder' => 2,'levelCode' => '203','levelName' => 'plot'},'positionCoordinateXType' => 'GRID_COL','positionCoordinateY' => undef,'entryType' => 'test','positionCoordinateX' => undef,'positionCoordinateYType' => 'GRID_ROW','observationLevelRelationships' => [{'levelOrder' => 0,'levelName' => 'replicate','levelCode' => '1'},{'levelCode' => '2','levelName' => 'block','levelOrder' => 1},{'levelOrder' => 2,'levelCode' => '203','levelName' => 'plot'},{'levelOrder' => 4,'levelName' => 'plant','levelCode' => undef}]},'externalReferences' => [],'programName' => 'test','observationUnitPUI' => '203','studyDbId' => '165','trialDbId' => '','germplasmDbId' => '41282'},{'observationUnitPUI' => '204','studyDbId' => '165','trialDbId' => '','germplasmDbId' => '41283','treatments' => [{'modality' => '','factor' => 'No ManagementFactor'}],'observationUnitPosition' => {'positionCoordinateYType' => 'GRID_ROW','positionCoordinateX' => undef,'observationLevelRelationships' => [{'levelOrder' => 0,'levelName' => 'replicate','levelCode' => '1'},{'levelOrder' => 1,'levelName' => 'block','levelCode' => '2'},{'levelCode' => '204','levelName' => 'plot','levelOrder' => 2},{'levelOrder' => 4,'levelName' => 'plant','levelCode' => undef}],'observationLevel' => {'levelName' => 'plot','levelCode' => '204','levelOrder' => 2},'positionCoordinateY' => undef,'entryType' => 'test','positionCoordinateXType' => 'GRID_COL','geoCoordinates' => ''},'externalReferences' => [],'programName' => 'test','germplasmName' => 'IITA-TMS-IBA980581','programDbId' => '134','additionalInfo' => {},'trialName' => undef,'observations' => [],'studyName' => 'CASS_6Genotypes_Sampling_2015','observationUnitName' => 'CASS_6Genotypes_204','locationDbId' => '23','locationName' => 'test_location','observationUnitDbId' => '41302'},{'observationUnitDbId' => '41285','locationName' => 'test_location','locationDbId' => '23','observationUnitName' => 'CASS_6Genotypes_205','studyName' => 'CASS_6Genotypes_Sampling_2015','germplasmName' => 'IITA-TMS-IBA011412','programDbId' => '134','additionalInfo' => {},'observations' => [],'trialName' => undef,'programName' => 'test','treatments' => [{'modality' => '','factor' => 'No ManagementFactor'}],'observationUnitPosition' => {'observationLevelRelationships' => [{'levelCode' => '1','levelName' => 'replicate','levelOrder' => 0},{'levelCode' => '2','levelName' => 'block','levelOrder' => 1},{'levelOrder' => 2,'levelName' => 'plot','levelCode' => '205'},{'levelName' => 'plant','levelCode' => undef,'levelOrder' => 4}],'positionCoordinateYType' => 'GRID_ROW','positionCoordinateX' => undef,'geoCoordinates' => '','positionCoordinateY' => undef,'entryType' => 'test','positionCoordinateXType' => 'GRID_COL','observationLevel' => {'levelOrder' => 2,'levelName' => 'plot','levelCode' => '205'}},'externalReferences' => [],'trialDbId' => '','germplasmDbId' => '41281','observationUnitPUI' => '205','studyDbId' => '165'}]}});

done_testing();