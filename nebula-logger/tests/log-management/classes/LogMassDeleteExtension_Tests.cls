//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@isTest
private class LogMassDeleteExtension_Tests {
    @TestSetup
    static void setupData() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 10; i++) {
            Log__c log = new Log__c(TransactionId__c = 'TXN-' + i);
            logs.add(log);
        }
        insert logs;
    }

    @isTest
    static void it_should_return_deletable_logs() {
        List<Log__c> logs = [SELECT Id, Name FROM Log__c];

        List<String> logIds = new List<String>();
        for (Log__c selectedLog : logs) {
            logIds.add(selectedLog.Id);
        }

        List<Log__c> expectedDeletableLogs = new List<Log__c>();
        for (UserRecordAccess recordAccess : [
            SELECT RecordId
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId() AND RecordId IN :logIds AND HasDeleteAccess = TRUE
        ]) {
            expectedDeletableLogs.add(new Log__c(Id = recordAccess.RecordId));
        }

        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(logs);
        controller.setSelected(logs);

        PageReference pageReference = Page.LogMassDelete;
        Test.setCurrentPage(pageReference);

        Test.startTest();

        LogMassDeleteExtension extension = new LogMassDeleteExtension(controller);
        List<Log__c> returnedDeletableLogs = extension.getDeletableLogs();

        Test.stopTest();

        System.assertEquals(expectedDeletableLogs.size(), returnedDeletableLogs.size());
    }

    @isTest
    static void it_should_delete_selected_log_records() {
        List<Log__c> logs = [SELECT Id, Name FROM Log__c];
        List<Log__c> logsToDelete = new List<Log__c>();
        List<Log__c> logsToKeep = new List<Log__c>();
        Integer numberToKeep = 3;
        for (Integer i = 0; i < logs.size(); i++) {
            if (i < numberToKeep) {
                logsToDelete.add(logs.get(i));
            } else {
                logsToKeep.add(logs.get(i));
            }
        }

        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(logs);
        controller.setSelected(logsToDelete);

        PageReference pageReference = Page.LogMassDelete;
        Test.setCurrentPage(pageReference);

        Test.startTest();

        LogMassDeleteExtension extension = new LogMassDeleteExtension(controller);
        extension.deleteSelectedLogs();

        Test.stopTest();

        // Verify that only the selected logs were deleted
        logsToDelete = [SELECT Id, IsDeleted FROM Log__c WHERE Id IN :logsToDelete ALL ROWS];
        for (Log__c log : logsToDelete) {
            System.assertEquals(true, log.IsDeleted, log);
        }
        logsToKeep = [SELECT Id, IsDeleted FROM Log__c WHERE Id IN :logsToKeep ALL ROWS];
        for (Log__c log : logsToKeep) {
            System.assertEquals(false, log.IsDeleted, log);
        }
    }
}
