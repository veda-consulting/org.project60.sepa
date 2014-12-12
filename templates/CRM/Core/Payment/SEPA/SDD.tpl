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

<div id="payment_information">
	<fieldset class="billing_mode-group direct_debit_info-group">
	<legend>
	{ts}Direct Debit Information{/ts}
	</legend>

	<div class="crm-section {$form.bank_iban.name}-section">
		<div class="label">{$form.bank_iban.label}</div>
		<div class="content">{$form.bank_iban.html}</div>
		<div class="clear"></div>
	</div>
	<div class="crm-section {$form.bank_bic.name}-section">
		<div class="label">{$form.bank_bic.label}</div>
		<div class="content">{$form.bank_bic.html}</div>
		<div class="clear"></div>
	</div>
	<div class="crm-section {$form.cycle_day.name}-section" hidden="1">
		<!-- this field is hidden by default, so people wouldn't worry about it. Feel free to show via a customisation extension -->
		<div class="label">{$form.cycle_day.label}</div>
		<div class="content">{$form.cycle_day.html}</div>
		<div class="clear"></div>
	</div>
	<div class="crm-section {$form.start_date.name}-section" hidden="1">
		<!-- this field is hidden by default, so people wouldn't worry about it. Feel free to show via a customisation extension -->
		<div class="label">{$form.start_date.label}</div>
		<div class="content">{include file="CRM/common/jcalendar.tpl" elementName=start_date}</div>
		<div class="clear"></div>
	</div>
</div>

<!-- TWEAK THE FORM: -->

<!-- create a better dropdown for intervals -->
<select class="form-select" id="frequency_combined" onChange="sepa_copy_combined()" disabled="disabled" hidden="1">
	<option value="1">{ts}monthly{/ts}</option>
	<option value="3">{ts}quarterly{/ts}</option>
	<option value="6">{ts}semi-annually{/ts}</option>
	<option value="12">{ts}annually{/ts}</option>
</select>

<!-- Additional Elements -->
<span id="currency_indicator" hidden="1"><b>EUR</b></span>

<!-- JS Disclaimer -->
<noscript>
<br/><br/>
<span style="color:#ff0000; font-size:150%; font-style:bold;">{ts}THIS PAGE PAGE DOES NOT WORK PROPERLY WITHOUT JAVASCRIPT. PLEASE ENABLE JAVASCRIPT IN YOUR BROWSER{/ts}</span>
</noscript>

<!-- JS Magic -->
<script type="text/javascript">
// translated captions
var label_months = "{ts}monthly{/ts}";
var label_years = "{ts}yearly{/ts}";
var earliest_ooff_date = new Date({$earliest_ooff_date[0]}, {$earliest_ooff_date[1]} - 1, {$earliest_ooff_date[2]});
var earliest_rcur_date = new Date({$earliest_rcur_date[0]}, {$earliest_rcur_date[1]} - 1, {$earliest_rcur_date[2]});
var currently_set_date = new Date("{$form.start_date.value}");

{literal}
if (cj("#frequency_interval").length) {
	// this is an custom interval page -> replace dropdown altogether
	cj("#frequency_interval").hide();
	cj("#frequency_unit").hide();
	cj("#frequency_combined").show();
	cj("#frequency_combined").insertBefore(cj("#frequency_interval"));

} else {
	// this is a period only page, just update the labels
	var options = cj("#frequency_unit > option");
	for (var i = 0; i < options.length; i++) {
		var option = cj(options[i]);
		if (option.attr('value') == 'month') {
			option.text(label_months);
		} else if (option.attr('value') == 'year') {
			option.text(label_years);
		} else {
			// this module cannot deal with weekly/daily payments
			option.remove();
		}
	}
}

// fix recur label
cj("label[for='is_recur']").get(0).nextSibling.textContent = ": ";

// show currency indicater and move next to field
if (cj(".other_amount-content > input").length) {
	cj("#currency_indicator").show();
	cj(".other_amount-content > input").parent().append(cj("#currency_indicator"));	
}

// disable the recur_selector fields if disabled
function _sdd_update_elements() {
	var is_recur = cj("#is_recur").attr('checked')=='checked';
	cj("#frequency_interval").attr('disabled', !is_recur);
	cj("#frequency_unit").attr('disabled', !is_recur);
	cj("#frequency_combined").attr('disabled', !is_recur);
	// this field is hidden by default, so people wouldn't worry about it. Feel free to show via a customisation extension
	// cj("#cycle_day").parent().parent().attr('hidden', !is_recur);
	if (is_recur) {
		cj("#start_date_display").datepicker("option", "minDate", earliest_rcur_date);
		if (currently_set_date > earliest_rcur_date) {
			cj("#start_date_display").datepicker("setDate", currently_set_date);
		} else {
			cj("#start_date_display").datepicker("setDate", earliest_rcur_date);
		}
	} else {
		cj("#start_date_display").datepicker("option", "minDate", earliest_ooff_date);
		if (currently_set_date > earliest_ooff_date) {
			cj("#start_date_display").datepicker("setDate", currently_set_date);
		} else {
			cj("#start_date_display").datepicker("setDate", earliest_ooff_date);
		}
	}
}

// function to propagate the frequency_combined button into the correct fields
function sepa_copy_combined() {
	if (!cj("#frequency_combined").length) return;

	var value = cj("#frequency_combined").attr('value');
	if (value == 12) {
		cj("#frequency_unit").attr('value', 'year');
		cj("#frequency_interval").attr('value', '1');
	} else {
		cj("#frequency_unit").attr('value', 'month');
		cj("#frequency_interval").attr('value', value);		
	}
}
sepa_copy_combined();


cj(function() {
	cj("#is_recur").change(_sdd_update_elements);
	_sdd_update_elements();
});

</script>
{/literal}