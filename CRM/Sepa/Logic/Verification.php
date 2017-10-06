<?php
/*-------------------------------------------------------+
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
+--------------------------------------------------------*/

require_once 'packages/php-iban-1.4.0/php-iban.php';


class CRM_Sepa_Logic_Verification {

  /**
   * Verifies if the given IBAN is formally correct
   *
   * @param iban  string, IBAN candidate
   *
   * @return NULL if given IBAN is valid, localized error message otherwise
   */
  static function verifyIBAN($iban) {
    // We only accept uppecase characters and numerals (machine format)
    // see https://github.com/Project60/org.project60.sepa/issues/246
    if (!preg_match("/^[A-Z0-9]+$/", $iban)) {
      return ts("IBAN is not correct", array('domain' => 'org.project60.sepa'));
    }

    if (verify_iban($iban)) {
      return NULL;
    } else {
      return ts("IBAN is not correct", array('domain' => 'org.project60.sepa'));
    }
  }

  /**
   * Form rule wrapper for ::verifyIBAN
   */
  static function rule_valid_IBAN($value) {
    if (self::verifyIBAN($value)===NULL) {
      return 1;
    } else {
      return 0;
    }
  }

  /**
   * Verifies if the given BIC is formally correct
   *
   * @param bic  string, BIC candidate
   *
   * @return NULL if given BIC is valid, localized error message otherwise
   */
  static function verifyBIC($bic) {
    if (preg_match("/^[A-Z]{6,6}[A-Z2-9][A-NP-Z0-9]([A-Z0-9]{3,3}){0,1}$/", $bic)) {
      return NULL;
    } else {
      return ts("BIC is not correct", array('domain' => 'org.project60.sepa'));
    }
  }

  /**
   * Form rule wrapper for ::verifyBIC
   */
  static function rule_valid_BIC($value) {
    if (self::verifyBIC($value)===NULL) {
      return 1;
    } else {
      return 0;
    }
  }

  /**
   * Verification method for verifying UK Bank Account & Sort Code
   */
  static function verifyAccountSortCode($account, $sortcode) {
    $result = array('is_error' => 0);

    // TEST Details
    if ($account == '12345678' && in_array($sortcode, array('000000', '000009'))) {
      $result['fields'] = array(
        'IsCorrect' => 1,
        'IBAN'      => 'GB27NWBK00009912345678',
        'Bank'      => 'TEST BANK PLC',
        'BankBIC'   => 'NWBKGB21',
      );
      CRM_Core_Error::debug_var('$result', $result);
      return $result;
    }

    $ukacscKey = CRM_Core_BAO_Setting::getItem('SEPA Direct Debit Preferences', 'ukbank_acsc_validator_key');
    if (empty($ukacscKey)) {
      CRM_Core_Error::debug_log_message(ts('SEPA UK Validator API Key not set.'));
      return $result;
    }
    $url  = "https://services.postcodeanywhere.co.uk/BankAccountValidation/Interactive/Validate/v2.00/xmla.ws?";
    $url .= "&Key=" . urlencode($ukacscKey);
    $url .= "&AccountNumber=" . urlencode($account);
    $url .= "&SortCode=" . urlencode($sortcode);

    //Make the request to Postcode Anywhere and parse the XML returned
    CRM_Core_Error::debug_var('uk account validator $url', $url);
    $file = simplexml_load_file($url);

    //Check for an error, if there is one then throw an exception
    if ($file->Columns->Column->attributes()->Name == "Error") {
      $result['is_error']  = 1; 
      $result['error']['msg'] = 
        " [DESCRIPTION] " . $file->Rows->Row->attributes()->Description . 
        " [CAUSE] " . $file->Rows->Row->attributes()->Cause . 
        " [RESOLUTION] " . $file->Rows->Row->attributes()->Resolution;
      $result['error']['description'] = (string)$file->Rows->Row->attributes()->Description;
      $result['error']['cause']       = (string)$file->Rows->Row->attributes()->Cause;
      $result['error']['resolution']  = (string)$file->Rows->Row->attributes()->Resolution;
    }

    //Copy the data
    if (!empty($file->Rows)) {
      foreach ($file->Rows->Row as $item) {
        $result['fields'] = array(
          'IsCorrect'              => filter_var($item->attributes()->IsCorrect, FILTER_VALIDATE_BOOLEAN),
          'IsDirectDebitCapable'   => filter_var($item->attributes()->IsDirectDebitCapable, FILTER_VALIDATE_BOOLEAN),
          'StatusInformation'      => (string)$item->attributes()->StatusInformation,
          'CorrectedSortCode'      => (string)$item->attributes()->CorrectedSortCode,
          'CorrectedAccountNumber' => (string)$item->attributes()->CorrectedAccountNumber,
          'IBAN'                   => (string)$item->attributes()->IBAN,
          'Bank'                   => (string)$item->attributes()->Bank,
          'BankBIC'                => (string)$item->attributes()->BankBIC,
          'Branch'                 => (string)$item->attributes()->Branch,
          'BranchBIC'              => (string)$item->attributes()->BranchBIC,
          'ContactAddressLine1'    => (string)$item->attributes()->ContactAddressLine1,
          'ContactAddressLine2'    => (string)$item->attributes()->ContactAddressLine2,
          'ContactPostTown'        => (string)$item->attributes()->ContactPostTown,
          'ContactPostcode'        => (string)$item->attributes()->ContactPostcode,
          'ContactPhone'           => (string)$item->attributes()->ContactPhone,
          'ContactFax'             => (string)$item->attributes()->ContactFax,
          'FasterPaymentsSupported'=> filter_var($item->attributes()->FasterPaymentsSupported, FILTER_VALIDATE_BOOLEAN),
          'CHAPSSupported'         => filter_var($item->attributes()->CHAPSSupported, FILTER_VALIDATE_BOOLEAN),
        );
      }
    }

    if (!$result['is_error'] && !$result['fields']['IsCorrect']) {
      $result['is_error']     = 1; 
      $result['error']['msg'] = ts("Account and Sort Code looks INVALID", array('domain' => 'org.project60.sepa'));
    }
    CRM_Core_Error::debug_var('$result', $result);
    return $result;
  }
}
