{*-------------------------------------------------------+
| Project 60 - SEPA direct debit                         |
| Copyright (C) 2013-2014 SYSTOPIA                       |
| Author: B. Endres (endres -at- systopia.de)            |
| http://www.systopia.de/                                |
+--------------------------------------------------------+
| This program is released as free software under the    |
| Affero GPL license. You can redistribute it and/or     |
| modify it under the terms of this license which you    |
| can read by viewing the included agpl.txt or online    |
| at www.gnu.org/licenses/agpl.html. Removal of this     |
| copyright header is strictly prohibited without        |
| written permission from the original author(s).        |
+-------------------------------------------------------*}

{if $pre4_6_10}
{* add these fields manually for 4.4.x - 4.6.9 *}
<!-- this field is hidden by default, so people wouldn't worry about it. Feel free to show via a customisation extension -->
<div id="sdd-cycle-day-section" class="crm-section {$form.cycle_day.name}-section" style="display: none;">
  <div class="label">{$form.cycle_day.label}</div>
  <div class="content">{$form.cycle_day.html}</div>
  <div class="clear"></div>
</div>

<!-- this field is hidden by default, so people wouldn't worry about it. Feel free to show via a customisation extension -->
<div id="sdd-start-date-section" class="crm-section {$form.start_date.name}-section" style="display: none;">
  <div class="label">{$form.start_date.label}</div>
  <div class="content">{$form.start_date.html}</div>
  <div class="clear"></div>
</div>

{literal}
<script type="text/javascript">
// in 4.4.x - 4.6.9 we could still ignore this (not mandatory)
cj(function(){
  cj("fieldset.billing_name_address-group").hide();
});
</script>
{/literal}
{/if}

{if $sepa_hide_billing}
{literal}
<script type="text/javascript">
  // If disabled remove the billing group, so no billing address is created
  cj(function(){
    cj("#billingcheckbox").remove();
    cj("label[for='billingcheckbox']").remove();
    cj("fieldset.billing_name_address-group").remove();
  });
</script>
{/literal}
{/if}

<!-- JS Magic -->
<script type="text/javascript">
// translated captions
var earliest_ooff_date = '{$earliest_ooff_date}';
var earliest_rcur_date = '{$earliest_rcur_date}';
var earliest_cycle_day = '{$earliest_cycle_day}';

{literal}

// change elements according to recur status
function _sdd_update_elements() {
	var is_recur = cj("#is_recur").prop('checked');
  var start_date = cj("#start_date");
	if (is_recur) {
    if (start_date.val() < earliest_rcur_date) {
      start_date.val(earliest_rcur_date);
    }
	} else {
    if (start_date.val() < earliest_ooff_date) {
      start_date.val(earliest_ooff_date);
    }
	}
}

cj(function() {
  // set cycle_day, and hide start_date/cycle_day
  cj("#cycle_day").val(earliest_cycle_day);
  cj("#start_date").parent().parent().hide();
  cj("#cycle_day").parent().parent().hide();

	// add event handler for IBAN entered
	cj("#bank_account_number").change(sepa_process_iban);

  // add event handler for rcur checkbox
  cj("#is_recur").change(_sdd_update_elements);

  // ... but also update SDD elements now
  _sdd_update_elements();

  cj('#validateACSC').appendTo('.ukbank_sort_code-section .content');
  cj('#validateACSCMsg').appendTo('.ukbank_sort_code-section .content');
  cj('#validateACSC').show();
});

// IBAN changed handler
function sepa_process_iban() {
	var reSpaceAndMinus = new RegExp('[\\s-]', 'g');
	var sanitized_iban = cj("#bank_account_number").val();
	sanitized_iban = sanitized_iban.replace(reSpaceAndMinus, "");
	sanitized_iban = sanitized_iban.toUpperCase();
	cj("#bank_account_number").val(sanitized_iban);
	{/literal}{if $bic_extension_installed}
	sepa_lookup_bic();
	{/if}{literal}
}

</script>
{/literal}

{if $bic_extension_installed}
<script type="text/javascript">
var busy_icon_url = "{$config->resourceBase}i/loading.gif";
var sepa_hide_bic_enabled = parseInt("{$sepa_hide_bic}");
var sepa_lookup_bic_error_message = "{ts domain="org.project60.sepa"}Bank unknown, please enter BIC.{/ts}";
var sepa_lookup_bic_timerID = 0;
var sepa_lookup_bic_timeout = 1000;
{literal}

cj(function() {
	cj("#bank_account_number").parent().append('&nbsp;<img id="bic_busy" height="12" src="' + busy_icon_url + '"/>');
	cj("#bank_account_number").on("input click keydown blur", function() {
		// set the timer to look up BIC when user stops typing
		if (sepa_lookup_bic_timerID) {
			// clear any existing lookup timers
			clearTimeout(sepa_lookup_bic_timerID);
			sepa_lookup_bic_timerID = 0;
		}
		sepa_lookup_bic_timerID = window.setTimeout(sepa_lookup_bic, sepa_lookup_bic_timeout);
	});
	cj("#bic_busy").hide();
	// call it once
	sepa_lookup_bic();
});

function sepa_clear_bank() {
  cj("#bank_name").val('');
  cj("#bic_busy").hide();
}

function sepa_show_bic(show_bic, message) {
	if (sepa_hide_bic_enabled) {
		if (show_bic) {
			cj("#bank_identification_number").parent().parent().show();
			cj("#bank_identification_number").parent().find("span.sepa-warning").remove();
			if (message.length) {
				cj("#bank_identification_number").parent().append("<span class='sepa-warning'>&nbsp;&nbsp;" + message + "</span>");
			}
		} else {
			// hide only if no error label attached:
			if (!cj("#bank_identification_number").parent().find("span.crm-error").length) {
				cj("#bank_identification_number").parent().parent().hide();
			}
		}
	}
}

function sepa_lookup_bic() {
	if (sepa_lookup_bic_timerID) {
		// clear any existing lookup timers
		clearTimeout(sepa_lookup_bic_timerID);
		sepa_lookup_bic_timerID = 0;
	}

	var iban_partial = cj("#bank_account_number").val();
	if (iban_partial == undefined || iban_partial.length == 0) return;
	if (sepa_hide_bic_enabled) {
		// if it's hidden, we should clear it at this point
		cj("#bank_identification_number").attr('value', '');
	}
	cj("#bic_busy").show();
	cj("div.payment_processor-section").trigger("sdd_biclookup", "started");
  CRM.api('Bic', 'findbyiban', {'q': 'civicrm/ajax/rest', 'iban': iban_partial},
    {success: function(data) {
    	if ('bic' in data) {
        cj("#bank_identification_number").attr('value', data['bic']);
        cj("#bank_name").val(data['title']);
        cj("#bic_busy").hide();
        cj("div.payment_processor-section").trigger("sdd_biclookup", "success");
        sepa_show_bic(false, "");
      } else {
      	sepa_clear_bank();
        //sepa_show_bic(true, sepa_lookup_bic_error_message);
        sepa_show_bic(true, "");
        cj("#bank_identification_number").attr('value', '');
        cj("div.payment_processor-section").trigger("sdd_biclookup", "failed");
      }
    }, error: function(result, settings) {
			// we suppress the message box here
			// and log the error via console
      cj("#bic_busy").hide();
      cj("div.payment_processor-section").trigger("sdd_biclookup", "failed");
			if (result.is_error) {
				console.log(result.error_message);
				sepa_clear_bank();
				sepa_show_bic(true, result.error_message);
			}
			return false;
		}});
}

// initially hide the bic (if hiding enabled)
cj(function(){
	sepa_show_bic(false, "");	
});
{/literal}
</script>
{/if}

{if $ukbank_acsc_enabled}
{literal}
<script type="text/javascript">
  // js to split sort code into 3 input boxes
  cj(function() {
    cj('#ukbank_sort_code').parent().append('<div id ="ukbank_sort_code_block"></div>');
    cj("#ukbank_sort_code").hide()
    cj("#ukbank_sort_code_block")
    .html('<input type = "text" size = "3" maxlength = "2" name = "ukbank_sort_code_block_1" id = "ukbank_sort_code_block_1" class="ukbank_sort_code_block_x"/>'
      +' - <input type = "text" size = "3" maxlength = "2" name = "ukbank_sort_code_block_2" id = "ukbank_sort_code_block_2" class="ukbank_sort_code_block_x"/>'
      +' - <input type = "text" size = "3" maxlength = "2" name = "ukbank_sort_code_block_3" id = "ukbank_sort_code_block_3" class="ukbank_sort_code_block_x"/>');

    cj("input.ukbank_sort_code_block_x").change(function() {
      updateSortCode();
    });
    cj("input.ukbank_sort_code_block_x").keyup(function () {
      if (this.value.length == this.maxLength) {
        cj(this).next('input.ukbank_sort_code_block_x').focus();
      }
    });
    var fieldValue = cj("#ukbank_sort_code").val();
    if (fieldValue.length >= 1) {
      var fieldSplit = fieldValue.split('');
      var scb = fieldSplit[0] + fieldSplit[1];
      updateSortCodeBlock('#ukbank_sort_code_block_1', scb);

      scb = fieldSplit[2] + fieldSplit[3];
      updateSortCodeBlock('#ukbank_sort_code_block_2', scb);

      scb = fieldSplit[4] + fieldSplit[5];
      updateSortCodeBlock('#ukbank_sort_code_block_3', scb);
    }
  });

  function updateSortCode() {
    var sc1 = cj("input#ukbank_sort_code_block_1").val();
    var sc2 = cj("input#ukbank_sort_code_block_2").val();
    var sc3 = cj("input#ukbank_sort_code_block_3").val();
    var finalFieldValue = sc1 + sc2 + sc3
    cj('#ukbank_sort_code').val(finalFieldValue);
  }

  function updateSortCodeBlock(ele, scb) {
    if (scb.length >= 1) {
      cj(ele).val(scb);
    } else {
      cj(ele).val('');
    }
  }
</script>
{/literal}
{/if}

