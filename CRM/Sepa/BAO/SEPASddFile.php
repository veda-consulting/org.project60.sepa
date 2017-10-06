<?php
/*-------------------------------------------------------+
| Project 60 - SEPA direct debit                         |
| Copyright (C) 2013-2014 TTTP                           |
| Author: X+                                             |
+--------------------------------------------------------+
| This program is released as free software under the    |
| Affero GPL license. You can redistribute it and/or     |
| modify it under the terms of this license which you    |
| can read by viewing the included agpl.txt or online    |
| at www.gnu.org/licenses/agpl.html. Removal of this     |
| copyright header is strictly prohibited without        |
| written permission from the original author(s).        |
+--------------------------------------------------------*/


/**
 * File for the CiviCRM sepa_sdd_file business logic
 *
 * @package CiviCRM_SEPA
 *
 */


/**
 * Class contains functions for Sepa mandates
 */
class CRM_Sepa_BAO_SEPASddFile extends CRM_Sepa_DAO_SEPASddFile {


  /**
   * @param array  $params         (reference ) an assoc array of name/value pairs
   *
   * @return object       CRM_Core_BAO_SEPASddFile object on success, null otherwise
   * @access public
   * @static
   */
  static function add(&$params) {
    $hook = empty($params['id']) ? 'create' : 'edit';
    CRM_Utils_Hook::pre($hook, 'SepaSddFile', CRM_Utils_Array::value('id', $params), $params);

    $dao = new CRM_Sepa_DAO_SEPASddFile();
    $dao->copyValues($params);
    $dao->save();

    CRM_Utils_Hook::post($hook, 'SepaSddFile', $dao->id, $dao);
    return $dao;
  }

  function generatexml($id) {
    $xml = "";
    $template = CRM_Core_Smarty::singleton();
    $this->get((int)$id);
    $template->assign("file", $this->toArray());
    $txgroup = new CRM_Sepa_BAO_SEPATransactionGroup();
    $txgroup->sdd_file_id=$this->id;
    $txgroup->find();
    $total =0; 
    $nbtransactions =0; 
    $fileFormats = array();
    while ($txgroup->fetch()) {
      $xml .= $txgroup->generateXML();
      $total += $txgroup->total;
      $nbtransactions += $txgroup->nbtransactions;
      $fileFormats[] = $txgroup->fileFormat;
    }
    if (count(array_unique($fileFormats)) > 1) {
      throw new Exception('Creditors with mismatching File Formats cannot be mixed in same File');
    }
    $template->assign("file",$this->toArray());
    $template->assign("total",$total );
    $template->assign("nbtransactions",$nbtransactions);
    $head = $template->fetch('CRM/Sepa/xml/file_header.tpl');
    $footer = $template->fetch('CRM/Sepa/xml/file_footer.tpl');
    return $head.$xml.$footer;
  }

  function generateTXT($id, $fileName) {
    $txt = "";
    $txgroup = new CRM_Sepa_BAO_SEPATransactionGroup();
    $txgroup->sdd_file_id = $id;
    $txgroup->find();
    
    while ($txgroup->fetch()) {
      $mandateDetails = self::getMandateDetailsByTxGroupId($txgroup->id);
      $txt .= $mandateDetails."\n";
    }
    $config = CRM_Core_Config::singleton();
    $filepath = $config->customFileUploadDir;
    $filePathName   = "{$filepath}/{$fileName}";
    $handle = fopen($filePathName, 'w');
    file_put_contents($filePathName, $txt);
    fclose($handle);
    return $txt;
  }

  //This SQL is copy of SepaTransactionGroup::generateXML function, this need to be move in Utils function so we reuse in both place
  static function getMandateDetailsByTxGroupId($txGroupId) {
    if (empty($txGroupId)) {
      return array();
    }
    
    $r = NULL;
    $queryParams= array (1=>array($txGroupId, 'Positive'));
    $query="
      SELECT
        c.id AS cid,
        civicrm_contact.display_name,
        invoice_id,
        currency,
        total_amount,
        receive_date,
        contribution_recur_id,
        contribution_status_id,
        mandate.*
      FROM civicrm_contribution AS c
      JOIN civicrm_sdd_contribution_txgroup AS g ON g.contribution_id=c.id
      JOIN civicrm_sdd_mandate AS mandate ON mandate.id = IF(c.contribution_recur_id IS NOT NULL,
        (SELECT id FROM civicrm_sdd_mandate WHERE entity_table = 'civicrm_contribution_recur' AND entity_id = c.contribution_recur_id),
        (SELECT id FROM civicrm_sdd_mandate WHERE entity_table = 'civicrm_contribution' AND entity_id = c.id)
      )
      JOIN civicrm_contact ON c.contact_id = civicrm_contact.id
      WHERE g.txgroup_id = %1
        AND contribution_status_id != 3
        AND mandate.is_enabled = true
    "; //and not cancelled
    $contrib = CRM_Core_DAO::executeQuery($query, $queryParams);
    while ($contrib->fetch()) {
      $t = $contrib->toArray();
      //Build Bacs String in format
      $str = self::lodgementFileformat($t);
      $r .= $str."\n";
    }
    return $r;    
  }

  public static function lodgementFileformat($mandateDetails, $defaultCode = NULL) {
    if (empty($mandateDetails)) {
      return array();
      //"BSORTCDE","BANKACNO","ACNAME","AMOUNT","BANKREF","0N"
    }

    // Check if we have default code
    if (!empty($defaultCode)) {
      $transcation_code = $defaultCode;
    } else {
      $transcation_code = CRM_Sepa_Logic_Status::translateMandateStatusToBacsReference($mandateDetails['status']);
    }
    //Build Bacs String in format
    //"BSORTCDE","BANKACNO","ACNAME","AMOUNT","BANKREF","0N"
    $str = "";
    $str .= '"'.$mandateDetails['sort_code'].'"';
    $str .= ',';
    $str .= '"'.$mandateDetails['account_num'].'"';
    $str .= ',';
    $str .= '"'.$mandateDetails['display_name'].'"';
    $str .= ',';
    $str .= '"'.$mandateDetails['total_amount'].'"';
    $str .= ',';
    $str .= '"'.$mandateDetails['reference'].'"';
    $str .= ',';
    $str .= '"'.(string)$transcation_code.'"';

    return $str;
  }
}

