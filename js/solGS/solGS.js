/** 
* @class solgs
* general solGS app wide and misc functions
* @author Isaak Y Tecle <iyt2@cornell.edu>
*
*/


JSAN.use('jquery.blockUI');
JSAN.use('jquery.form');


function solGS () {};

solGS.waitPage = function (page) {

    if ( page.match(/solgs\/trait\//)) {
    	askUser(page);
    } else {
    	blockPage(page);
    }
   
}


function  askUser(page) {
       
    var t = '<p>This analysis may take longer than 20 min. ' 
	+ 'Would you like to be emailed when it is done?</p>';
    
    jQuery('<div />')
	.html(t)
	.dialog({
	    height : 200,
	    width  : 400,
	    modal  : true,
	    title  : "Analysis update message",
 	    buttons: {
		No: { text: "No, I will wait...",
                      click: function() { 
			  jQuery(this).dialog("close");
			  
			  displayAnalysisNow(page);
		      },
		    },

		Yes: { text: "Yes", 
                       click: function() {
			   jQuery(this).dialog("close");			  
			 
			   checkUserLogin(page);
		       },
		     }          
	    }
	});
  
}


function checkUserLogin (page) {
    
    jQuery.ajax({
	type    : 'POST',
	dataType: 'json',
	url     : '/solgs/check/user/login/',
	success : function(response) {
            if (response.loggedin) {
		//include in response user data
		
		getProfileDialog(page);
            } else {
		loginAlert();
	    }
	}
	});

}


function loginAlert () {
    
    jQuery('<div />')
	.html('To use this feature, you need to log in and start over the process.')
	.dialog({
	    height : 200,
	    width  : 250,
	    modal  : true,
	    title  : 'Login Alert',
	    buttons: {
		OK: function () {
		    jQuery(this).dialog('close');
		
		    loginUser();
		}
	    }			
	});	    

}
	

function loginUser () {

   window.location = '/solpeople/login.pl?goto_url=' + window.location.pathname;
   
}


function displayAnalysisNow (page) {

    blockPage(page);

 }


function blockPage (page) {
  
    goToPage(page);

    jQuery.blockUI.defaults.applyPlatformOpacityRules = false;
    jQuery.blockUI({message: 'Please wait..'});
         
    jQuery(window).unload(function()  {
	jQuery.unblockUI();            
    }); 
 
}

function getProfileForm () {
  //remove user name; ask for email depending on whether there is one in the db or not.
    var emailForm = '<p>Please fill in your email.</p>'
	+'<table>'
	+ '<tr>'
	+  '<td>Your name:</td>'
	+  '<td><input  type="text" name="user_name" id="user_name"></td>'
	+ '</tr>'
	+ '<tr>'
	+  '<td>Your analysis name:</td>'
	+  '<td><input  type="text" name="analysis_name" id="analysis_name"></td>'
	+  '</tr>'
	+ '<tr>'
	+  '<td>Email:</td>'
	+  '<td><input type="text" name="user_email" id="user_email"></td>' 
	+ '</tr>'
	+'</table>';
   
    return emailForm;
}
 

function getProfileDialog (page) {
    var form = getProfileForm();
    
    jQuery('<div />', {id: 'email-form'})
	.html(form)
	.dialog({	
	    height : 300,
	    width  : 300,
	    modal  : true,
	    title  : 'Submit your email',
 	    buttons: {
		Submit: function() { 
		    var userName     = jQuery('#user_name').val();
		    var userEmail    = jQuery('#user_email').val();
		    var analysisName = jQuery('#analysis_name').val();
		     //validate input
		    var analysisProfile = {
			'user_name'    : userName, 
			'user_email'   : userEmail,
			'analysis_name': analysisName,
			'analysis_page': page
		    }

		    jQuery(this).dialog('close');
		     
		    saveAnalysisProfile(analysisProfile);
		},
		Cancel:  function() {
		    jQuery(this).dialog('close');
		},    
	    }
	});

}


jQuery(document).ready(function (){
   
     jQuery('#runGS').on('click',  function() {
	 
	 var popId = jQuery('#population_id').val(); 
	 var page = '/solgs/analyze/traits/population/' + popId;

	 askUser(page);

     });
    
});


function submitTraitSelections () {
    
    var popId  = jQuery('#population_id').val();
    var formId = ' id="traits_selection_form"';
    var action = ' action="/solgs/analyze/traits/population/' + popId + '"';
    var method = ' method="POST"';
    
    var traitsForm = '<form'
	+ formId
	+ action
	+ method
	+ '>' 
	+ '</form>';

    jQuery('#population_traits_list').wrap(traitsForm);
   
    var value = jQuery("#traits_selection_form :checkbox").fieldValue();
    alert('selected traits: ' + value);
   
    jQuery('#traits_selection_form').ajaxSubmit();
    
}


function goToPage (page) {
     
    

    if (page.match(/solgs\/trait\//)) {
	window.location = page;
    } else if (page.match(/solgs\/analyze\/traits\/population\//)) {
	
	submitTraitSelections();
	
	var popId  = jQuery('#population_id').val();
	window.location = '/solgs/analyze/traits/population/' + popId;
    }
	    
}

// jQuery(document).ready(function() {

//     var traits = [];
//     var selectedTraits = [];

//     jQuery('#population_traits_list tr').on('click',  function() {
     
//         var traitId =  jQuery(this).find(".trait_id").val();
        
//        	if (selectedTraits !== undefined) {
// 		if (jQuery.inArray(traitId, selectedTraits) == -1 ) {
		   
// 		    selectedTraits.push(traitId);
		 
// 		} else {
		   
// 		    selectedTraits = jQuery.grep(selectedTraits, function(value) {
// 			return value != traitId;
// 		    });
// 		}

// 	}  else {
	   
// 	    selectedTraits = traitId;
// 	}  	
//     });

//     jQuery("#runGS").on('click', function(){
// 	var popId = jQuery('#population_id').val();
// 	alert('pop id: ' + popId);
// 	if (selectedTraits[-1] == ',') {
// 	    alert('pop to clean selectedTraits: ' + selectedTraits);
// 	    selectedTraits.pop();
// 	     alert('pop cleaned selectedTraits: ' + selectedTraits);
// 	} else if (selectedTraits[0] == ',') {
	    
// 	    alert('shift to clean selectedTraits: ' + selectedTraits);
// 	    selectedTraits.shift();
// 	     alert('shift cleaned selectedTraits: ' + selectedTraits);
// 	}

// 	if (selectedTraits) {
// 	    alert('selected traits: ' + selectedTraits);
// 	  //  askUser(page);
// 	    if (selectedTraits.length == 1) {
// 		var traitId = selectedTraits[0];
// 		runSingleModel(popId, traitId);
// 		selectedTraits = [];
// 	    } else {
// 		runMultipleModels(popId, selectedTraits);
// 	    	selectedTraits = [];
// 	    }
// 	} else {
	    
// 	    alert('Select Traits first.');
// 	}
    

//     });



//  });


function runSingleModel(popId, traitId) {
    
    if (traitId !== undefined) {
	var page = '/solgs/trait/' + traitId + '/population/' + popId;
	askUser(page);
    } else {
	
	window.location = window.location.href;
    }
}


function runMultipleModels (popId, traitIds) {

    if (traitIds !== undefined) {
	var page = '/solgs/analyze/traits/population/' + popId; 
	var args = {'traitIds': traitIds};
	askUser(page);
    } else {
	window.location = window.location.href;	

    }
   // window.location = {}
    // jQuery.Ajax({
    // 	typee: 'POST',
    // 	dataType: 'json',
    // 	data: {'trait_id': traitIds},
    // 	url: '/solgs/analyze/traits/population' + popId,
    // 	success: function(response){
	    

    // 	},


    // });


}


function saveAnalysisProfile (profile) {
    
    //make an ajax request
    //save analysis details in a file
    //run analysis, when complete, retrieve analysis owner and send an email

    jQuery.ajax({
	type    : 'POST',
	dataType: 'json',
	data    : profile,
	url     : '/solgs/save/analysis/profile/',
	success : function(response) {
            if (response.result) {
		runAnalysis(profile);
		confirmRequest();
	
            } else { 
		jQuery('<div />', {id: 'error-message'})
		    .html('Failed saving your analysis profile.')
		    .dialog({
			height : 200,
			width  : 250,
			modal  : true,
			title  : 'Error message',
			buttons: {
			    OK: function () {
				jQuery(this).dialog('close');
				window.location = window.location.href;
			    }
			}			
		    });
            }
	},
	error: function () {
	    jQuery('<div />')
		.html('Error occured calling the function to save your analysis profile.')
		.dialog({
		    height : 200,
		    width  : 250,
		    modal  : true,
		    title  : 'Error message',
		    buttons: {
			OK: function () {
			    jQuery(this).dialog('close');
			    window.location = window.location.href;
			}
		    }			
		});	    
	}
    });

}


function runAnalysis (profile) {
   
    jQuery.ajax({
	async: true,
	type: 'POST',
	dataType: 'json',
	data: profile,
	url: '/solgs/run/saved/analysis/',
	 success: function () {
	 },	
    });
 
}


function confirmRequest () {
    
    blockPage('/solgs/confirm/request');
 
}


// function confirmRequest () {
//    var m = 'You will receive an email when the analysis is complete.'; 
    
//     jQuery('<div />', {id: 'confirmation-message'})
// 	.html(m)
// 	.dialog({	
// 	    height: 200,
// 	    width:  250,
// 	    modal: true,
// 	    title: 'Request confirmation',
//  	    buttons: {
// 		OK: function() {
// 		    jQuery(this).dialog('close');
	
	 	   
// 		}
// 	    }
// 	});
	
//    //  
// }
//executes two functions alternately
jQuery.fn.alternateFunctions = function(a, b) {
    return this.each(function() {
        var clicked = false;
        jQuery(this).bind("click", function() {
            if (clicked) {
                clicked = false;
                return b.apply(this, arguments);
              
            }
            clicked = true;
             return a.apply(this, arguments);
           
        });
    });
};
//



 //  $(function() {
//     var dialog, form,
 
//       // From http://www.whatwg.org/specs/web-apps/current-work/multipage/states-of-the-type-attribute.html#e-mail-state-%28type=email%29
//       emailRegex = /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/,
//       name = $( "#name" ),
//       email = $( "#email" ),
//       password = $( "#password" ),
//       allFields = $( [] ).add( name ).add( email ).add( password ),
//       tips = $( ".validateTips" );
 
//     function updateTips( t ) {
//       tips
//         .text( t )
//         .addClass( "ui-state-highlight" );
//       setTimeout(function() {
//         tips.removeClass( "ui-state-highlight", 1500 );
//       }, 500 );
//     }
 
//     function checkLength( o, n, min, max ) {
//       if ( o.val().length > max || o.val().length < min ) {
//         o.addClass( "ui-state-error" );
//         updateTips( "Length of " + n + " must be between " +
//           min + " and " + max + "." );
//         return false;
//       } else {
//         return true;
//       }
//     }
 
//     function checkRegexp( o, regexp, n ) {
//       if ( !( regexp.test( o.val() ) ) ) {
//         o.addClass( "ui-state-error" );
//         updateTips( n );
//         return false;
//       } else {
//         return true;
//       }
//     }
 
//     function addUser() {
//       var valid = true;
//       allFields.removeClass( "ui-state-error" );
 
//       valid = valid && checkLength( name, "username", 3, 16 );
//       valid = valid && checkLength( email, "email", 6, 80 );
//       valid = valid && checkLength( password, "password", 5, 16 );
 
//       valid = valid && checkRegexp( name, /^[a-z]([0-9a-z_\s])+$/i, "Username may consist of a-z, 0-9, underscores, spaces and must begin with a letter." );
//       valid = valid && checkRegexp( email, emailRegex, "eg. ui@jquery.com" );
//       valid = valid && checkRegexp( password, /^([0-9a-zA-Z])+$/, "Password field only allow : a-z 0-9" );
 
//       if ( valid ) {
//         $( "#users tbody" ).append( "<tr>" +
//           "<td>" + name.val() + "</td>" +
//           "<td>" + email.val() + "</td>" +
//           "<td>" + password.val() + "</td>" +
//         "</tr>" );
//         dialog.dialog( "close" );
//       }
//       return valid;
//     }
 
//     dialog = $( "#dialog-form" ).dialog({
//       autoOpen: false,
//       height: 300,
//       width: 350,
//       modal: true,
//       buttons: {
//         "Create an account": addUser,
//         Cancel: function() {
//           dialog.dialog( "close" );
//         }
//       },
//       close: function() {
//         form[ 0 ].reset();
//         allFields.removeClass( "ui-state-error" );
//       }
//     });
 
//     form = dialog.find( "form" ).on( "submit", function( event ) {
//       event.preventDefault();
//       addUser();
//     });
 
//     $( "#create-user" ).button().on( "click", function() {
//       dialog.dialog( "open" );
//     });
//   });
//   </script>
// </head>
// <body>
 
