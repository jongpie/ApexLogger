//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class LogEntryEventBuilder_Tests {
    private static Organization getOrganization() {
        return [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
    }

    private static String getOrganizationEnvironmentType(Organization organization) {
        String orgEnvironmentType;
        if (organization.IsSandbox == true && organization.TrialExpirationDate != null) {
            orgEnvironmentType = 'Scratch Org';
        } else if (organization.IsSandbox == true) {
            orgEnvironmentType = 'Sandbox';
        } else {
            orgEnvironmentType = 'Production';
        }
        return orgEnvironmentType;
    }

    private static SObject getNetwork() {
        if (Network.getNetworkId() == null) {
            return null;
        }

        String networkApiName = 'Network';
        // Networks (communities) may not be enabled in the org (no Network object), so run everything dynamically
        Boolean networksEnabled = Schema.getGlobalDescribe().containsKey(networkApiName);

        if (!networksEnabled) {
            return null;
        }

        String queryString = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id = :Network.getNetworkId()';

        return Database.query(queryString);
    }

    private static User getUser() {
        return [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
    }

    @isTest
    static void it_should_short_circuit_when_not_enabled() {
        Boolean shouldSave = false;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.DEBUG, shouldSave);

        System.assertEquals(null, builder.getLogEntryEvent());
        System.assertEquals(null, builder.setMessage('test').getLogEntryEvent());
        System.assertEquals(null, builder.setExceptionDetails(new IllegalArgumentException('test')).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId(new Account()).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId('005000000000001').getLogEntryEvent());
        System.assertEquals(null, builder.setTopics(new List<String>{ '', ' ' }).getLogEntryEvent());
    }

    @isTest
    static void it_should_short_circuit_when_enabled_logging_level_above_called_level() {
        Boolean shouldSave = false;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, shouldSave);

        System.assertEquals(null, builder.getLogEntryEvent());
    }

    @isTest
    static void it_should_not_short_circuit_when_enabledl() {
        Boolean shouldSave = true;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, shouldSave);

        System.assertNotEquals(null, builder.getLogEntryEvent());
    }

    @isTest
    static void it_should_set_message_fields_for_logMessage() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);

        Test.startTest();

        LogMessage logMessage = new LogMessage('The time is {0}', System.now());
        builder.setMessage(logMessage);

        Test.stopTest();

        System.assertEquals(logMessage.getMessage(), builder.getLogEntryEvent().Message__c);
    }

    @isTest
    static void it_should_set_message_fields_for_string() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);

        Test.startTest();

        String message = 'The time is ' + String.valueOf(System.now());
        builder.setMessage(message);

        Test.stopTest();

        System.assertEquals(message, builder.getLogEntryEvent().Message__c);
    }

    @isTest
    static void it_should_set_exception_fields_for_dmlException() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, builder.getLogEntryEvent().ExceptionType__c);

        Test.startTest();

        DmlException dmlException = new DmlException('Test DML exception');
        builder.setExceptionDetails(dmlException);

        Test.stopTest();

        System.assertEquals(dmlException.getMessage(), builder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(dmlException.getTypeName(), builder.getLogEntryEvent().ExceptionType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_successful_deleteResult() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Database.DeleteResult deleteResult = Database.delete(log, false);
        System.assertEquals(true, deleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(deleteResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('Single', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(deleteResult), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_failed_deleteResult() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        // Delete the log twice to trigger a DeleteResult error
        delete log;

        Database.DeleteResult deleteResult = Database.delete(log, false);
        System.assertEquals(false, deleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(deleteResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('Single', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(deleteResult), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    // TODO only some standard objects can be merged - need to find a way to either mock or trigger a merge result that works in all orgs
    // @isTest
    // static void it_should_set_database_result_fields_for_failed_mergeResult() {
    //     Database.MergeResult mergeResult = Database.merge(new Account(Name='Expcted'), new Account(Name='Failure'), false);
    //     System.assertEquals(false, mergeResult.isSuccess());

    //     LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

    //     Test.startTest();
    //     builder.setDatabaseResult(mergeResult);
    //     Test.stopTest();

    //     LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

    //     System.assertEquals(JSON.serializePretty(mergeResult), logEntryEvent.DatabaseResultJson__c);
    //     System.assertEquals(Database.MergeResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    // }

    @isTest
    static void it_should_set_database_result_fields_for_successful_saveResult() {
        Database.SaveResult saveResult = Database.insert(new Log__c(TransactionId__c = '1234'), false);
        System.assertEquals(true, saveResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(saveResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('Single', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(saveResult), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_failed_saveResult() {
        Database.SaveResult saveResult = Database.insert(new Account(), false);
        System.assertEquals(false, saveResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(saveResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('Single', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(saveResult), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_successful_undeleteResult() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        delete log;

        Database.UndeleteResult undeleteResult = Database.undelete(log.Id, false);
        System.assertEquals(true, undeleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(undeleteResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('Single', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_failed_undeleteResult() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        delete log;
        // Hard delete to (later) cause an undelete error
        Database.emptyRecycleBin(log);

        Database.UndeleteResult undeleteResult = Database.undelete(log.Id, false);
        System.assertEquals(false, undeleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(undeleteResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('Single', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_successful_upsertResult_when_insert() {
        // UpsertResult for a new record insert
        Database.UpsertResult upsertResult = Database.upsert(new Log__c(TransactionId__c = '1234'), false);
        System.assertEquals(true, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(upsertResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('Single', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResult), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_failed_upsertResult_when_insert() {
        // UpsertResult for a new record insert
        Database.UpsertResult upsertResult = Database.upsert(new Account(), false);
        System.assertEquals(false, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(upsertResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('Single', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResult), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_successful_upsertResult_when_update() {
        // UpsertResult for an existing record update
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        log.TransactionId__c = '9876';

        Database.UpsertResult upsertResult = Database.upsert(log, false);
        System.assertEquals(true, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(upsertResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('Single', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResult), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_failed_upsertResult_when_update() {
        // UpsertResult for an existing record update
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        // Use a log entry this time to handle the upsert scenario
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, Name = 'Test Log Entry');
        insert logEntry;

        // Set name field to a value too long for the field
        Integer maxFieldLength = Schema.LogEntry__c.Name.getDescribe().getLength();
        logEntry.Name = '0'.repeat(maxFieldLength + 10);

        Database.UpsertResult upsertResult = Database.upsert(logEntry, false);
        System.assertEquals(false, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(upsertResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('Single', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResult), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_list_of_successful_deleteResult() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        insert logs;

        List<Database.DeleteResult> deleteResults = Database.delete(logs, false);
        for (Database.DeleteResult deleteResult : deleteResults) {
            System.assertEquals(true, deleteResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(deleteResults);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('List', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(deleteResults), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_list_of_failed_deleteResult() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        insert logs;

        // Delete the logs twice to trigger DeleteResult errors
        delete logs;

        List<Database.DeleteResult> deleteResults = Database.delete(logs, false);
        for (Database.DeleteResult deleteResult : deleteResults) {
            System.assertEquals(false, deleteResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(deleteResults);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('List', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(deleteResults), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    // TODO only some standard objects can be merged - need to find a way to either mock or trigger a merge result that works in all orgs
    // @isTest
    // static void it_should_set_database_result_fields_for_list_of_failed_mergeResult() {
    //     Database.MergeResult mergeResult = Database.merge(new Account(Name='Expcted'), new Account(Name='Failure'), false);
    //     System.assertEquals(false, mergeResult.isSuccess());

    //     LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

    //     Test.startTest();
    //     builder.setDatabaseResult(mergeResult);
    //     Test.stopTest();

    //     LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

    //     System.assertEquals(JSON.serializePretty(mergeResult), logEntryEvent.DatabaseResultJson__c);
    //     System.assertEquals(Database.MergeResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    // }

    @isTest
    static void it_should_set_database_result_fields_for_list_of_successful_saveResult() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        List<Database.SaveResult> saveResults = Database.insert(logs, false);
        for (Database.SaveResult saveResult : saveResults) {
            System.assertEquals(true, saveResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(saveResults);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('List', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(saveResults), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_list_of_failed_saveResult() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account account = new Account();
            accounts.add(account);
        }
        List<Database.SaveResult> saveResults = Database.insert(accounts, false);
        for (Database.SaveResult saveResult : saveResults) {
            System.assertEquals(false, saveResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(saveResults);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('List', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(saveResults), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_list_of_successful_undeleteResult() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        insert logs;
        delete logs;

        List<Database.UndeleteResult> undeleteResults = Database.undelete(logs, false);
        for (Database.UndeleteResult undeleteResult : undeleteResults) {
            System.assertEquals(true, undeleteResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(undeleteResults);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('List', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_list_of_failed_undeleteResult() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        insert logs;
        delete logs;
        // Hard delete to (later) cause an undelete error
        Database.emptyRecycleBin(logs);

        List<Database.UndeleteResult> undeleteResults = Database.undelete(logs, false);
        for (Database.UndeleteResult undeleteResult : undeleteResults) {
            System.assertEquals(false, undeleteResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(undeleteResults);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('List', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_list_of_successful_upsertResult_when_insert() {
        // UpsertResult for a new record insert
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        List<Database.UpsertResult> upsertResults = Database.upsert(logs, false);
        for (Database.UpsertResult upsertResult : upsertResults) {
            System.assertEquals(true, upsertResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(upsertResults);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('List', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResults), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_database_result_fields_for_list_of_failed_upsertResult_when_insert() {
        // UpsertResult for a new record insert
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account account = new Account();
            accounts.add(account);
        }
        List<Database.UpsertResult> upsertResults = Database.upsert(accounts, false);
        for (Database.UpsertResult upsertResult : upsertResults) {
            System.assertEquals(false, upsertResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDatabaseResult(upsertResults);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals('List', logEntryEvent.DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResults), logEntryEvent.DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    }

    @isTest
    static void it_should_set_record_fields_for_recordId_when_standard_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        Id currentUserId = UserInfo.getUserId();
        builder.setRecordId(currentUserId);

        Test.stopTest();

        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(currentUserId, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals('User', builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @isTest
    static void it_should_set_record_fields_for_recordId_when_custom_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        builder.setRecordId(log.Id);

        Test.stopTest();

        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(log.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(Log__c.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @isTest
    static void it_should_set_record_fields_for_recordId_when_custom_metadata_type() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        LogStatus__mdt status = [SELECT Id, MasterLabel, DeveloperName FROM LogStatus__mdt LIMIT 1];
        builder.setRecordId(status.Id);

        Test.stopTest();

        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(status.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(LogStatus__mdt.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @isTest
    static void it_should_set_record_fields_for_record_when_standard_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        User currentUser = [SELECT Id, Name, ProfileId, Profile.Name, IsActive FROM User WHERE Id = :UserInfo.getUserId()];
        builder.setRecordId(currentUser);

        Test.stopTest();

        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(currentUser.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(currentUser), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals('User', builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @isTest
    static void it_should_set_record_fields_for_record_when_custom_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        builder.setRecordId(log);

        Test.stopTest();

        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(log.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(log), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(Log__c.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @isTest
    static void it_should_set_record_fields_for_record_when_custom_metadata_type() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        LogStatus__mdt status = [SELECT Id, MasterLabel, DeveloperName FROM LogStatus__mdt LIMIT 1];
        builder.setRecordId(status);

        Test.stopTest();

        System.assertEquals(status.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(status), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(LogStatus__mdt.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @isTest
    static void it_should_set_record_fields_for_list_of_records() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        builder.setRecord(users);

        Test.stopTest();

        System.assertEquals('List', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(User.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @isTest
    static void it_should_add_topic_string() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Topics__c);

        String topic = 'something';

        Test.startTest();
        builder.addTopic(topic);
        Test.stopTest();

        System.assertEquals(topic, builder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_topic_string_to_existing_list_of_topics() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Topics__c);

        List<String> originalTopics = new List<String>{ 'some-topic', 'another One', 'here\'s one more!' };
        builder.setTopics(originalTopics);
        System.assertEquals(String.join(originalTopics, '\n'), builder.getLogEntryEvent().Topics__c);

        String topic = 'something';

        Test.startTest();
        builder.addTopic(topic);
        Test.stopTest();

        List<String> expectedTopics = new List<String>(originalTopics);
        expectedTopics.add(topic);
        String expectedTopicsString = String.join(expectedTopics, '\n');
        System.assertEquals(expectedTopicsString, builder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_set_topics_string_for_list_of_topics() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Topics__c);

        Test.startTest();

        List<String> topics = new List<String>{ 'some-topic', 'another One', 'here\'s one more!' };
        builder.setTopics(topics);

        Test.stopTest();

        String expectedTopicsString = String.join(topics, '\n');
        System.assertEquals(expectedTopicsString, builder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_set_stack_trace_and_origin_location_for_stack_trace_string() {
        DmlException stackTraceHandler = new DmlException();

        Boolean shouldSave = true;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, shouldSave);
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;

        Test.startTest();
        builder.parseStackTrace(stackTraceHandler.getStackTraceString());
        Test.stopTest();

        String expectedOriginLocation = stackTraceHandler.getStackTraceString().split('\n').get(0).substringBefore(':').substringAfter('Class.');
        String expectedStackTrace = stackTraceHandler.getStackTraceString();

        System.assertNotEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(expectedOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.assertNotEquals(null, builder.getLogEntryEvent().StackTrace__c);
        System.assertEquals(expectedStackTrace, builder.getLogEntryEvent().StackTrace__c);
    }

    @isTest
    static void it_should_not_set_stack_trace_and_origin_location_for_invalid_stack_trace_string() {
        final String invalidStackTrace = '()';

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        // Clear out any auto-set values
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;

        Test.startTest();
        builder.parseStackTrace(invalidStackTrace);
        Test.stopTest();

        System.assertEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(null, builder.getLogEntryEvent().StackTrace__c);
    }

    @isTest
    static void it_should_return_value_of_shouldSave_when_true() {
        Test.startTest();
        Boolean shouldSave = true;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, shouldSave);
        Test.stopTest();

        System.assertEquals(shouldSave, builder.shouldSave());
    }

    @isTest
    static void it_should_return_value_of_shouldSave_when_false() {
        Test.startTest();
        Boolean shouldSave = false;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, shouldSave);
        Test.stopTest();

        System.assertEquals(shouldSave, builder.shouldSave());
    }

    @isTest
    static void it_should_set_detailed_fields() {
        Test.startTest();
        Boolean shouldSave = true;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, shouldSave);
        Test.stopTest();

        // Get expected data
        Organization organization = getOrganization();
        String organizationEnvironmentType = getOrganizationEnvironmentType(organization);
        SObject networkSite = getNetwork();
        User user = getUser();

        // Verify organization fields
        System.assertEquals(Url.getOrgDomainUrl().toExternalForm(), builder.getLogEntryEvent().OrganizationDomainUrl__c);
        System.assertEquals(organizationEnvironmentType, builder.getLogEntryEvent().OrganizationEnvironmentType__c);
        System.assertEquals(organization.Id, builder.getLogEntryEvent().OrganizationId__c);
        System.assertEquals(organization.InstanceName, builder.getLogEntryEvent().OrganizationInstanceName__c);
        System.assertEquals(organization.Name, builder.getLogEntryEvent().OrganizationName__c);
        System.assertEquals(organization.NamespacePrefix, builder.getLogEntryEvent().OrganizationNamespacePrefix__c);
        System.assertEquals(organization.OrganizationType, builder.getLogEntryEvent().OrganizationType__c);

        // Verify user fields
        System.assertEquals(USER.Username, builder.getLogEntryEvent().LoggedByUsername__c);
        System.assertEquals(USER.Profile.Name, builder.getLogEntryEvent().ProfileName__c);
        System.assertEquals(USER.Profile.UserLicense.LicenseDefinitionKey, builder.getLogEntryEvent().UserLicenseDefinitionKey__c);
        System.assertEquals(USER.Profile.UserLicenseId, builder.getLogEntryEvent().UserLicenseId__c);
        System.assertEquals(USER.Profile.UserLicense.Name, builder.getLogEntryEvent().UserLicenseName__c);
        System.assertEquals(USER.UserRole?.Name, builder.getLogEntryEvent().UserRoleName__c);
    }
}
