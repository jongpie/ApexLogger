//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class Logger_Tests {
    // Helper classes
    private class Logger_TestsException extends Exception {
    }

    private class SuccessCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(request.getBody());
            response.setStatusCode(200);
            return response;
        }
    }

    private class FailureCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(request.getBody());
            response.setStatusCode(400);
            return response;
        }
    }

    // Helper methods
    static User getCurrentUser() {
        return new User(Id = UserInfo.getUserId());
    }

    static void setUserLoggingLevel(LoggingLevel loggingLevel) {
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
    }

    static String getMessage() {
        return 'Hello, world';
    }

    static LogMessage getLogMessage() {
        return new LogMessage('The current user is {0}', getRecord());
    }

    static SObject getRecord() {
        return new User(
            Id = UserInfo.getUserId(),
            ProfileId = UserInfo.getProfileId(),
            Username = UserInfo.getUserName(),
            UserRoleId = UserInfo.getUserRoleId()
        );
    }

    static Exception getException() {
        return new DmlException('Example DML Exception');
    }

    static Database.DeleteResult getDeleteResult(Boolean isSuccess) {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        if (isSuccess == false) {
            // Delete the log twice to trigger a DeleteResult error
            delete log;
        }

        Database.DeleteResult deleteResult = Database.delete(log, false);
        System.assertEquals(isSuccess, deleteResult.isSuccess());

        return deleteResult;
    }

    static List<Database.DeleteResult> getDeleteResultList() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 3; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
        }
        insert logs;

        return Database.delete(logs, false);
    }

    // TODO only some standard objects can be merged - need to find a way to either mock or trigger a merge result that works in all orgs
    // static Database.MergeResult getMergeResult(Boolean isSuccess) { }

    static Database.SaveResult getSaveResult(Boolean isSuccess) {
        Database.SaveResult saveResult;

        if (isSuccess == false) {
            saveResult = Database.insert(new Account(), false);
        } else {
            saveResult = Database.insert(new Log__c(TransactionId__c = '1234'), false);
        }
        System.assertEquals(isSuccess, saveResult.isSuccess());
        return saveResult;
    }

    static List<Database.SaveResult> getSaveResultList() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 3; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
        }

        return Database.insert(logs, false);
    }

    static Database.UpsertResult getUpsertResult(Boolean isSuccess, Boolean isInsert) {
        Database.UpsertResult upsertResult;

        if (isSuccess == false && isInsert == true) {
            upsertResult = Database.upsert(new Account(), false);
        } else if (isSuccess == true && isInsert == true) {
            upsertResult = Database.upsert(new Log__c(TransactionId__c = '1234'), false);
        } else if (isSuccess == true && isInsert == false) {
            Log__c log = new Log__c(TransactionId__c = '1234');
            insert log;
            log.TransactionId__c = '9876';

            upsertResult = Database.upsert(log, false);
        } else if (isSuccess == false && isInsert == false) {
            Log__c log = new Log__c(TransactionId__c = '1234');
            insert log;

            // Use a log entry this time to handle the upsert scenario
            LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, Name = 'Test Log Entry');
            insert logEntry;

            // Set name field to a value too long for the field
            Integer maxFieldLength = Schema.LogEntry__c.Name.getDescribe().getLength();
            logEntry.Name = '0'.repeat(maxFieldLength + 10);

            upsertResult = Database.upsert(logEntry, false);
        }
        System.assertEquals(isSuccess, upsertResult.isSuccess());
        System.assertEquals(isInsert, upsertResult.isCreated());
        return upsertResult;
    }

    static List<Database.UpsertResult> getUpsertResultList() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 3; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
        }

        return Database.upsert(logs, false);
    }

    static Database.UndeleteResult getUndeleteResult(Boolean isSuccess) {
        Database.UndeleteResult undeleteResult;

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        delete log;

        if (isSuccess == false) {
            // Hard delete to cause an undelete error
            Database.emptyRecycleBin(log);

            undeleteResult = Database.undelete(log.Id, false);
        } else {
            undeleteResult = Database.undelete(log.Id, false);
        }
        System.assertEquals(isSuccess, undeleteResult.isSuccess());
        return undeleteResult;
    }

    static List<Database.UndeleteResult> getUndeleteResultList() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 3; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
        }
        insert logs;
        delete logs;

        return Database.undelete(logs, false);
    }

    static String getOriginLocation() {
        String originLocation;
        for (String currentStackTraceLine : new DmlException().getStackTraceString().split('\n')) {
            if (currentStackTraceLine.contains('Logger_Tests.getOriginLocation'))
                continue;
            if (currentStackTraceLine.contains('.LogEntryEventBuilder.'))
                continue;
            if (currentStackTraceLine.contains('.Logger.'))
                continue;

            originLocation = currentStackTraceLine.substringBefore(':');
            if (originLocation.startsWith('Class.')) {
                originLocation = originLocation.substringAfter('Class.');
            }
            break;
        }

        return originLocation;
    }

    @testSetup
    static void setup() {
        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = true;
        settings.EnableSystemMessages__c = false;
        settings.LoggingLevel__c = LoggingLevel.DEBUG.name();
        upsert settings;
    }

    @isTest
    static void it_should_auto_create_org_default_settings_when_not_configured() {
        delete [SELECT Id FROM LoggerSettings__c];
        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(0, existingSettings.size());

        Test.startTest();
        Logger.isEnabled();
        Test.stopTest();

        existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(1, existingSettings.size());

        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        System.assertEquals(orgDefaults.Id, existingSettings.get(0).Id);
    }

    @isTest
    static void it_should_return_transaction_id() {
        String transactionId = Logger.getTransactionId();
        System.assert(String.isNotBlank(transactionId));
        System.assertEquals(System.Request.getCurrent().getRequestId(), transactionId);
    }

    @isTest
    static void it_should_set_transaction_entry_number() {
        for (Integer i = 0; i < 10; i++) {
            LogEntryEventBuilder builder = Logger.info('my log entry');

            System.assertEquals(i + 1, builder.getLogEntryEvent().TransactionEntryNumber__c);
        }
    }

    @isTest
    static void it_should_return_set_parent_transaction_id() {
        String expectedParentTransactionId = 'imagineThisWereAGuid';
        Logger.setParentLogTransactionId(expectedParentTransactionId);
        System.assertEquals(expectedParentTransactionId, Logger.getParentLogTransactionId());
    }

    @isTest
    static void it_should_return_quiddity_level() {
        List<Quiddity> acceptableDefaultQuidditiesForTests = new List<Quiddity>{ Quiddity.RUNTEST_ASYNC, Quiddity.RUNTEST_DEPLOY, Quiddity.RUNTEST_SYNC };
        System.assertEquals(true, acceptableDefaultQuidditiesForTests.contains(Logger.getCurrentQuiddity()));

        System.assertEquals(System.Request.getCurrent().getQuiddity(), Logger.getCurrentQuiddity());
    }

    @isTest
    static void it_should_return_user_logging_level() {
        LoggingLevel expectedValue = LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = expectedValue.name();

        Test.startTest();
        LoggingLevel returnedValue = Logger.getUserLoggingLevel();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_enabled() {
        Boolean expectedValue = true;

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = expectedValue;

        Boolean returnedValue = Logger.isEnabled();

        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_provided_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Boolean expectedValue = true;

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();

        Boolean returnedValue = Logger.isEnabled(loggingLevel);

        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_error_logging_level_is_enabled() {
        Boolean expectedValue = true;

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();

        Boolean returnedValue = Logger.isErrorEnabled();

        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_warn_logging_level_is_enabled() {
        Boolean expectedValue = true;

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.WARN.name();

        Boolean returnedValue = Logger.isWarnEnabled();

        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_info_logging_level_is_enabled() {
        Boolean expectedValue = true;

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.INFO.name();

        Boolean returnedValue = Logger.isInfoEnabled();

        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_debug_logging_level_is_enabled() {
        Boolean expectedValue = true;

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.DEBUG.name();

        Boolean returnedValue = Logger.isDebugEnabled();

        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_fine_logging_level_is_enabled() {
        Boolean expectedValue = true;

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINE.name();

        Boolean returnedValue = Logger.isFineEnabled();

        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_finer_logging_level_is_enabled() {
        Boolean expectedValue = true;

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINER.name();

        Boolean returnedValue = Logger.isFinerEnabled();

        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_finest_logging_level_is_enabled() {
        Boolean expectedValue = true;

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();

        Boolean returnedValue = Logger.isFinestEnabled();

        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_saving_is_suspended() {
        System.assertEquals(false, Logger.isSavingSuspended());

        Test.startTest();
        Logger.suspendSaving();
        Test.stopTest();

        System.assertEquals(true, Logger.isSavingSuspended());
    }

    @isTest
    static void it_should_suspend_saving() {
        Integer countOfExistingLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfExistingLogEntries);

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = true;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.DEBUG.name();

        Logger.suspendSaving();

        Logger.debug('test log entry');
        Logger.saveLog();

        Test.stopTest();

        countOfExistingLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfExistingLogEntries);
    }

    @isTest
    static void it_should_resume_saving() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = true;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();

        Integer logEntriesToCreate = 4;

        Logger.suspendSaving();
        System.assertEquals(true, Logger.isSavingSuspended());

        for (Integer i = 0; i < logEntriesToCreate; i++) {
            Logger.info('test log entry #' + i);
        }
        System.assertEquals(logEntriesToCreate, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(logEntriesToCreate, Logger.getBufferSize());
        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        Logger.resumeSaving();
        System.assertEquals(false, Logger.isSavingSuspended());

        Logger.saveLog();

        Test.getEventBus().deliver();

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(logEntriesToCreate, countOfLogEntries);
        System.assertEquals(1, Limits.getDmlStatements());
    }

    @isTest
    static void it_should_save_accurate_timestamp_when_logging_user_has_different_time_zone() {
        User automatedProcessUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Name = 'Automated Process' AND Profile.Name = null];
        User currentUser = new User(Id = UserInfo.getUserId(), TimeZoneSidKey = UserInfo.getTimeZone().getId());

        // Make sure that the current user has a different time zone from the automated process user
        if (automatedProcessUser.TimeZoneSidKey == currentUser.TimeZoneSidKey) {
            switch on automatedProcessUser.TimeZoneSidKey {
                when 'America/Los_Angeles' {
                    currentUser.TimeZoneSidKey = 'America/New_York';
                }
                when else {
                    currentUser.TimeZoneSidKey = 'America/Los_Angeles';
                }
            }
            System.assertNotEquals(automatedProcessUser.TimeZoneSidKey, currentUser.TimeZoneSidKey);
            update currentUser;
        }

        Datetime originalTimestamp;
        System.runAs(currentUser) {
            Logger.getUserSettings().IsEnabled__c = true;
            Logger.getUserSettings().LoggingLevel__c = LoggingLevel.INFO.name();

            LogEntryEventBuilder builder = Logger.info('test log entry');
            originalTimestamp = builder.getLogEntryEvent().TimeStamp__c;
            System.assertNotEquals(null, originalTimestamp);

            System.assertEquals(1, Logger.getBufferSize());
            Logger.saveLog();

            Test.getEventBus().deliver();
        }

        LogEntry__c logEntry = [SELECT Id, Timestamp__c FROM LogEntry__c];
        System.assertEquals(originalTimestamp, logEntry.Timestamp__c);
    }

    @isTest
    static void it_should_return_the_buffer_size() {
        System.assertEquals(0, Logger.getBufferSize());

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Test.startTest();

        Logger.debug('test log entry');
        Logger.warn('another test log entry');

        Test.stopTest();

        System.assertEquals(2, Logger.getBufferSize());
    }

    @isTest
    static void it_should_save_via_event_bus_when_defaulted() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.getUserSettings().DefaultSaveMethod__c = 'EVENT_BUS';

        System.assertEquals(Logger.SaveMethod.EVENT_BUS, Logger.transactionSaveMethod);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getPublishImmediateDml());

        Test.startTest();

        Logger.saveLog();
        System.assertEquals(1, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @isTest
    static void it_should_save_via_event_bus_when_specified() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getPublishImmediateDml());

        Test.startTest();

        Logger.saveLog(Logger.SaveMethod.EVENT_BUS);
        System.assertEquals(1, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @isTest
    static void it_should_save_via_queueable_when_defaulted() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.DEBUG.name();
        Logger.getUserSettings().DefaultSaveMethod__c = 'QUEUEABLE';

        System.assertEquals(Logger.SaveMethod.QUEUEABLE, Logger.transactionSaveMethod);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(2, Logger.getBufferSize());
        System.assertEquals(0, Limits.getQueueableJobs());

        Logger.saveLog();

        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(1, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @isTest
    static void it_should_save_via_queueable_when_specified() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getQueueableJobs());

        Test.startTest();

        Logger.saveLog(Logger.SaveMethod.QUEUEABLE);
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(1, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());

        Test.getEventBus().deliver();

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @isTest
    static void it_should_save_via_rest_api_when_defaulted() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.getUserSettings().DefaultSaveMethod__c = 'REST';

        System.assertEquals(Logger.SaveMethod.REST, Logger.transactionSaveMethod);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getCallouts());

        Test.startTest();

        Logger.saveLog();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(1, Limits.getCallouts());

        Test.stopTest();
    }

    @isTest
    static void it_should_save_via_rest_api_when_specified() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getCallouts());

        Test.startTest();

        Logger.saveLog(Logger.SaveMethod.REST);
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(1, Limits.getCallouts());

        Test.stopTest();
    }

    @isTest
    static void it_should_throw_exception_when_save_via_rest_api_fails() {
        Test.setMock(HttpCalloutMock.class, new FailureCalloutMock());

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getCallouts());

        Test.startTest();

        try {
            Logger.saveLog(Logger.SaveMethod.REST);
        } catch (Exception ex) {
            System.assertEquals(ex.getTypeName(), Logger.RestResponseException.class.getName());
        }
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(1, Limits.getCallouts());

        Test.stopTest();
    }

    @isTest
    static void it_should_flush_buffer() {
        System.assertEquals(0, Logger.getBufferSize());

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Test.startTest();

        Logger.debug('test log entry');
        Logger.debug('another test log entry');
        System.assertEquals(2, Logger.getBufferSize());

        Logger.flushBuffer();

        Logger.debug('the only log entry to save');
        System.assertEquals(1, Logger.getBufferSize());

        Test.stopTest();
    }

    // Start ERROR methods for LogMessage
    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord().Id, getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End ERROR methods for LogMessage

    // Start ERROR methods for String
    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord().Id, getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    // Start WARN methods for LogMessage
    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord().Id, getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End WARN methods for LogMessage

    // Start WARN methods for String
    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord().Id, getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_a_warn_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End WARN methods for String

    // Start INFO methods for LogMessage
    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), deleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), saveResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), undeleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), upsertResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), users);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End INFO methods for LogMessage

    // Start INFO methods for String
    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), deleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), saveResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), undeleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), upsertResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), users);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End INFO methods for String

    // Start DEBUG methods for LogMessage
    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), deleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), saveResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), undeleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), upsertResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), users);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End DEBUG methods for LogMessage

    // Start DEBUG methods for String
    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), deleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), saveResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), undeleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), upsertResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), users);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End DEBUG methods for String

    // Start FINE methods for LogMessage
    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), deleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), saveResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), undeleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), upsertResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), users);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINE methods for LogMessage

    // Start FINE methods for String
    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), deleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), saveResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), undeleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), upsertResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), users);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINE methods for String

    // Start FINER methods for LogMessage
    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), deleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), saveResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), undeleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), upsertResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), users);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINER methods for LogMessage

    // Start FINER methods for String
    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), deleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), saveResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), undeleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), upsertResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), users);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINER methods for String

    // Start FINEST methods for LogMessage
    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), deleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), saveResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), undeleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), upsertResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), users);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINEST methods for LogMessage

    // Start FINEST methods for String
    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), deleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), saveResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), undeleteResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), upsertResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), users);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINEST methods for String

    // Start newEntry for LogMessage test methods
    @isTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_logMessage_and_shouldSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        Boolean shouldSave = true;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getLogMessage(), shouldSave);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(logEntryLoggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_not_add_a_new_entry_for_loggingLevel_with_logMessage_and_shouldNotSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        Boolean shouldSave = false;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getLogMessage(), shouldSave);

        Test.stopTest();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(null, entryBuilder.getLogEntryEvent());
    }

    @isTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.newEntry(loggingLevel, getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(true, entryBuilder.shouldSave());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End newEntry for LogMessage test methods

    // Start newEntry for String test methods
    @isTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_string_and_shouldSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        Boolean shouldSave = true;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getMessage(), shouldSave);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(logEntryLoggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_not_add_a_new_entry_for_loggingLevel_with_string_and_shouldNotSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        Boolean shouldSave = false;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getMessage(), shouldSave);

        Test.stopTest();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(null, entryBuilder.getLogEntryEvent());
    }

    @isTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_string() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.newEntry(loggingLevel, getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(true, entryBuilder.shouldSave());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End newEntry for String test methods

    // Start tests for utility methods
    @isTest
    static void it_should_return_logging_levels_for_string_names() {
        System.assertEquals(LoggingLevel.DEBUG, Logger.getLoggingLevel('fake'));
        System.assertEquals(LoggingLevel.NONE, Logger.getLoggingLevel('none'));
        System.assertEquals(LoggingLevel.ERROR, Logger.getLoggingLevel('error'));
        System.assertEquals(LoggingLevel.WARN, Logger.getLoggingLevel('warn'));
        System.assertEquals(LoggingLevel.INFO, Logger.getLoggingLevel('info'));
        System.assertEquals(LoggingLevel.DEBUG, Logger.getLoggingLevel('debug'));
        System.assertEquals(LoggingLevel.FINE, Logger.getLoggingLevel('fine'));
        System.assertEquals(LoggingLevel.FINER, Logger.getLoggingLevel('finer'));
        System.assertEquals(LoggingLevel.FINEST, Logger.getLoggingLevel('finest'));
    }

    @isTest
    static void it_should_return_log_when_id_provided() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Test.startTest();
        Log__c returnedLog = Logger.getLog(log.Id);
        Test.stopTest();

        System.assertEquals(log.Id, returnedLog.Id);
    }

    @isTest
    static void it_should_return_log_when_transaction_id_provided() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Test.startTest();
        Log__c returnedLog = Logger.getLog(log.TransactionId__c);
        Test.stopTest();

        System.assertEquals(log.Id, returnedLog.Id);
    }
    // End tests for utility methods
}
