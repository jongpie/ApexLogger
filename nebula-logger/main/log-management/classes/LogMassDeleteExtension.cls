//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Manages mass deleting `Log__c` records that have been selected by a user on a `Log__c` list view
 */
public with sharing class LogMassDeleteExtension {
    private ApexPages.StandardSetController controller;

    /**
     * @description LogMassDeleteExtension description
     * @param  controller controller description
     * @return            return description
     */
    public LogMassDeleteExtension(ApexPages.StandardSetController controller) {
        if (Schema.Log__c.SObjectType.getDescribe().isDeletable() == false) {
            String deleteAccessError = 'You do not have access to delete logs records';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, deleteAccessError));
        }

        this.controller = controller;
    }

    /**
     * @description Filters the list of selected `Log__c` records to only include records that the current user can delete (based on object-level access)
     * @return      The matching `Log__c` records that the current user has access to delete
     */
    public List<Log__c> getDeletableLogs() {
        // The UserRecordAccess object is weird - RecordId is not an actual ID field, so you can't filter using `List<SObject>` or `List<Id>`, you have to use strings
        // So, here's some code that would be unnecessary if RecordId were a polymorphic ID field instead
        List<String> logIds = new List<String>();
        for (Log__c selectedLog : (List<Log__c>) this.controller.getSelected()) {
            logIds.add(selectedLog.Id);
        }

        // Get the list of record IDs that the current user can delete
        List<Id> deletableLogIds = new List<Id>();
        for (UserRecordAccess recordAccess : [
            SELECT RecordId
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId() AND RecordId IN :logIds AND HasDeleteAccess = TRUE
        ]) {
            deletableLogIds.add(recordAccess.RecordId);
        }

        // Get the logs + any fields shown in the VF page
        return [SELECT Id, Name, LoggedBy__c, LoggedBy__r.Name, StartTime__c, TotalLogEntries__c FROM Log__c WHERE Id IN :deletableLogIds];
    }

    /**
     * @description Deletes the list of selected `Log__c` records (if the current user has delete access for the `Log__c` object)
     * @return      The PageReference of the previous page (based on `controller.cancel()`)
     */
    public PageReference deleteSelectedLogs() {
        try {
            delete getDeletableLogs();
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }

        // The controller's method cancel() just returns the user to the previous page - it doesn't rollback any DML statements (like the delete above)
        return this.controller.cancel();
    }
}
