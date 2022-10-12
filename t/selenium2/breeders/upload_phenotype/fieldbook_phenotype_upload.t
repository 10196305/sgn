use lib 't/lib';

use Test::More 'tests' => 83;

use SGN::Test::WWW::WebDriver;
use SGN::Test::Fixture;

my $f = SGN::Test::Fixture->new();
my $t = SGN::Test::WWW::WebDriver->new();

$t->while_logged_in_as("submitter", sub { 
    sleep(2);

    $t->get_ok('/breeders/trial/137');
    sleep(4);

    $t->find_element_ok("trial_upload_files_onswitch", "id", "click on upload_fieldbook_link ")->click();
    sleep(1);

    $t->find_element_ok("upload_fieldbook_phenotypes_link", "id", "click on upload_fieldbook_link ")->click();
    sleep(2);

    my $upload_input = $t->find_element_ok("upload_fieldbook_phenotype_file_input", "id", "find file input");
    sleep(4);

    # Change from fieldbook_phenotype_file.csv to fieldbook_phenotype_file_no_fieldbook_image.csv
    # For some reasons, fieldbook_image traits are returned as invalid. Don't know why there is no
    # list of valid traits in the documentation or changes in the valid list.
    # In fieldbook_phenotype_file_no_fieldbook_image two last rows with fieldbook_image traits were removed

    $t->find_element_ok("upload_fieldbook_phenotype_data_level", "id", "find fieldbook phenotype data level select")->click();
    sleep(1);
    $t->find_element_ok('//select[@id="upload_fieldbook_phenotype_data_level"]/option[@value="plots"]', 'xpath', "Select 'plots' as value of phenotype data level")->click();

    my $filename = $f->config->{basepath}."/t/data/fieldbook/fieldbook_phenotype_file_no_fieldbook_image.csv";
    $t->driver()->upload_file($filename);
    $upload_input->send_keys($filename);
    sleep(1);

    $t->find_element_ok("upload_fieldbook_phenotype_submit_verify", "id", "submit spreadsheet file for verification")->click();
    sleep(3);

    my $verify_status = $t->find_element_ok(
        "upload_phenotype_fieldbook_verify_status",
        "id", "verify the verification")->get_attribute('innerHTML');

    ok($verify_status =~ /File fieldbook_phenotype_file_no_fieldbook_image.csv saved in archive./, "Verify the positive validation");
    ok($verify_status =~ /File valid: fieldbook_phenotype_file_no_fieldbook_image.csv./, "Verify the positive validation");
    ok($verify_status =~ /File data successfully parsed./, "Verify the positive validation");
    ok($verify_status =~ /File data verified. Plot names and trait names are valid./, "Verify the positive validation");

    $t->find_element_ok("upload_fieldbook_phenotype_submit_store", "id", "submit spreadsheet file for storage")->click();
    sleep(10);

    $verify_status = $t->find_element_ok(
        "upload_phenotype_fieldbook_verify_status",
        "id", "verify the verification")->get_attribute('innerHTML');

    ok($verify_status =~ /File data successfully parsed./, "Verify the positive store validation");
    ok($verify_status =~ /All values in your file have been successfully processed!/, "Verify the positive store validation");
    ok($verify_status =~ /Metadata saved for archived file./, "Verify the positive store validation");
    ok($verify_status =~ /Upload Successfull!/, "Verify the positive store validation");

    $t->get_ok('/breeders/trial/137');
    sleep(2);

    $t->find_element_ok("trial_upload_files_onswitch", "id", "click on upload_fieldbook_link ")->click();
    sleep(2);

    $t->find_element_ok("upload_fieldbook_phenotypes_link", "id", "click on upload_spreadsheet_link ")->click();
    sleep(4);

    $t->find_element_ok("upload_fieldbook_phenotype_data_level", "id", "find fieldbook phenotype data level select")->click();
    sleep(1);

    $t->find_element_ok('//select[@id="upload_fieldbook_phenotype_data_level"]/option[@value="plots"]', 'xpath', "Select 'plots' as value of phenotype data level")->click();

    $upload_input = $t->find_element_ok("upload_fieldbook_phenotype_file_input", "id", "find file input");
    $filename = $f->config->{basepath}."/t/data/fieldbook/fieldbook_phenotype_file_no_fieldbook_image.csv";
    $t->driver()->upload_file($filename);
    $upload_input->send_keys($filename);
    sleep(1);

    $t->find_element_ok("upload_fieldbook_phenotype_submit_verify", "id", "submit spreadsheet file for verification")->click();
    sleep(3);

    $verify_status = $t->find_element_ok(
        "upload_phenotype_fieldbook_verify_status",
        "id", "verify the verification")->get_attribute('innerHTML');

    ok($verify_status =~ /Warnings are shown in yellow. Either fix the file and try again/, "Verify warnings after store validation");
    ok($verify_status =~ /If you continue, by default any new values will be uploaded/, "Verify warnings after store validation");
    ok($verify_status =~ /To overwrite previously stored values instead/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial21 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /trait dry matter content|CO_334:0000092/, "Verify warnings after store validation");
    ok($verify_status =~ /trait dry yield|CO_334:0000014/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial210 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial211 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial212 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial213 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial215 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial22 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial23 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial24 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial25 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial26 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial27 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial28 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial29 already has the same value as in your file/, "Verify warnings after store validation");

    $t->find_element_ok("upload_fieldbook_phenotype_submit_store", "id", "submit spreadsheet file for storage")->click();
    sleep(10);

    $verify_status = $t->find_element_ok(
        "upload_phenotype_fieldbook_verify_status",
        "id", "verify the verification")->get_attribute('innerHTML');

    ok($verify_status =~ /0 new values stored/, "Verify warnings after store validation");
    ok($verify_status =~ /28 previously stored values skipped/, "Verify warnings after store validation");
    ok($verify_status =~ /0 previously stored values overwritten/, "Verify warnings after store validation");
    ok($verify_status =~ /Upload Successfull!/, "Verify warnings after store validation");

    $t->get_ok('/fieldbook');
    sleep(2);

    $t->find_element_ok("upload_fieldbook_phenotypes_link", "id", "click on upload_spreadsheet_link ")->click();
    sleep(4);

    $t->find_element_ok("upload_fieldbook_phenotype_data_level", "id", "find fieldbook phenotype data level select")->click();
    sleep(1);

    $t->find_element_ok('//select[@id="upload_fieldbook_phenotype_data_level"]/option[@value="plots"]', 'xpath', "Select 'plots' as value of phenotype data level")->click();

    $upload_input = $t->find_element_ok("upload_fieldbook_phenotype_file_input", "id", "find file input");
    $filename = $f->config->{basepath}."/t/data/fieldbook/fieldbook_phenotype_file_no_fieldbook_image.csv";
    $t->driver()->upload_file($filename);
    $upload_input->send_keys($filename);
    sleep(1);

    $t->find_element_ok("upload_fieldbook_phenotype_submit_verify", "id", "submit spreadsheet file for verification")->click();
    sleep(3);

    $verify_status = $t->find_element_ok(
        "upload_phenotype_fieldbook_verify_status",
        "id", "verify the verification")->get_attribute('innerHTML');

    ok($verify_status =~ /Warnings are shown in yellow. Either fix the file and try again/, "Verify warnings after store validation");
    ok($verify_status =~ /If you continue, by default any new values will be uploaded/, "Verify warnings after store validation");
    ok($verify_status =~ /To overwrite previously stored values instead/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial21 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /trait dry matter content|CO_334:0000092/, "Verify warnings after store validation");
    ok($verify_status =~ /trait dry yield|CO_334:0000014/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial210 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial211 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial212 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial213 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial215 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial22 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial23 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial24 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial25 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial26 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial27 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial28 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial29 already has the same value as in your file/, "Verify warnings after store validation");

    $t->find_element_ok("upload_fieldbook_phenotype_submit_store", "id", "submit spreadsheet file for storage")->click();
    sleep(10);

    $verify_status = $t->find_element_ok(
        "upload_phenotype_fieldbook_verify_status",
        "id", "verify the verification")->get_attribute('innerHTML');

    ok($verify_status =~ /0 new values stored/, "Verify warnings after store validation");
    ok($verify_status =~ /28 previously stored values skipped/, "Verify warnings after store validation");
    ok($verify_status =~ /0 previously stored values overwritten/, "Verify warnings after store validation");
    ok($verify_status =~ /Upload Successfull!/, "Verify warnings after store validation");
   
    }
);

$t->driver()->close();
$f->clean_up_db();
done_testing();
