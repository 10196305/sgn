/*jslint browser: true, devel: true */

/**

=head1 UploadTrial.js

Dialogs for uploading trials


=head1 AUTHOR

Jeremy D. Edwards <jde22@cornell.edu>

=cut

*/

var $j = jQuery.noConflict();

jQuery(document).ready(function ($) {

let uniqueTrials = {};
let trialData = {};
document.getElementById('multiple_trial_designs_upload_file').addEventListener("change", handleFileAsync, false);

    var trial_id;
    var plants_per_plot;
    var inherits_plot_treatments;
    jQuery('#upload_trial_trial_sourced').change(function(){
        if(jQuery(this).val() == 'yes'){
            jQuery('#upload_trial_source_trial_section').show();
        } else {
            jQuery('#upload_trial_source_trial_section').hide();
        }
    });

    jQuery('#trial_upload_breeding_program').change(function(){
        populate_upload_trial_linkage_selects();
    });

    function populate_upload_trial_linkage_selects(){
        get_select_box('trials', 'upload_trial_trial_source', {'id':'upload_trial_trial_source_select', 'name':'upload_trial_trial_source_select', 'breeding_program_name':jQuery('#trial_upload_breeding_program').val(), 'multiple':1, 'empty':1} );
    }

    function upload_trial_validate_form(){
        var trial_name = $("#trial_upload_name").val();
        var breeding_program = $("#trial_upload_breeding_program").val();
        var location = $("#trial_upload_location").val();
        var trial_year = $("#trial_upload_year").val();
        var description = $("#trial_upload_description").val();
        var design_type = $("#trial_upload_design_method").val();
        var uploadFile = $("#trial_uploaded_file").val();
        var trial_stock_type = $("#trial_upload_trial_stock_type").val();
        var plot_width = $("#trial_upload_plot_width").val();
        var plot_length = $("#trial_upload_plot_length").val();
        plants_per_plot = $("#trial_upload_plant_entries").val();
        inherits_plot_treatments = $('#trial_upload_plants_per_plot_inherit_treatments').val();


        if (trial_name === '') {
            alert("Please give a trial name");
        }
        else if (breeding_program === '') {
            alert("Please give a breeding program");
        }
        else if (location === '') {
            alert("Please give a location");
        }
        else if (trial_year === '') {
            alert("Please give a trial year");
        }
        else if (plot_width < 0 ){
            alert("Please check the plot width");
        }
        else if (plot_width > 13){
            alert("Please check the plot width is too high");
        }
        else if (plot_length < 0){
            alert("Please check the plot length");
        }
        else if (plot_length > 13){
            alert("Please check the plot length is too high");
        }
        else if (plants_per_plot > 500) {
            alert("Please no more than 500 plants per plot.");
        }
        else if (description === '') {
            alert("Please give a description");
        }
        else if (trial_stock_type === '') {
            alert("Please select stock type being evaluated in trial");
        }
        else if (design_type === '') {
            alert("Please give a design type");
        }
        else if (uploadFile === '') {
            alert("Please select a file");
        }
        else {
            verify_upload_trial_name(trial_name);
        }
    }

    function verify_upload_trial_name(trial_name){
        jQuery.ajax( {
            url: '/ajax/trial/verify_trial_name?trial_name='+trial_name,
            beforeSend: function() {
                jQuery("#working_modal").modal("show");
            },
            success: function(response) {
                console.log(response);
                jQuery("#working_modal").modal("hide");
                if (response.error){
                    alert(response.error);
                    jQuery('[name="upload_trial_submit_first"]').attr('disabled', true);
                    jQuery('[name="upload_trial_submit_second"]').attr('disabled', true);
                }
                else {
                    jQuery('[name="upload_trial_submit_first"]').attr('disabled', false);
                    jQuery('[name="upload_trial_submit_second"]').attr('disabled', false);
                }
            },
            error: function(response) {
                jQuery("#working_modal").modal("hide");
                alert('An error occurred checking trial name');
            }
        });
    }

    function upload_trial_file() {
        $('#upload_trial_form').attr("action", "/ajax/trial/upload_trial_file");
        $("#upload_trial_form").submit();
    }

    function open_upload_trial_dialog() {
        $('#upload_trial_dialog').modal("show");
        //add a blank line to design method select dropdown that dissappears when dropdown is opened
        $("#trial_upload_design_method").prepend("<option value=''></option>").val('');
        $("#trial_upload_design_method").one('mousedown', function () {
            $("option:first", this).remove();
            $("#trial_design_more_info").show();
            //trigger design method change events in case the first one is selected after removal of the first blank select item
            $("#trial_upload_design_method").change();
        });

        //reset previous selections
        $("#trial_upload_design_method").change();
    }

    function add_plants_per_plot() {
        if (plants_per_plot && plants_per_plot != 0) {
            jQuery.ajax( {
                url: '/ajax/breeders/trial/'+trial_id+'/create_plant_entries/',
                type: 'POST',
                data: {
                    'plants_per_plot' : plants_per_plot,
                    'inherits_plot_treatments' : inherits_plot_treatments,
                },
                success: function(response) {
                    console.log(response);
                    if (response.error) {
                    alert(response.error);
                    }
                    else {
                    jQuery('#add_plants_dialog').modal("hide");
                    }
                },
                error: function(response) {
                    alert(response);
                },
                });
        }
    }


    $('[name="upload_trial_link"]').click(function () {
        get_select_box('years', 'trial_upload_year', {'auto_generate': 1 });
        get_select_box('trial_types', 'trial_upload_trial_type', {'empty': 1 });
        populate_upload_trial_linkage_selects();
        open_upload_trial_dialog();
    });

    $('#upload_trial_validate_form_button').click(function(){
        upload_trial_validate_form();
    });

    $('[name="upload_trial_submit_first"]').click(function () {
        upload_trial_file();
    });

    $('[name="upload_trial_submit_second"]').click(function () {
        upload_trial_file();
    });

    $('#multiple_trial_designs_upload_submit').click(function () {
        console.log("Registered click on multiple_trial_designs_upload_submit button");
        upload_multiple_trial_designs_file();
    });

    $("#upload_single_trial_design_format_info").click( function () {
        $("#trial_upload_spreadsheet_info_dialog" ).modal("show");
    });

    $("#upload_multiple_trial_designs_format_info").click( function () {
        $("#multiple_trial_upload_spreadsheet_info_dialog" ).modal("show");
    });

    $('#upload_trial_form').iframePostForm({
        json: true,
        post: function () {
            var uploadedTrialLayoutFile = $("#trial_uploaded_file").val();
            $('#working_modal').modal("show");
            if (uploadedTrialLayoutFile === '') {
                $('#working_modal').modal("hide");
                alert("No file selected");
                return;
            }
        },
        complete: function (response) {
            trial_id = response.trial_id;
            console.log(response);

            $('#working_modal').modal("hide");
            if (response.error) {
                alert(response.error);
                return;
            }
            else if (response.error_string) {

                if (response.missing_accessions) {
                    jQuery('#upload_trial_missing_accessions_div').show();
                    var missing_accessions_html = "<div class='well well-sm'><h3>Add the missing accessions to a list</h3><div id='upload_trial_missing_accessions' style='display:none'></div><div id='upload_trial_add_missing_accessions'></div></div><br/>";
                    $("#upload_trial_add_missing_accessions_html").html(missing_accessions_html);

                    var missing_accessions_vals = '';
                    for(var i=0; i<response.missing_accessions.length; i++) {
                        missing_accessions_vals = missing_accessions_vals + response.missing_accessions[i] + '\n';
                    }
                    $("#upload_trial_missing_accessions").html(missing_accessions_vals);
                    addToListMenu('upload_trial_add_missing_accessions', 'upload_trial_missing_accessions', {
                        selectText: true,
                        listType: 'accessions'
                    });
                } else {
                    jQuery('#upload_trial_missing_accessions_div').hide();
                    var no_missing_accessions_html = '<button class="btn btn-primary" onclick="Workflow.skip(this);">There were no errors regarding missing accessions Click Here</button><br/><br/>';
                    jQuery('#upload_trial_no_error_messages_html').html(no_missing_accessions_html);
                    Workflow.skip('#upload_trial_missing_accessions_div', false);
                }

                if (response.missing_seedlots) {
                    jQuery('#upload_trial_missing_seedlots_div').show();
                } else {
                    jQuery('#upload_trial_missing_seedlots_div').hide();
                    var no_missing_seedlot_html = '<button class="btn btn-primary" onclick="Workflow.skip(this);">There were no errors regarding missing seedlots Click Here</button><br/><br/>';
                    jQuery('#upload_trial_no_error_messages_seedlot_html').html(no_missing_seedlot_html);
                    Workflow.skip('#upload_trial_missing_seedlots_div', false);
                }

                $("#upload_trial_error_display tbody").html(response.error_string);
                //$("#upload_trial_error_display_seedlot tbody").html(response.error_string);
                $("#upload_trial_error_display_second_try").show();
                $("#upload_trial_error_display_second_try tbody").html(response.error_string);
            }
            if (response.missing_accessions){
                Workflow.focus("#trial_upload_workflow", 4);
            } else if(response.missing_seedlots){
                Workflow.focus("#trial_upload_workflow", 5);
            } else if(response.error_string){
                Workflow.focus("#trial_upload_workflow", 6);
                $("#upload_trial_error_display_second_try").show();
            }
            if (response.warnings) {
                alert(response.warnings);
            }
            if (response.success) {
                refreshTrailJsTree(0);
                jQuery("#upload_trial_error_display_second_try").hide();
                jQuery('#trial_upload_show_repeat_upload_button').hide();
                jQuery('[name="upload_trial_completed_message"]').html('<button class="btn btn-primary" name="upload_trial_success_complete_button">The trial was saved to the database with no errors! Congrats Click Here</button><br/><br/>');
                Workflow.skip('#upload_trial_missing_accessions_div', false);
                Workflow.skip('#upload_trial_missing_seedlots_div', false);
                Workflow.skip('#upload_trial_error_display_second_try', false);
                Workflow.focus("#trial_upload_workflow", -1); //Go to success page
                Workflow.check_complete("#trial_upload_workflow");
                add_plants_per_plot();
            }
        }
    });

    jQuery('#upload_multiple_trials_success_button').on('click', function(){
        //alert('Trial was saved in the database');
        jQuery('#upload_trial_dialog').modal('hide');
        location.reload();
    });

    jQuery(document).on('click', 'button[name="upload_trial_success_complete_button"]', function(){
        //alert('Trial was saved in the database');
        jQuery('#upload_trial_dialog').modal('hide');
        location.reload();
    });

    async function handleFileAsync(e) {
      const file = e.target.files[0];
      const data = await file.arrayBuffer();
      const wb = XLSX.read(data);

      console.log("converting to JSON");
      console.log(XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]]));
      allData = XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]]);
      uniqueTrials = allData.uniqueTrials; //extract from upload file
      trialData = allData.trialData; // extract from upload file
    }

});

// Add function to parse multi-trial upload file with onchange event, and store parsed file data in JSON

function upload_multiple_trial_designs_file(trialJSON) {
  jQuery("#upload_multiple_trials_warning_messages").html('');
  jQuery("#upload_multiple_trials_error_messages").html('');
  jQuery("#upload_multiple_trials_success_messages").html('');

  jQuery('#progress_msg').text('Preparing trials for upload');
  jQuery('#progress_bar').css("width", "0%")
  .attr("aria-valuenow", 0)
  .text("0%");
  jQuery('#progress_modal').modal('show');

  loadAllTrials(uniqueTrials, trialData).done(function(result) {
      // console.log("Result from promise is: "+JSON.stringify(result));
      jQuery('#progress_modal').modal('hide');
      reportStoreResult(result);
  })
  .fail(function(error) {
      console.log(error);
      jQuery('#upload_multiple_trials_status').append(
          formatMessage(error, 'error')
      );
  });

}

function reportStoreResult(result) {
    // console.log("result is: "+JSON.stringify(result));
    if (result.success && result.success.length > 0) {
        jQuery('#upload_multiple_trials_status').html(
            formatMessage(result.success, 'success')
        );
    }
    if (result.error && result.error.length > 0) {
        jQuery('#upload_multiple_trials_status').html(
            formatMessage(result.error, 'error')
        );
    }
    jQuery('#working_modal').modal("hide");
}

function loadAllTrials(uniqueTrials, trialData){
    return loadImagesSequentially(uniqueTrials, trialData, {"success":[],"error":[]} );
}

function loadTrialsSequentially(uniqueTrials, trialData, uploadStatus){

    return loadSingleTrial(uniqueTrials, trialData).then(function(response) {
        // console.log("load single image response is: " +JSON.stringify(response));

        if (response.result) {
            var msg = "Successfly uploaded trial "+response.result.data[0].studyName;
            uploadStatus.success.push(msg);
        } else {
            // console.log("handling response errors: "+JSON.stringify(response.metadata.status));
            response.metadata.status.forEach(function(msg) {
              if (msg.messageType == "ERROR") { uploadStatus.error.push(msg.message); }
            });
            return uploadStatus;
        }

        trialData.shift();

        if (trialData.length < 1) {
            // console.log("We've shifted through and loaded all "+uniqueTrials.length+" trials");
            return uploadStatus;
        } else {
            return loadTrialsSequentially(uniqueTrials, trialData, uploadStatus);
        }

    });

}

function loadSingleTrial(uniqueTrials, trialData, uploadStatus){

    var currentTrial = uniqueTrials.length - trialData.length;
    var total = uniqueTrials.length;
    var file = uniqueTrials[currentTrial];
    var trial = trialData[0];
    var trialMetadata = trial.metadata;
    var trialLayout = trial.layout;

    currentTrial++;
    jQuery('#progress_msg').html('<p class="form-group text-center">Working on trial '+currentTrial+' out of '+total+'</p>');
    jQuery('#progress_msg').append('<p class="form-group text-center"><b>'+trial.studyName+'</b></p>')
    var progress = Math.round((currentTrial / total) * 100)
    jQuery('#progress_bar').css("width", progress + "%")
    .attr("aria-valuenow", progress)
    .text(progress + "%");

    return jQuery.ajax( {
        /* structure of trialMetadata obj
        [{
            "endDate": harvest_date,
            "startDate": planting_date,
            "studyType": trial_type,
            "studyName": trial_name,
            "studyDescription": description,
            "trialDbId": breeding_program, #convert from trialName to trialDbId
            "locationDbId": location,  #convert from locationName to locationDbId
            "seasons": ["year"],
            "additionalInfo": {
                "field_size": field_size,
                "plot_width": plot_width,
                "plot_length": plot_length
            },
            "experimentalDesign": {
                "PUI": design_type
            }
        }] */
        url: "/brapi/v2/studies",
        method: 'POST',
        headers: { "Authorization": "Bearer "+jQuery.cookie("sgn_session_id") },
        data: JSON.stringify([trialMetadata]),
        contentType: "application/json; charset=utf-8"
    }).success(function(response){
        trialLayout.studyDbId = response.result.data[0].studyDbId;
        jQuery.ajax( {
            /* structure of trialLayout obj
            [{
                "studyDbId": get from saved study,
                "observationUnitName": plot_name,
                "germplasmName": accession_name,
                "programName": breeding_program,
                "seedlotName": seedlot_name,
                "observationUnitPosition": {
                    "positionCoordinateX": row_number,
                    "positionCoordinateY": col_number,
                    "observationLevel": {
                        "levelName": "plot",
                        "levelCode": plot_number,
                    },
                    "observationLevelRelationships": {
                            {
                                "levelCode": block_number,
                                "levelName": "block",
                                "levelOrder": 1
                            },
                            {
                                "levelCode": rep_number,
                                "levelName": "replicate",
                                "levelOrder": 1
                            }
                    },
                },
                "additionalInfo": {
                    "control": is_a_control,
                    "range": range_number,
                    "num_seed_per_plot": num_seed_per_plot,
                    "weight_gram_seed_per_plot": weight_gram_seed_per_plot,
                }
            }, {...}] */
            url: "/brapi/v2/observationunits",
            method: 'POST',
            async: false,
            headers: { "Authorization": "Bearer "+jQuery.cookie("sgn_session_id") },
            data: JSON.stringify([trialLayout]),
            contentType: "application/json; charset=utf-8"
        });
    });
}
