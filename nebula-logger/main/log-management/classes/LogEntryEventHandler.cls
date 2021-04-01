//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group log-management
 * @description Subscribes to `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records
 */
public without sharing class LogEntryEventHandler {
    private static final Map<String, Log__c> TRANSACTION_ID_TO_LOG = new Map<String, Log__c>();
    private static final String TOPICS_DELIMITER = ',';
    private static final List<LogEntryTopicAssignment__mdt> TOPIC_ASSIGNMENT_RULES = getTopicAssignmentRules();

    @TestVisible
    private static Boolean shouldCallStatusApi = Test.isRunningTest() == false;

    private List<LogEntry__c> logEntries;
    private Map<Id, LogEntry__c> logEntryIdToLogEntry = new Map<Id, LogEntry__c>();
    private Map<Id, Set<String>> logEntryIdToTopics;
    private Set<String> topicNames;

    public LogEntryEventHandler() {
        this.logEntries = new List<LogEntry__c>();
        this.logEntryIdToLogEntry = new Map<Id, LogEntry__c>();
        this.logEntryIdToTopics = new Map<Id, Set<String>>();
        this.topicNames = new Set<String>();
    }

    public void execute() {
        List<LogEntryEvent__e> logEntryEvents = (List<LogEntryEvent__e>) Trigger.new;

        switch on Trigger.operationType {
            when AFTER_INSERT {
                this.upsertLogs(logEntryEvents);
                this.insertLogEntries(logEntryEvents);
                this.appendCmdtTopics();
                this.insertTopics();
            }
        }
    }

    private void upsertLogs(List<LogEntryEvent__e> logEntryEvents) {
        Log__c recentLogWithApiReleaseDetails = getRecentLogWithApiReleaseDetails();

        // The LogEntryEvent__e object stores a denormalized version of Log__c & LogEntry__c data
        // In case the list contains entries tied to multiple transactions, use the TRANSACTION_ID_TO_LOG map to create 1 Log__c per transaction ID

        for (LogEntryEvent__e logEntryEvent : logEntryEvents) {
            if (TRANSACTION_ID_TO_LOG.containsKey(logEntryEvent.TransactionId__c) == true) {
                continue;
            }

            Log__c parentLog = new Log__c(TransactionId__c = logEntryEvent.ParentLogTransactionId__c);
            Log__c log = new Log__c();
            // To avoid making a callout for every log for details retrieved from api.status.salesforce.com,
            // ...try to query recent logs first to see if there is a recent log with the details already populated
            if (recentLogWithApiReleaseDetails != null) {
                log.ApiReleaseNumber__c = recentLogWithApiReleaseDetails.ApiReleaseNumber__c;
                log.ApiReleaseVersion__c = recentLogWithApiReleaseDetails.ApiReleaseVersion__c;
            }

            log.ApiVersion__c = logEntryEvent.ApiVersion__c;
            log.Locale__c = logEntryEvent.Locale__c;
            log.LoggedBy__c = logEntryEvent.CreatedById;
            log.LoggedByUsername__c = logEntryEvent.LoggedByUsername__c;
            log.LoginDomain__c = logEntryEvent.LoginDomain__c;
            log.LoginHistoryId__c = logEntryEvent.LoginHistoryId__c;
            log.LoginApplication__c = logEntryEvent.LoginApplication__c;
            log.LoginBrowser__c = logEntryEvent.LoginBrowser__c;
            log.LoginPlatform__c = logEntryEvent.LoginPlatform__c;
            log.LoginType__c = logEntryEvent.LoginType__c;
            log.LogoutUrl__c = logEntryEvent.LogoutUrl__c;
            log.NetworkId__c = logEntryEvent.NetworkId__c;
            log.NetworkLoginUrl__c = logEntryEvent.NetworkLoginUrl__c;
            log.NetworkLogoutUrl__c = logEntryEvent.NetworkLogoutUrl__c;
            log.NetworkName__c = logEntryEvent.NetworkName__c;
            log.NetworkSelfRegistrationUrl__c = logEntryEvent.NetworkSelfRegistrationUrl__c;
            log.NetworkUrlPathPrefix__c = logEntryEvent.NetworkUrlPathPrefix__c;
            log.OrganizationDomainUrl__c = logEntryEvent.OrganizationDomainUrl__c;
            log.OrganizationEnvironmentType__c = logEntryEvent.OrganizationEnvironmentType__c;
            log.OrganizationId__c = logEntryEvent.OrganizationId__c;
            log.OrganizationInstanceName__c = logEntryEvent.OrganizationInstanceName__c;
            log.OrganizationName__c = logEntryEvent.OrganizationName__c;
            log.OrganizationNamespacePrefix__c = logEntryEvent.OrganizationNamespacePrefix__c;
            log.OrganizationType__c = logEntryEvent.OrganizationType__c;
            log.OwnerId = logEntryEvent.CreatedById;
            log.ParentLog__r = logEntryEvent.ParentLogTransactionId__c == null ? null : parentLog;
            log.ProfileId__c = logEntryEvent.ProfileId__c;
            log.ProfileName__c = logEntryEvent.ProfileName__c;
            log.SessionId__c = logEntryEvent.SessionId__c;
            log.SessionId__c = logEntryEvent.SessionId__c;
            log.SessionSecurityLevel__c = logEntryEvent.SessionSecurityLevel__c;
            log.SessionType__c = logEntryEvent.SessionType__c;
            log.SourceIp__c = logEntryEvent.SourceIp__c;
            log.SystemMode__c = logEntryEvent.SystemMode__c;
            log.ThemeDisplayed__c = logEntryEvent.ThemeDisplayed__c;
            log.TimeZoneId__c = logEntryEvent.TimeZoneId__c;
            log.TimeZoneName__c = logEntryEvent.TimeZoneName__c;
            log.TransactionId__c = logEntryEvent.TransactionId__c;
            log.UserLicenseDefinitionKey__c = logEntryEvent.UserLicenseDefinitionKey__c;
            log.UserLicenseId__c = logEntryEvent.UserLicenseId__c;
            log.UserLicenseName__c = logEntryEvent.UserLicenseName__c;
            log.UserLoggingLevel__c = logEntryEvent.UserLoggingLevel__c;
            log.UserLoggingLevelOrdinal__c = logEntryEvent.UserLoggingLevelOrdinal__c;
            log.UserRoleId__c = logEntryEvent.UserRoleId__c;
            log.UserRoleName__c = logEntryEvent.UserRoleName__c;
            log.UserType__c = logEntryEvent.UserType__c;

            TRANSACTION_ID_TO_LOG.put(log.TransactionId__c, log);
        }

        upsert TRANSACTION_ID_TO_LOG.values() TransactionId__c;

        // If no recent logs have the details, and there is not another instance of the job in progress, then start a new one
        if (
            shouldCallStatusApi == true &&
            LoggerSettings__c.getOrgDefaults().EnableStatusApiCallout__c &&
            recentLogWithApiReleaseDetails == null &&
            getCountOfOpenJobs() == 0
        ) {
            setStatusApiDetails();
        }
    }

    private void insertLogEntries(List<LogEntryEvent__e> logEntryEvents) {
        for (LogEntryEvent__e logEntryEvent : logEntryEvents) {
            // Workaround field for platform issue w/ accurate datetimes
            Datetime timestamp = String.isNotBlank(logEntryEvent.TimestampString__c)
                ? Datetime.valueOf(logEntryEvent.TimestampString__c)
                : logEntryEvent.Timestamp__c;

            LogEntry__c logEntry = new LogEntry__c(
                DatabaseResultCollectionType__c = logEntryEvent.DatabaseResultCollectionType__c,
                DatabaseResultJson__c = logEntryEvent.DatabaseResultJson__c,
                DatabaseResultType__c = logEntryEvent.DatabaseResultType__c,
                ExceptionMessage__c = logEntryEvent.ExceptionMessage__c,
                ExceptionStackTrace__c = logEntryEvent.ExceptionStackTrace__c,
                ExceptionType__c = logEntryEvent.ExceptionType__c,
                LimitsAggregateQueriesMax__c = logEntryEvent.LimitsAggregateQueriesMax__c,
                LimitsAggregateQueriesUsed__c = logEntryEvent.LimitsAggregateQueriesUsed__c,
                LimitsAsyncCallsMax__c = logEntryEvent.LimitsAsyncCallsMax__c,
                LimitsAsyncCallsUsed__c = logEntryEvent.LimitsAsyncCallsUsed__c,
                LimitsCalloutsMax__c = logEntryEvent.LimitsCalloutsMax__c,
                LimitsCalloutsUsed__c = logEntryEvent.LimitsCalloutsUsed__c,
                LimitsCpuTimeMax__c = logEntryEvent.LimitsCpuTimeMax__c,
                LimitsCpuTimeUsed__c = logEntryEvent.LimitsCpuTimeUsed__c,
                LimitsDmlRowsMax__c = logEntryEvent.LimitsDmlRowsMax__c,
                LimitsDmlRowsUsed__c = logEntryEvent.LimitsDmlRowsUsed__c,
                LimitsDmlStatementsMax__c = logEntryEvent.LimitsDmlStatementsMax__c,
                LimitsDmlStatementsUsed__c = logEntryEvent.LimitsDmlStatementsUsed__c,
                LimitsEmailInvocationsMax__c = logEntryEvent.LimitsEmailInvocationsMax__c,
                LimitsEmailInvocationsUsed__c = logEntryEvent.LimitsEmailInvocationsUsed__c,
                LimitsFutureCallsMax__c = logEntryEvent.LimitsFutureCallsMax__c,
                LimitsFutureCallsUsed__c = logEntryEvent.LimitsFutureCallsUsed__c,
                LimitsHeapSizeMax__c = logEntryEvent.LimitsHeapSizeMax__c,
                LimitsHeapSizeUsed__c = logEntryEvent.LimitsHeapSizeUsed__c,
                LimitsMobilePushApexCallsMax__c = logEntryEvent.LimitsMobilePushApexCallsMax__c,
                LimitsMobilePushApexCallsUsed__c = logEntryEvent.LimitsMobilePushApexCallsUsed__c,
                LimitsQueueableJobsMax__c = logEntryEvent.LimitsQueueableJobsMax__c,
                LimitsQueueableJobsUsed__c = logEntryEvent.LimitsQueueableJobsUsed__c,
                LimitsSoqlQueriesMax__c = logEntryEvent.LimitsSoqlQueriesMax__c,
                LimitsSoqlQueriesUsed__c = logEntryEvent.LimitsSoqlQueriesUsed__c,
                LimitsSoqlQueryLocatorRowsMax__c = logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c,
                LimitsSoqlQueryLocatorRowsUsed__c = logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c,
                LimitsSoqlQueryRowsMax__c = logEntryEvent.LimitsSoqlQueryRowsMax__c,
                LimitsSoqlQueryRowsUsed__c = logEntryEvent.LimitsSoqlQueryRowsUsed__c,
                LimitsSoslSearchesMax__c = logEntryEvent.LimitsSoslSearchesMax__c,
                LimitsSoslSearchesUsed__c = logEntryEvent.LimitsSoslSearchesUsed__c,
                Log__c = TRANSACTION_ID_TO_LOG.get(logEntryEvent.TransactionId__c).Id,
                LoggingLevel__c = logEntryEvent.LoggingLevel__c,
                LoggingLevelOrdinal__c = logEntryEvent.LoggingLevelOrdinal__c,
                Message__c = logEntryEvent.Message__c,
                MessageTruncated__c = logEntryEvent.MessageTruncated__c,
                Name = null, // Salesforce will auto-set the record ID as the name when null
                OriginLocation__c = logEntryEvent.OriginLocation__c,
                OriginType__c = logEntryEvent.OriginType__c,
                RecordCollectionType__c = logEntryEvent.RecordCollectionType__c,
                RecordId__c = logEntryEvent.RecordId__c,
                RecordJson__c = logEntryEvent.RecordJson__c,
                RecordSObjectClassification__c = logEntryEvent.RecordSObjectClassification__c,
                RecordSObjectType__c = logEntryEvent.RecordSObjectType__c,
                RecordSObjectTypeNamespace__c = logEntryEvent.RecordSObjectTypeNamespace__c,
                StackTrace__c = logEntryEvent.StackTrace__c,
                Timestamp__c = timestamp,
                TriggerIsExecuting__c = logEntryEvent.TriggerIsExecuting__c,
                TriggerOperationType__c = logEntryEvent.TriggerOperationType__c,
                TriggerSObjectType__c = logEntryEvent.TriggerSObjectType__c
            );

            this.logEntries.add(logEntry);

        }

        insert this.logEntries;
        this.logEntryIdToLogEntry = new Map<Id, LogEntry__c>(this.logEntries);

        for (Integer i = 0; i < logEntryEvents.size(); i++) {
            LogEntryEvent__e logEntryEvent = logEntryEvents.get(i);

            if (logEntryEvent.Topics__c != null) {
                List<String> logEntryTopicNames = new List<String>();
                for (String topicName : logEntryEvent.Topics__c.split(TOPICS_DELIMITER)) {
                    logEntryTopicNames.add(topicName.trim());
                }

                this.topicNames.addAll(logEntryTopicNames);
                this.logEntryIdToTopics.put(this.logEntries.get(i).Id, new Set<String>(logEntryTopicNames));
            }
        }
    }

    private void appendCmdtTopics() {
        for (LogEntry__c logEntry : this.logEntries) {
            for (LogEntryTopicAssignment__mdt rule : TOPIC_ASSIGNMENT_RULES) {
                Boolean matches;
                switch on rule.FieldOperation__c {
                    when 'CONTAINS' {
                        matches = String.valueOf(logEntry.get(rule.LoggerField__r.QualifiedApiName)).contains(rule.FieldValue__c);
                    }
                    when 'EQUALS' {
                        matches = logEntry.get(rule.LoggerField__r.QualifiedApiName) == rule.FieldValue__c;
                    }
                    when 'STARTS_WITH' {
                        matches = String.valueOf(logEntry.get(rule.LoggerField__r.QualifiedApiName)).startsWith(rule.FieldValue__c);
                    }
                }

                if (matches == true) {
                    List<String> cmdtTopics = rule.Topics__c.split('\n');
                    this.topicNames.addAll(cmdtTopics);
                    Set<String> logEntryTopics = logEntryIdToTopics.get(logEntry.Id);
                    if (logEntryTopics == null) {
                        logEntryTopics = new Set<String>();
                    }
                    logEntryTopics.addAll(cmdtTopics);

                    this.logEntryIdToTopics.put(logEntry.Id, logEntryTopics);
                    this.topicNames.addAll(logEntryTopics);
                }
            }
        }
    }

    private void insertTopics() {
        System.debug('insertTopics startings');
        System.debug('this.topicNames ==' + this.topicNames);
        System.debug('this.logEntryIdToTopics ==' + this.logEntryIdToTopics);

        if (this.topicNames.isEmpty()) {
            return;
        }

        // Query for existing topics
        Map<String, Topic> topicNameToTopics = new Map<String, Topic>();
        for (Topic topic : [SELECT Id, Name FROM Topic WHERE Name IN :this.topicNames]) {
            topicNameToTopics.put(topic.Name, topic);
        }
        // Create any new topics
        List<Topic> topicsToCreate = new List<Topic>();
        for (String topicName : this.topicNames) {
            if (topicNameToTopics.get(topicName) != null) {
                continue;
            }

            topicsToCreate.add(new Topic(Name = topicName));
        }
        if (!topicsToCreate.isEmpty()) {
            Database.insert(topicsToCreate, false);
            for (Topic topic : topicsToCreate) {
                if (topic.Id != null) {
                    topicNameToTopics.put(topic.Name, topic);
                }
            }
        }
        // TODO cleanup/eliminate duplicate query
        for (Topic topic : [SELECT Id, Name FROM Topic WHERE Name IN :this.topicNames]) {
            topicNameToTopics.put(topic.Name, topic);
        }

        // Assign the topics to the records
        Set<TopicAssignment> topicAssignments = new Set<TopicAssignment>();
        for (Id logEntryId : logEntryIdToTopics.keySet()) {
            System.debug('logEntryIdToTopics.get(logEntry)==' + logEntryIdToTopics.get(logEntryId));
            Set<String> logEntryTopics = logEntryIdToTopics.get(logEntryId);

            if (logEntryTopics == null) {
                continue;
            }

            LogEntry__c logEntry = this.logEntryIdToLogEntry.get(logEntryId);

            for (String topicName : logEntryTopics) {
                Topic topic = topicNameToTopics.get(topicName);

                // TODO this guard clause shouldn't be necessary - remove?
                if (topic == null) {
                    continue;
                }

                // Add log entry-specific topics
                topicAssignments.add(new TopicAssignment(EntityId = logEntryId, TopicId = topic.Id));

                // Add all topics to the parent log when enabled
                topicAssignments.add(new TopicAssignment(EntityId = logEntry.Log__c, TopicId = topic.Id));
            }
        }
        insert new List<TopicAssignment>(topicAssignments);
    }

    // Private static methods
    private static List<LogEntryTopicAssignment__mdt> getTopicAssignmentRules() {
        return [
            SELECT Id, LoggerField__r.QualifiedApiName, FieldOperation__c, FieldValue__c, Topics__c
            FROM LogEntryTopicAssignment__mdt
            WHERE IsActive__c = TRUE AND LoggerObject__r.DeveloperName = 'LogEntry'
        ];
    }
    private static Log__c getRecentLogWithApiReleaseDetails() {
        // Query for recent logs created only today - the status API should be called...
        // ...at least once per day to make sure that status details are still accurate.
        // This query should make a callout approximately every 4 hours.
        Datetime fourHoursAgo = System.now().addMinutes(-4 * 60);

        List<Log__c> logs = [
            SELECT Id, ApiReleaseNumber__c, ApiReleaseVersion__c
            FROM Log__c
            WHERE CreatedDate >= :fourHoursAgo AND CreatedDate = TODAY AND ApiReleaseNumber__c != NULL
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (logs.isEmpty()) {
            return null;
        } else {
            return logs.get(0);
        }
    }

    private static Integer getCountOfOpenJobs() {
        return [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE
                ApexClass.Name = :LogEntryEventHandler.class.getName()
                AND MethodName = 'setStatusApiDetails'
                AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];
    }

    @future(callout=true)
    private static void setStatusApiDetails() {
        System.debug('Running setStatusApiDetails()');

        Organization organization = [SELECT InstanceName FROM Organization];
        String statusApiEndpoint = 'https://api.status.salesforce.com/v1/instances/' + organization.InstanceName + '/status';

        HttpRequest request = new HttpRequest();
        request.setEndpoint(statusApiEndpoint);
        request.setMethod('GET');

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() >= 400) {
            String errorMessage =
                'Callout failed for ' +
                statusApiEndpoint +
                '\nReceived request status code ' +
                response.getStatusCode() +
                ', status message: ' +
                response.getStatus();
            throw new StatusApiResponseException(errorMessage);
        }

        StatusApiResponse statusApiResponse = (StatusApiResponse) JSON.deserialize(response.getBody(), StatusApiResponse.class);
        System.debug('statusApiResponse==' + statusApiResponse);

        List<Log__c> logsToUpdate = new List<Log__c>();
        for (Log__c log : [
            SELECT Id
            FROM Log__c
            WHERE CreatedDate = TODAY AND ApiReleaseNumber__c = NULL
            ORDER BY CreatedDate
            LIMIT :Limits.getLimitDmlRows()
        ]) {
            log.ApiReleaseNumber__c = statusApiResponse.releaseNumber;
            log.ApiReleaseVersion__c = statusApiResponse.releaseVersion;

            logsToUpdate.add(log);
        }
        System.debug('logsToUpdate==' + logsToUpdate);
        update logsToUpdate;
    }

    // Private class for handling the response from api.status.salesforce.com
    @TestVisible
    private class StatusApiResponse {
        public String releaseNumber { get; set; }
        public String releaseVersion { get; set; }
    }

    @TestVisible
    private class StatusApiResponseException extends Exception {
    }
}
