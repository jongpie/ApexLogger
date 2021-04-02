//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class LogEntryEventHandler_Tests {
    private static final String MOCK_RELEASE_NUMBER = '230.12.2';
    private static final String MOCK_RELEASE_VERSION = 'Spring \'21 Patch 12.2';

    static User getCurrentUser() {
        return [
            SELECT
                Id,
                ProfileId,
                Profile.Name,
                Profile.UserLicenseId,
                Profile.UserLicense.LicenseDefinitionKey,
                Profile.UserLicense.Name,
                Username,
                UserRoleId,
                UserRole.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
    }

    static Log__c getLog() {
        return [
            SELECT
                ApiReleaseNumber__c,
                ApiReleaseVersion__c,
                ApiVersion__c,
                Id,
                Locale__c,
                LoggedBy__c,
                LoggedByUsername__c,
                LoginDomain__c,
                LoginHistoryId__c,
                LoginType__c,
                LogoutUrl__c,
                NetworkId__c,
                OrganizationDomainUrl__c,
                OrganizationEnvironmentType__c,
                OrganizationId__c,
                OrganizationInstanceName__c,
                OrganizationName__c,
                OrganizationNamespacePrefix__c,
                OrganizationType__c,
                OwnerId,
                ParentLog__c,
                ProfileId__c,
                ProfileName__c,
                SessionId__c,
                SessionSecurityLevel__c,
                SessionType__c,
                SourceIp__c,
                SystemMode__c,
                ThemeDisplayed__c,
                TimeZoneId__c,
                TimeZoneName__c,
                TransactionId__c,
                UserLicenseDefinitionKey__c,
                UserLicenseId__c,
                UserLicenseName__c,
                UserLoggingLevel__c,
                UserLoggingLevelOrdinal__c,
                UserRoleId__c,
                UserRoleName__c,
                UserType__c,
                (
                    SELECT
                        ExceptionStackTrace__c,
                        ExceptionType__c,
                        LimitsAggregateQueriesMax__c,
                        LimitsAggregateQueriesUsed__c,
                        LimitsAsyncCallsMax__c,
                        LimitsAsyncCallsUsed__c,
                        LimitsCalloutsMax__c,
                        LimitsCalloutsUsed__c,
                        LimitsCpuTimeMax__c,
                        LimitsCpuTimeUsed__c,
                        LimitsDmlRowsMax__c,
                        LimitsDmlRowsUsed__c,
                        LimitsDmlStatementsMax__c,
                        LimitsDmlStatementsUsed__c,
                        LimitsEmailInvocationsMax__c,
                        LimitsEmailInvocationsUsed__c,
                        LimitsFutureCallsMax__c,
                        LimitsFutureCallsUsed__c,
                        LimitsHeapSizeMax__c,
                        LimitsHeapSizeUsed__c,
                        LimitsMobilePushApexCallsMax__c,
                        LimitsMobilePushApexCallsUsed__c,
                        LimitsQueueableJobsMax__c,
                        LimitsQueueableJobsUsed__c,
                        LimitsSoqlQueriesMax__c,
                        LimitsSoqlQueriesUsed__c,
                        LimitsSoqlQueryLocatorRowsMax__c,
                        LimitsSoqlQueryLocatorRowsUsed__c,
                        LimitsSoqlQueryRowsMax__c,
                        LimitsSoqlQueryRowsUsed__c,
                        LimitsSoslSearchesUsed__c,
                        LimitsSoslSearchesMax__c,
                        Log__c,
                        LoggingLevel__c,
                        LoggingLevelOrdinal__c,
                        Message__c,
                        MessageTruncated__c,
                        Id,
                        Name,
                        OriginType__c,
                        OriginLocation__c,
                        RecordId__c,
                        RecordJson__c,
                        RecordSObjectClassification__c,
                        RecordSObjectType__c,
                        RecordSObjectTypeNamespace__c,
                        StackTrace__c,
                        Timestamp__c,
                        TransactionEntryNumber__c,
                        TriggerIsExecuting__c,
                        TriggerOperationType__c,
                        TriggerSObjectType__c
                    FROM LogEntries__r
                )
            FROM Log__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
    }

    private class SuccessCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            LogEntryEventHandler.StatusApiResponse apiResponse = new LogEntryEventHandler.StatusApiResponse();
            apiResponse.releaseNumber = MOCK_RELEASE_NUMBER;
            apiResponse.releaseVersion = MOCK_RELEASE_VERSION;

            HttpResponse response = new HttpResponse();
            response.setBody(JSON.serialize(apiResponse));
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);

            return response;
        }
    }

    private class FailureCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);
            return response;
        }
    }

    static void validateLogFields(LogEntryEvent__e logEntryEvent, Log__c log) {
        Organization org = [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
        User currentUser = getCurrentUser();
        String orgEnvironmentType;
        if (org.IsSandbox == true && org.TrialExpirationDate != null) {
            orgEnvironmentType = 'Scratch Org';
        } else if (org.IsSandbox == true) {
            orgEnvironmentType = 'Sandbox';
        } else {
            orgEnvironmentType = 'Production';
        }

        System.assertEquals(logEntryEvent.ApiVersion__c, log.ApiVersion__c);
        System.assertEquals(logEntryEvent.Locale__c, log.Locale__c);
        //System.assertEquals(logEntryEvent.CreatedById, log.LoggedBy__c);
        System.assertEquals(logEntryEvent.LoggedByUsername__c, log.LoggedByUsername__c);
        System.assertEquals(logEntryEvent.LoginDomain__c, log.LoginDomain__c);
        System.assertEquals(logEntryEvent.LoginHistoryId__c, log.LoginHistoryId__c);
        System.assertEquals(logEntryEvent.LoginType__c, log.LoginType__c);
        System.assertEquals(logEntryEvent.LogoutUrl__c, log.LogoutUrl__c);
        System.assertEquals(logEntryEvent.NetworkId__c, log.NetworkId__c);
        //System.assertEquals(logEntryEvent.CreatedById, log.OwnerId);
        System.assertEquals(logEntryEvent.ProfileId__c, log.ProfileId__c);
        System.assertEquals(logEntryEvent.SessionId__c, log.SessionId__c);
        System.assertEquals(logEntryEvent.SessionId__c, log.SessionId__c);
        System.assertEquals(logEntryEvent.SessionSecurityLevel__c, log.SessionSecurityLevel__c);
        System.assertEquals(logEntryEvent.SessionType__c, log.SessionType__c);
        System.assertEquals(logEntryEvent.SourceIp__c, log.SourceIp__c);
        System.assertEquals(logEntryEvent.SystemMode__c, log.SystemMode__c);
        System.assertEquals(logEntryEvent.ThemeDisplayed__c, log.ThemeDisplayed__c);
        System.assertEquals(logEntryEvent.TimeZoneId__c, log.TimeZoneId__c);
        System.assertEquals(logEntryEvent.TimeZoneName__c, log.TimeZoneName__c);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        System.assertEquals(logEntryEvent.UserLoggingLevel__c, log.UserLoggingLevel__c);
        System.assertEquals(logEntryEvent.UserLoggingLevelOrdinal__c, log.UserLoggingLevelOrdinal__c);
        // System.assertEquals(currentUser.UserRoleId, log.UserRoleId__c);
        // System.assertEquals(currentUser.UserRoleId == null ? null : currentUser.UserRole.Name, log.UserRoleName__c);
        System.assertEquals(logEntryEvent.UserType__c, log.UserType__c);

        // Org fields
        System.assertEquals(logEntryEvent.OrganizationDomainUrl__c, log.OrganizationDomainUrl__c);
        System.assertEquals(logEntryEvent.OrganizationEnvironmentType__c, log.OrganizationEnvironmentType__c);
        System.assertEquals(logEntryEvent.OrganizationId__c, log.OrganizationId__c);
        System.assertEquals(logEntryEvent.OrganizationInstanceName__c, log.OrganizationInstanceName__c);
        System.assertEquals(logEntryEvent.OrganizationName__c, log.OrganizationName__c);
        System.assertEquals(logEntryEvent.OrganizationNamespacePrefix__c, log.OrganizationNamespacePrefix__c);
        System.assertEquals(logEntryEvent.OrganizationType__c, log.OrganizationType__c);

        // Profile fields
        System.assertEquals(logEntryEvent.UserLicenseDefinitionKey__c, log.UserLicenseDefinitionKey__c);
        System.assertEquals(logEntryEvent.UserLicenseId__c, log.UserLicenseId__c);
        System.assertEquals(logEntryEvent.UserLicenseName__c, log.UserLicenseName__c);
    }

    static void validateLogEntryFields(LogEntryEvent__e logEntryEvent, LogEntry__c logEntry) {
        System.assertEquals(logEntryEvent.ExceptionStackTrace__c, logEntry.ExceptionStackTrace__c);
        System.assertEquals(logEntryEvent.ExceptionType__c, logEntry.ExceptionType__c);
        System.assertEquals(logEntryEvent.LimitsAggregateQueriesMax__c, logEntry.LimitsAggregateQueriesMax__c);
        System.assertEquals(logEntryEvent.LimitsAggregateQueriesUsed__c, logEntry.LimitsAggregateQueriesUsed__c);
        System.assertEquals(logEntryEvent.LimitsAsyncCallsMax__c, logEntry.LimitsAsyncCallsMax__c);
        System.assertEquals(logEntryEvent.LimitsAsyncCallsUsed__c, logEntry.LimitsAsyncCallsUsed__c);
        System.assertEquals(logEntryEvent.LimitsCalloutsMax__c, logEntry.LimitsCalloutsMax__c);
        System.assertEquals(logEntryEvent.LimitsCalloutsUsed__c, logEntry.LimitsCalloutsUsed__c);
        System.assertEquals(logEntryEvent.LimitsCpuTimeMax__c, logEntry.LimitsCpuTimeMax__c);
        System.assertEquals(logEntryEvent.LimitsCpuTimeUsed__c, logEntry.LimitsCpuTimeUsed__c);
        System.assertEquals(logEntryEvent.LimitsDmlRowsMax__c, logEntry.LimitsDmlRowsMax__c);
        System.assertEquals(logEntryEvent.LimitsDmlRowsUsed__c, logEntry.LimitsDmlRowsUsed__c);
        System.assertEquals(logEntryEvent.LimitsDmlStatementsMax__c, logEntry.LimitsDmlStatementsMax__c);
        System.assertEquals(logEntryEvent.LimitsDmlStatementsUsed__c, logEntry.LimitsDmlStatementsUsed__c);
        System.assertEquals(logEntryEvent.LimitsEmailInvocationsMax__c, logEntry.LimitsEmailInvocationsMax__c);
        System.assertEquals(logEntryEvent.LimitsEmailInvocationsUsed__c, logEntry.LimitsEmailInvocationsUsed__c);
        System.assertEquals(logEntryEvent.LimitsFutureCallsMax__c, logEntry.LimitsFutureCallsMax__c);
        System.assertEquals(logEntryEvent.LimitsFutureCallsUsed__c, logEntry.LimitsFutureCallsUsed__c);
        System.assertEquals(logEntryEvent.LimitsHeapSizeMax__c, logEntry.LimitsHeapSizeMax__c);
        System.assertEquals(logEntryEvent.LimitsHeapSizeUsed__c, logEntry.LimitsHeapSizeUsed__c);
        System.assertEquals(logEntryEvent.LimitsMobilePushApexCallsMax__c, logEntry.LimitsMobilePushApexCallsMax__c);
        System.assertEquals(logEntryEvent.LimitsMobilePushApexCallsUsed__c, logEntry.LimitsMobilePushApexCallsUsed__c);
        System.assertEquals(logEntryEvent.LimitsQueueableJobsMax__c, logEntry.LimitsQueueableJobsMax__c);
        System.assertEquals(logEntryEvent.LimitsQueueableJobsUsed__c, logEntry.LimitsQueueableJobsUsed__c);
        System.assertEquals(logEntryEvent.LimitsSoqlQueriesMax__c, logEntry.LimitsSoqlQueriesMax__c);
        System.assertEquals(logEntryEvent.LimitsSoqlQueriesUsed__c, logEntry.LimitsSoqlQueriesUsed__c);
        System.assertEquals(logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c, logEntry.LimitsSoqlQueryLocatorRowsMax__c);
        System.assertEquals(logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c, logEntry.LimitsSoqlQueryLocatorRowsUsed__c);
        System.assertEquals(logEntryEvent.LimitsSoqlQueryRowsMax__c, logEntry.LimitsSoqlQueryRowsMax__c);
        System.assertEquals(logEntryEvent.LimitsSoqlQueryRowsUsed__c, logEntry.LimitsSoqlQueryRowsUsed__c);
        System.assertEquals(logEntryEvent.LimitsSoslSearchesUsed__c, logEntry.LimitsSoslSearchesUsed__c);
        System.assertEquals(logEntryEvent.LimitsSoslSearchesMax__c, logEntry.LimitsSoslSearchesMax__c);
        System.assertEquals(logEntryEvent.LoggingLevel__c, logEntry.LoggingLevel__c);
        System.assertEquals(logEntryEvent.LoggingLevelOrdinal__c, logEntry.LoggingLevelOrdinal__c);
        System.assertEquals(logEntryEvent.Message__c, logEntry.Message__c);
        System.assertEquals(logEntryEvent.MessageTruncated__c, logEntry.MessageTruncated__c);
        System.assertEquals(logEntry.Id, logEntry.Name);
        System.assertEquals(logEntryEvent.OriginType__c, logEntry.OriginType__c);
        System.assertEquals(logEntryEvent.OriginLocation__c, logEntry.OriginLocation__c);
        System.assertEquals(logEntryEvent.RecordId__c, logEntry.RecordId__c);
        System.assertEquals(logEntryEvent.RecordJson__c, logEntry.RecordJson__c);
        System.assertEquals(logEntryEvent.RecordSObjectClassification__c, logEntry.RecordSObjectClassification__c);
        System.assertEquals(logEntryEvent.RecordSObjectType__c, logEntry.RecordSObjectType__c);
        System.assertEquals(logEntryEvent.RecordSObjectTypeNamespace__c, logEntry.RecordSObjectTypeNamespace__c);
        System.assertEquals(logEntryEvent.StackTrace__c, logEntry.StackTrace__c);
        System.assertEquals(logEntryEvent.Timestamp__c, logEntry.Timestamp__c);
        System.assertEquals(logEntryEvent.TransactionEntryNumber__c, logEntry.TransactionEntryNumber__c);
        System.assertEquals(logEntryEvent.TriggerIsExecuting__c, logEntry.TriggerIsExecuting__c);
        System.assertEquals(logEntryEvent.TriggerOperationType__c, logEntry.TriggerOperationType__c);
        System.assertEquals(logEntryEvent.TriggerSObjectType__c, logEntry.TriggerSObjectType__c);
    }

    @isTest
    static void it_should_normalize_simple_event_data_into_log_and_log_entry() {
        String transactionId = '123-456-789-0';

        LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
            Message__c = 'my message',
            Timestamp__c = System.now(),
            TransactionEntryNumber__c = 1,
            TransactionId__c = transactionId
        );

        Test.startTest();
        Database.SaveResult saveResult = EventBus.publish(logEntryEvent);
        Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());

        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);

        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @isTest
    static void it_should_normalize_complex_event_data_into_log_and_log_entry() {
        String transactionId = '123-456-789-0';
        User currentUser = getCurrentUser();
        DmlException dmlException = new DmlException();

        LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
            ApiVersion__c = '99.0',
            ExceptionStackTrace__c = dmlException.getStackTraceString(),
            ExceptionType__c = dmlException.getTypeName(),
            LimitsAggregateQueriesMax__c = 987,
            LimitsAggregateQueriesUsed__c = 123,
            LimitsAsyncCallsMax__c = 987,
            LimitsAsyncCallsUsed__c = 123,
            LimitsCalloutsMax__c = 987,
            LimitsCalloutsUsed__c = 123,
            LimitsCpuTimeMax__c = 987,
            LimitsCpuTimeUsed__c = 123,
            LimitsDmlRowsMax__c = 987,
            LimitsDmlRowsUsed__c = 123,
            LimitsDmlStatementsMax__c = 987,
            LimitsDmlStatementsUsed__c = 123,
            LimitsEmailInvocationsMax__c = 987,
            LimitsEmailInvocationsUsed__c = 123,
            LimitsFutureCallsMax__c = 987,
            LimitsFutureCallsUsed__c = 123,
            LimitsHeapSizeMax__c = 987,
            LimitsHeapSizeUsed__c = 123,
            LimitsMobilePushApexCallsMax__c = 987,
            LimitsMobilePushApexCallsUsed__c = 123,
            LimitsQueueableJobsMax__c = 987,
            LimitsQueueableJobsUsed__c = 123,
            LimitsSoqlQueriesMax__c = 987,
            LimitsSoqlQueriesUsed__c = 123,
            LimitsSoqlQueryLocatorRowsMax__c = 987,
            LimitsSoqlQueryLocatorRowsUsed__c = 123,
            LimitsSoqlQueryRowsMax__c = 987,
            LimitsSoqlQueryRowsUsed__c = 123,
            LimitsSoslSearchesMax__c = 987,
            LimitsSoslSearchesUsed__c = 123,
            Locale__c = 'es-ES',
            LoggingLevel__c = 'DEBUG',
            LoggingLevelOrdinal__c = 9,
            LoginDomain__c = 'https://fake.my.salesforce.com',
            LoginHistoryId__c = '255.255.255.255',
            LoginType__c = null,
            LogoutUrl__c = null,
            Message__c = 'My message',
            MessageTruncated__c = false,
            NetworkId__c = 'Fake-ID',
            OriginLocation__c = 'right here',
            OriginType__c = 'Apex',
            ProfileId__c = currentUser.ProfileId,
            RecordId__c = currentUser.Id,
            RecordJson__c = JSON.serializePretty(currentUser),
            RecordSObjectClassification__c = 'Standard Object',
            RecordSObjectType__c = 'User',
            SessionId__c = null,
            SessionSecurityLevel__c = null,
            SessionType__c = null,
            SourceIp__c = null,
            StackTrace__c = 'I started here \nand then went there',
            SystemMode__c = System.Quiddity.SYNCHRONOUS.name(),
            ThemeDisplayed__c = 'SomeTheme',
            Timestamp__c = System.now(),
            TimeZoneId__c = 'fake-id',
            TimeZoneName__c = 'My time zone name',
            TransactionEntryNumber__c = 1,
            TransactionId__c = transactionId,
            TriggerIsExecuting__c = false,
            TriggerOperationType__c = 'SomeOperation',
            TriggerSObjectType__c = 'Account',
            UserLoggingLevel__c = 'DEBUG',
            UserLoggingLevelOrdinal__c = 9,
            UserRoleId__c = currentUser.UserRoleId,
            UserType__c = null
        );

        Test.startTest();
        Database.SaveResult saveResult = EventBus.publish(logEntryEvent);
        Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());

        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);

        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @isTest
    static void it_should_normalize_event_data_for_multiple_transactions_into_multiple_logs() {
        List<String> transactionIds = new List<String>{ '123-456', '789-0' };
        System.assertEquals(2, transactionIds.size());

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        for (Integer i = 0; i < transactionIds.size(); i++) {
            LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
                Message__c = 'my message',
                Timestamp__c = System.now(),
                TransactionEntryNumber__c = i,
                TransactionId__c = transactionIds.get(i)
            );

            logEntryEvents.add(logEntryEvent);
        }
        System.assertEquals(transactionIds.size(), logEntryEvents.size());

        Test.startTest();
        List<Database.SaveResult> saveResults = EventBus.publish(logEntryEvents);
        Test.getEventBus().deliver();
        System.assertEquals(transactionIds.size(), saveResults.size());
        Test.stopTest();

        for (Database.SaveResult saveResult : saveResults) {
            System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        }

        List<Log__c> logs = [SELECT Id, TransactionId__c, (SELECT Id FROM LogEntries__r) FROM Log__c];

        System.assertEquals(2, logs.size(), logs);

        // Convert the list of txn IDs to a set so we can use `contains()`
        Set<String> uniqueTransactionIds = new Set<String>(transactionIds);
        for (Log__c log : logs) {
            System.assert(uniqueTransactionIds.contains(log.TransactionId__c), log.TransactionId__c);
            System.assertEquals(1, log.LogEntries__r.size());
        }
    }

    @isTest
    static void it_should_create_topic_and_topicAssignment_records() {
        String transactionId = '123-456-789-0';

        List<String> topics = new List<String>{ 'test-topic-1', 'test-topic-2' };
        LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
            Message__c = 'my message',
            Timestamp__c = System.now(),
            Topics__c = String.join(topics, ','),
            TransactionEntryNumber__c = 1,
            TransactionId__c = transactionId
        );

        Test.startTest();
        Database.SaveResult saveResult = EventBus.publish(logEntryEvent);
        Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());

        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);

        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);

        Set<String> topicsSet = new Set<String>(topics);
        List<TopicAssignment> topicAssignments = [SELECT Id, EntityId, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId = :logEntry.Id];
        for (TopicAssignment topicAssignment : topicAssignments) {
            System.assert(topicsSet.contains(topicAssignment.Topic.Name));
        }
    }

    @isTest
    static void it_should_set_api_release_number_and_api_release_version_from_callout_when_enabled() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());
        LogEntryEventHandler.shouldCallStatusApi = true;

        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        orgDefaults.EnableStatusApiCallout__c = true;
        upsert orgDefaults;

        String transactionId = '123-456-789-0';
        LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
            Message__c = 'my message',
            Timestamp__c = System.now(),
            TransactionEntryNumber__c = 1,
            TransactionId__c = transactionId
        );

        Database.SaveResult saveResult;

        Test.startTest();

        saveResult = EventBus.publish(logEntryEvent);
        // Normally, you don't have to call Test.getEventBus().deliver() if you're also using Test.stopTest()
        // But, in this case, there are 3 transactions happening (original test, async platform event, and async future method)
        // So, call Test.getEventBus().deliver() and Test.stopTest() to make sure all transactions are completed before running asserts
        Test.getEventBus().deliver();

        Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());

        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);

        System.assertEquals(MOCK_RELEASE_NUMBER, log.ApiReleaseNumber__c);
        System.assertEquals(MOCK_RELEASE_VERSION, log.ApiReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @isTest
    static void it_should_set_not_api_release_number_or_api_release_version_from_callout_when_disabled() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());
        LogEntryEventHandler.shouldCallStatusApi = true;

        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        orgDefaults.EnableStatusApiCallout__c = false;
        upsert orgDefaults;

        String transactionId = '123-456-789-0';
        LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
            Message__c = 'my message',
            Timestamp__c = System.now(),
            TransactionEntryNumber__c = 1,
            TransactionId__c = transactionId
        );

        Database.SaveResult saveResult;

        Test.startTest();

        saveResult = EventBus.publish(logEntryEvent);
        // Normally, you don't have to call Test.getEventBus().deliver() if you're also using Test.stopTest()
        // But, in this case, there are 3 transactions happening (original test, async platform event, and async future method)
        // So, call Test.getEventBus().deliver() and Test.stopTest() to make sure all transactions are completed before running asserts
        Test.getEventBus().deliver();

        System.assertEquals(0, Limits.getCallouts());

        Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());

        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);

        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        System.assertEquals(null, log.ApiReleaseNumber__c);
        System.assertEquals(null, log.ApiReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @isTest
    static void it_should_skip_setting_api_release_number_and_api_release_version_when_callout_fails() {
        Test.setMock(HttpCalloutMock.class, new FailureCalloutMock());
        LogEntryEventHandler.shouldCallStatusApi = true;

        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        orgDefaults.EnableStatusApiCallout__c = true;
        upsert orgDefaults;

        String transactionId = '123-456-789-0';
        LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
            Message__c = 'my message',
            Timestamp__c = System.now(),
            TransactionEntryNumber__c = 1,
            TransactionId__c = transactionId
        );

        Database.SaveResult saveResult;
        try {
            Test.startTest();

            saveResult = EventBus.publish(logEntryEvent);
            // Normally, you don't have to call Test.getEventBus().deliver() if you're also using Test.stopTest()
            // But, in this case, there are 3 transactions happening (original test, async platform event, and async future method)
            // So, call Test.getEventBus().deliver() and Test.stopTest() to make sure all transactions are completed before running asserts
            Test.getEventBus().deliver();

            Test.stopTest();
            System.assert(false, 'Exception expected, this assert should not run');
        } catch (Exception ex) {
            System.assertEquals(LogEntryEventHandler.StatusApiResponseException.class.getName(), ex.getTypeName());

            String expectedErrorMessage = 'Callout failed for https://api.status.salesforce.com/v1/instances/';
            System.assert(ex.getMessage().contains(expectedErrorMessage));
        }

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());

        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);

        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        System.assertEquals(null, log.ApiReleaseNumber__c);
        System.assertEquals(null, log.ApiReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }
}
