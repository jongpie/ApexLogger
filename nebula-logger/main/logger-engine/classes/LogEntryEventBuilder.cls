//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group logger-engine
 * @description Builder class that generates each `LogEntryEvent__e` record
 * @see Logger
 */
global with sharing class LogEntryEventBuilder {
    private static final String API_VERSION = getApiVersion();
    private static final AuthSession AUTH_SESSION = getAuthSession();
    private static final List<String> IGNORED_CLASSES = getIgnoredClasses();
    private static final String NAMESPACE_PREFIX = getNamespacePrefix();
    private static final SObject NETWORK_SITE = getNetwork();
    private static final Organization ORGANIZATION = getOrganization();
    private static final String ORIGIN_TYPE_APEX = 'Apex';
    // TODO future enhancement: consider converting strings to enum and add overload for `parseStackTrace(OriginType, String)
    // private static final String ORIGIN_TYPE_COMPONENT = 'Component';
    // private static final String ORIGIN_TYPE_FLOW = 'Flow';
    private static final User USER = getUser();
    private static final Map<String, String> SOBJECT_NAME_TO_CLASSIFICATION = new Map<String, String>();
    private static final Map<String, String> SOBJECT_SUFFIX_TO_CLASSIFICATION = getSObjectSuffixToClassification();

    private final LogEntryEvent__e logEntryEvent;
    private final LoggingLevel loggingLevel;

    private Boolean detailsAreSet = false;
    private Boolean shouldSave;
    private List<String> topics = new List<String>();

    /**
     * @description Used by `Logger` to instantiate a new instance of `LogEntryEventBuilder`
     * @param  loggingLevel The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e`
     * @param  shouldSave   Determines if the builder's instance of `LogEntryEvent__e` should be saved
     * @return              The new instance of `LogEntryEventBuilder`
     */
    public LogEntryEventBuilder(LoggingLevel loggingLevel, Boolean shouldSave) {
        this.shouldSave = shouldSave;

        if (this.shouldSave == false) {
            return;
        }

        this.loggingLevel = loggingLevel;

        this.logEntryEvent = new LogEntryEvent__e(
            ApiVersion__c = API_VERSION,
            LimitsAggregateQueriesUsed__c = Limits.getAggregateQueries(),
            LimitsAsyncCallsUsed__c = Limits.getAsyncCalls(),
            LimitsCalloutsUsed__c = Limits.getCallouts(),
            LimitsCpuTimeUsed__c = Limits.getCpuTime(),
            LimitsDmlRowsUsed__c = Limits.getDmlRows(),
            LimitsDmlStatementsUsed__c = Limits.getDmlStatements(),
            LimitsEmailInvocationsUsed__c = Limits.getEmailInvocations(),
            LimitsFutureCallsUsed__c = Limits.getFutureCalls(),
            LimitsHeapSizeUsed__c = Limits.getHeapSize(),
            LimitsMobilePushApexCallsUsed__c = Limits.getMobilePushApexCalls(),
            LimitsQueueableJobsUsed__c = Limits.getQueueableJobs(),
            LimitsSoqlQueriesUsed__c = Limits.getQueries(),
            LimitsSoqlQueryLocatorRowsUsed__c = Limits.getQueryLocatorRows(),
            LimitsSoqlQueryRowsUsed__c = Limits.getQueryRows(),
            LimitsSoslSearchesUsed__c = Limits.getSoslQueries(),
            LoggingLevel__c = loggingLevel.NAME(),
            LoggingLevelOrdinal__c = loggingLevel.ORDINAL(),
            OriginType__c = ORIGIN_TYPE_APEX,
            Timestamp__c = System.now(),
            TriggerIsExecuting__c = Trigger.isExecuting,
            TriggerOperationType__c = Trigger.operationType == null ? null : Trigger.operationType.name(),
            TriggerSObjectType__c = Trigger.new == null ? null : String.valueOf(Trigger.new.getSObjectType())
        );

        // TODO add check to see if the class's namespace == the org's namespace
        //if (!hasNamespacePrefix()) {
        DmlException stackTraceException = new DmlException();
        this.parseStackTrace(stackTraceException.getStackTraceString());
        //}

        Database.DmlOptions dmlOptions = new Database.DmlOptions();
        dmlOptions.allowFieldTruncation = true;
        this.logEntryEvent.setOptions(dmlOptions);
    }

    /**
     * @description Sets the log entry event's message field
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setMessage(LogMessage logMessage) {
        if (this.shouldSave == false) {
            return this;
        }

        return this.setMessage(logMessage.getMessage());
    }

    /**
     * @description Sets the log entry event's message field
     * @param  message The string to use to set the entry's message field
     * @return         The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setMessage(String message) {
        if (this.shouldSave == false) {
            return this;
        }

        System.debug(this.loggingLevel, message);

        this.logEntryEvent.Message__c = message;

        return this;
    }

    /**
     * @description Sets the log entry event's exception fields
     * @param  apexException The instance of an `Exception` to use.
     * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setExceptionDetails(Exception apexException) {
        if (this.shouldSave == false) {
            return this;
        }

        this.logEntryEvent.ExceptionMessage__c = apexException.getMessage();
        this.logEntryEvent.ExceptionType__c = apexException.getTypeName();

        // Stack traces are not returned for managed packages
        if (isValidStackTrace(apexException.getStackTraceString())) {
            this.logEntryEvent.ExceptionStackTrace__c = apexException.getStackTraceString();
        }

        return this;
    }

    // DML-result builder methods. All* of the Result classes behave the same (*except Upsert)
    // ...but Salesforce didn't bother to use an interface for the classes, so instead - overloads!
    /**
     * @description Sets the log entry event's database operation result fields
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.DeleteResult deleteResult) {
        if (this.shouldSave == false || deleteResult == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = JSON.serializePretty(deleteResult);
        this.logEntryEvent.DatabaseResultType__c = Database.DeleteResult.class.getName();

        return this.setRecordId(deleteResult.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.MergeResult mergeResult) {
        if (this.shouldSave == false || mergeResult == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = JSON.serializePretty(mergeResult);
        this.logEntryEvent.DatabaseResultType__c = Database.MergeResult.class.getName();

        return this.setRecordId(mergeResult.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.SaveResult saveResult) {
        if (this.shouldSave == false || saveResult == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = JSON.serializePretty(saveResult);
        this.logEntryEvent.DatabaseResultType__c = Database.SaveResult.class.getName();

        return this.setRecordId(saveResult.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.UpsertResult upsertResult) {
        if (this.shouldSave == false || upsertResult == null) {
            return this;
        }

        // Upsert has 2 subtypes (surprise!) - insert and update - so, UpsertResult has an extra method to take into account
        String subtype = upsertResult.isCreated() ? 'Insert' : 'Update';

        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = JSON.serializePretty(upsertResult);
        this.logEntryEvent.DatabaseResultType__c = Database.UpsertResult.class.getName() + '.' + subtype;

        return this.setRecordId(upsertResult.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.UndeleteResult undeleteResult) {
        if (this.shouldSave == false || undeleteResult == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = JSON.serializePretty(undeleteResult);
        this.logEntryEvent.DatabaseResultType__c = Database.UndeleteResult.class.getName();

        return this.setRecordId(undeleteResult.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.DeleteResult> deleteResults) {
        if (this.shouldSave == false || deleteResults == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = JSON.serializePretty(deleteResults);
        this.logEntryEvent.DatabaseResultType__c = Database.DeleteResult.class.getName();

        return this;
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.MergeResult> mergeResults) {
        if (this.shouldSave == false || mergeResults == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = JSON.serializePretty(mergeResults);
        this.logEntryEvent.DatabaseResultType__c = Database.MergeResult.class.getName();

        return this;
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.SaveResult> saveResults) {
        if (this.shouldSave == false || saveResults == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = JSON.serializePretty(saveResults);
        this.logEntryEvent.DatabaseResultType__c = Database.SaveResult.class.getName();

        return this;
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.UpsertResult> upsertResults) {
        if (this.shouldSave == false || upsertResults == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = JSON.serializePretty(upsertResults);
        this.logEntryEvent.DatabaseResultType__c = Database.UpsertResult.class.getName();

        return this;
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.UndeleteResult> undeleteResults) {
        if (this.shouldSave == false || undeleteResults == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = JSON.serializePretty(undeleteResults);
        this.logEntryEvent.DatabaseResultType__c = Database.UndeleteResult.class.getName();

        return this;
    }

    /**
     * @description Deprecated - use `setRecord(Id recordId)` instead
     */
    // TODO before publishing managed package version, uncomment @Deprecated
    // @Deprecated
    global LogEntryEventBuilder setRecordId(Id recordId) {
        return this.setRecord(recordId);
    }

    /**
     * @description Deprecated - use `setRecord(SObject record)` instead
     */
    // TODO before publishing managed package version, uncomment @Deprecated
    // @Deprecated
    global LogEntryEventBuilder setRecordId(SObject record) {
        return this.setRecord(record);
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  recordId The ID of the SObject record related to the entry
     * @return          The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setRecord(Id recordId) {
        if (this.shouldSave == false || String.isBlank(recordId)) {
            return this;
        }

        this.logEntryEvent.RecordCollectionType__c = 'Single';
        this.logEntryEvent.RecordId__c = recordId;
        this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(recordId.getSObjectType());
        this.logEntryEvent.RecordSObjectType__c = recordId.getSObjectType().getDescribe().getName();
        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  record The `SObject` record related to the entry. The JSON of the record is automatically added to the entry
     * @return        The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setRecord(SObject record) {
        if (this.shouldSave == false || record == null) {
            return this;
        }

        this.logEntryEvent.RecordCollectionType__c = 'Single';
        this.logEntryEvent.RecordId__c = record.Id;
        this.logEntryEvent.RecordJson__c = JSON.serializePretty(record);
        this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(record.getSObjectType());
        this.logEntryEvent.RecordSObjectType__c = record.getSObjectType().getDescribe().getName();
        this.logEntryEvent.RecordSObjectTypeNamespace__c = getSObjectTypeNamespace(record.getSObjectType());

        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  records The list of `SObject` records related to the entry. The JSON of the list is automatically added to the entry
     * @return         The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setRecord(List<SObject> records) {
        if (this.shouldSave == false || records == null) {
            return this;
        }

        this.logEntryEvent.RecordCollectionType__c = 'List';
        this.logEntryEvent.RecordJson__c = JSON.serializePretty(records);
        this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(records.getSObjectType());
        this.logEntryEvent.RecordSObjectType__c = records.getSObjectType().getDescribe().getName();
        this.logEntryEvent.RecordSObjectTypeNamespace__c = getSObjectTypeNamespace(records.getSObjectType());

        return this;
    }

    /**
     * @description Appends the topic to the existing list of topics
     * @param  topics The string to use as a topic for the current entry
     * @return        The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public LogEntryEventBuilder addTopic(String topic) {
        if (this.shouldSave == false || String.isBlank(topic)) {
            return this;
        }

        this.topics.add(topic);
        return this;
    }

    /**
     * @description Sets a comma-separate list of strings on the LogEntryEvent__e, which ultimately becomes Topic & TopicAssignment records on Log__c and LogEntry__c
     * @param  topics The list of strings to use as topics for the current entry
     * @return        The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public LogEntryEventBuilder setTopics(List<String> topics) {
        if (this.shouldSave == false) {
            return this;
        }

        this.topics = new List<String>(topics);
        return this;
    }

    /**
     * @description Parses the provided stack trace and sets the log entry's origin & stack trace fields
     * @param  stackTraceString The Apex stack trace string to parse
     * @return                  The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder parseStackTrace(String stackTraceString) {
        if (this.shouldSave == false) {
            return this;
        }

        // Stack traces are not returned for managed packages
        if (!isValidStackTrace(stackTraceString)) {
            return this;
        }

        List<String> stackTraceLines = new List<String>();
        for (String currentStackTraceLine : stackTraceString.split('\n')) {
            // Don't include the logging system's classes in the stack trace

            Boolean ignoreLine = false;
            for (String ignoredClass : IGNORED_CLASSES) {
                if (currentStackTraceLine.contains('.' + ignoredClass + '.')) {
                    ignoreLine = true;
                    continue;
                }
            }

            if (ignoreLine) {
                continue;
            }

            stackTraceLines.add(currentStackTraceLine);
        }

        // In a managed package, we can end up with an invalid (unhelpful) stack trace, so only store when valid
        stackTraceString = String.join(stackTraceLines, '\n');
        if (isValidStackTrace(stackTraceString)) {
            String originLocation = stackTraceLines.get(0);
            if (originLocation.contains(':')) {
                originLocation = originLocation.substringBefore(':');
            }
            if (originLocation.startsWith('Class.')) {
                originLocation = originLocation.substringAfter('Class.');
            }

            this.logEntryEvent.OriginLocation__c = originLocation;
            this.logEntryEvent.StackTrace__c = stackTraceString;
        }

        return this;
    }

    /**
     * @description Determines if this instance of `LogEntryEventBuilder` should be saved the next time that `Logger.saveLog()` is called
     * @return   Boolean
     */
    public Boolean shouldSave() {
        return this.shouldSave;
    }

    /**
     * @description Returns the `LogEntryEvent__e` record for this instance of LogEntryEventBuilder
     * @return   The `LogEntryEvent__e` record
     */
    public LogEntryEvent__e getLogEntryEvent() {
        if (this.shouldSave == false) {
            return null;
        }

        // Lazy-loading of some details to help minimize Apex heap size usage until needed
        if (this.detailsAreSet == false) {
            this.setOrganizationDetails();
            this.setNetworkDetails();
            this.setUserDetails();
            this.setUserSessionDetails();

            this.detailsAreSet = true;
        }

        this.logEntryEvent.Topics__c = getTopicsString(topics);

        // Salesforce does not provide precise datetimes in Apex triggers for platform events
        // Set the string value of timestamp to a second field as a workaround
        // See https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_api_considerations.htm
        if (this.logEntryEvent.Timestamp__c != null) {
            this.logEntryEvent.TimestampString__c = String.valueOf(this.logEntryEvent.Timestamp__c);
        }

        return this.logEntryEvent;
    }

    private void setOrganizationDetails() {
        if (this.shouldSave == false) {
            return;
        }

        String orgEnvironmentType;
        if (ORGANIZATION.IsSandbox == true && ORGANIZATION.TrialExpirationDate != null) {
            orgEnvironmentType = 'Scratch Org';
        } else if (ORGANIZATION.IsSandbox == true) {
            orgEnvironmentType = 'Sandbox';
        } else {
            orgEnvironmentType = 'Production';
        }

        this.logEntryEvent.OrganizationDomainUrl__c = Url.getOrgDomainUrl()?.toExternalForm();
        this.logEntryEvent.OrganizationEnvironmentType__c = orgEnvironmentType;
        this.logEntryEvent.OrganizationId__c = ORGANIZATION.Id;
        this.logEntryEvent.OrganizationInstanceName__c = ORGANIZATION.InstanceName;
        this.logEntryEvent.OrganizationName__c = ORGANIZATION.Name;
        this.logEntryEvent.OrganizationNamespacePrefix__c = ORGANIZATION.NamespacePrefix;
        this.logEntryEvent.OrganizationType__c = ORGANIZATION.OrganizationType;
    }

    private void setNetworkDetails() {
        if (this.shouldSave == false) {
            return;
        }

        if (NETWORK_SITE == null) {
            return;
        }

        this.logEntryEvent.NetworkName__c = (String) NETWORK_SITE.get('Name');
        this.logEntryEvent.NetworkLoginUrl__c = Network.getLoginUrl(NETWORK_SITE.ID);
        this.logEntryEvent.NetworkLogoutUrl__c = Network.getLogoutUrl(NETWORK_SITE.ID);
        this.logEntryEvent.NetworkSelfRegistrationUrl__c = Network.getSelfRegUrl(NETWORK_SITE.ID);
        this.logEntryEvent.NetworkUrlPathPrefix__c = (String) NETWORK_SITE.get('UrlPathPrefix');
    }

    private void setUserDetails() {
        if (this.shouldSave == false) {
            return;
        }

        this.logEntryEvent.LoggedByUsername__c = USER.Username;
        this.logEntryEvent.ProfileName__c = USER.Profile.Name;
        this.logEntryEvent.UserLicenseDefinitionKey__c = USER.Profile.UserLicense.LicenseDefinitionKey;
        this.logEntryEvent.UserLicenseId__c = USER.Profile.UserLicenseId;
        this.logEntryEvent.UserLicenseName__c = USER.Profile.UserLicense.Name;
        this.logEntryEvent.UserRoleName__c = USER.UserRole?.Name;
    }

    private String getSObjectClassification(Schema.SObjectType sobjectType) {
        if (sobjectType == null) {
            return null;
        }

        String sobjectName = sobjectType.getDescribe().getName();

        // Check the map to see if we've already determined the classification for this SObject type
        if (SOBJECT_NAME_TO_CLASSIFICATION.containsKey(sobjectName)) {
            return SOBJECT_NAME_TO_CLASSIFICATION.get(sobjectName);
        }

        String sobjectClassification;

        // Custom settings and custom objects both end in '__c', so explicitly check if it's a custom setting
        if (sobjectType.getDescribe().isCustomSetting()) {
            sobjectClassification = 'Custom Setting Object';
        }

        for (String sobjectSuffix : SOBJECT_SUFFIX_TO_CLASSIFICATION.keySet()) {
            if (String.isBlank(sobjectClassification) && sobjectName.endsWith(sobjectSuffix)) {
                sobjectClassification = SOBJECT_SUFFIX_TO_CLASSIFICATION.get(sobjectSuffix);
                break;
            }
        }

        // Finally, if we still don't have a classification, assume it's a standard object
        if (String.isBlank(sobjectClassification) && sobjectType.getDescribe().isCustom() == false) {
            sobjectClassification = 'Standard Object';
        }

        // Cache the results in case there are other entries related to the same SObject Type
        SOBJECT_NAME_TO_CLASSIFICATION.put(sobjectName, sobjectClassification);

        return sobjectClassification;
    }

    private String getSObjectTypeNamespace(Schema.SObjectType sobjectType) {
        if (sobjectType == null) {
            return null;
        }

        String sobjectFullName = sobjectType.getDescribe().getName();
        String sobjectLocalName = sobjectType.getDescribe().getLocalName();

        // Remove the trailing '__' if present
        String namespace = sobjectFullName.replace(sobjectLocalName, '').replace('__', '');
        if (String.isBlank(namespace)) {
            namespace = null;
        }
        return namespace;
    }

    private void setUserSessionDetails() {
        if (this.shouldSave == false) {
            return;
        }

        LoggingLevel userLoggingLevel = Logger.getLoggingLevel(LoggerSettings__c.getInstance().LoggingLevel__c);

        this.logEntryEvent.LimitsAggregateQueriesMax__c = Limits.getLimitAggregateQueries();
        this.logEntryEvent.LimitsAsyncCallsMax__c = Limits.getLimitAsyncCalls();
        this.logEntryEvent.LimitsCalloutsMax__c = Limits.getLimitCallouts();
        this.logEntryEvent.LimitsCpuTimeMax__c = Limits.getLimitCpuTime();
        this.logEntryEvent.LimitsDmlRowsMax__c = Limits.getLimitDmlRows();
        this.logEntryEvent.LimitsDmlStatementsMax__c = Limits.getLimitDmlStatements();
        this.logEntryEvent.LimitsEmailInvocationsMax__c = Limits.getLimitEmailInvocations();
        this.logEntryEvent.LimitsFutureCallsMax__c = Limits.getLimitFutureCalls();
        this.logEntryEvent.LimitsHeapSizeMax__c = Limits.getLimitHeapSize();
        this.logEntryEvent.LimitsMobilePushApexCallsMax__c = Limits.getLimitMobilePushApexCalls();
        this.logEntryEvent.LimitsQueueableJobsMax__c = Limits.getLimitQueueableJobs();
        this.logEntryEvent.LimitsSoqlQueriesMax__c = Limits.getLimitQueries();
        this.logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c = Limits.getLimitQueryLocatorRows();
        this.logEntryEvent.LimitsSoqlQueryRowsMax__c = Limits.getLimitQueryRows();
        this.logEntryEvent.LimitsSoslSearchesMax__c = Limits.getLimitSoslQueries();
        this.logEntryEvent.Locale__c = UserInfo.getLocale();
        this.logEntryEvent.NetworkId__c = Network.getNetworkId();
        this.logEntryEvent.LoginHistoryId__c = AUTH_SESSION?.LoginHistoryId;
        this.logEntryEvent.LoginApplication__c = AUTH_SESSION?.LoginHistory.Application;
        this.logEntryEvent.LoginBrowser__c = AUTH_SESSION?.LoginHistory.Browser;
        this.logEntryEvent.LoginPlatform__c = AUTH_SESSION?.LoginHistory.Platform;
        this.logEntryEvent.LoginType__c = AUTH_SESSION?.LoginType;
        this.logEntryEvent.LogoutUrl__c = AUTH_SESSION?.LogoutUrl;
        this.logEntryEvent.ProfileId__c = UserInfo.getProfileId();
        this.logEntryEvent.SessionId__c = AUTH_SESSION?.Id;
        this.logEntryEvent.SessionSecurityLevel__c = AUTH_SESSION?.SessionSecurityLevel;
        this.logEntryEvent.SessionType__c = AUTH_SESSION?.SessionType;
        this.logEntryEvent.SourceIp__c = AUTH_SESSION?.SourceIp;
        this.logEntryEvent.TimeZoneId__c = UserInfo.getTimeZone().getId();
        this.logEntryEvent.TimeZoneName__c = UserInfo.getTimeZone().getDisplayName();
        this.logEntryEvent.UserLoggingLevel__c = userLoggingLevel.name();
        this.logEntryEvent.UserLoggingLevelOrdinal__c = userLoggingLevel.ordinal();
        this.logEntryEvent.UserRoleId__c = UserInfo.getUserRoleId();
        this.logEntryEvent.UserType__c = UserInfo.getUserType();

        if (this.logEntryEvent.SessionType__c != 'Oauth2') {
            this.logEntryEvent.ThemeDisplayed__c = UserInfo.getUiThemeDisplayed();
        }
    }

    // Private static methods
    private static AuthSession getAuthSession() {
        if (String.isBlank(UserInfo.getSessionId())) {
            return null;
        }

        // Scheduled jobs, batch jobs, invocables, future methods and queueables are ALL
        // run by the Automated Process user - attempting to access Auth.SessionManagement
        // methods as that user throws an UNCATCHABLE error. Let's sidestep that by querying AuthSession instead.

        List<AuthSession> sessions = [
            SELECT
                Id,
                LoginType,
                LoginHistoryId,
                LoginHistory.Application,
                LoginHistory.Browser,
                LoginHistory.Platform,
                LogoutUrl,
                SessionSecurityLevel,
                SessionType,
                SourceIp
            FROM AuthSession
            WHERE UsersId = :UserInfo.getUserId() AND IsCurrent = TRUE AND ParentId = NULL
        ];

        if (sessions.isEmpty()) {
            return null;
        } else {
            return sessions.get(0);
        }
    }

    private static String getApiVersion() {
        // Small hack to determine the org's current API version (since Apex doesn't natively provide it)
        // Serializing any SObject w/ an ID will include the API version
        // So, use UserInfo.getUserId() to create the current user's record without querying
        // Then parse the JSON to get the API version
        // Expected JSON: {"attributes":{"type":"User","url":"/services/data/v51.0/sobjects/User/005J000000AugnYIAR"}
        String userJson = JSON.serialize(new User(Id = UserInfo.getUserId()));
        return userJson.substringAfter('/data/').substringBefore('/sobjects/User');
    }

    private static List<String> getIgnoredClasses() {
        return new List<String>{ Logger.class.getName(), LogMessage.class.getName(), LogEntryEventBuilder.class.getName() };
    }

    // TODO move namespace methods to separate Namespace class (again) if other classes end up needing this info
    /* private static Boolean hasNamespacePrefix() {
        return String.isNotBlank(NAMESPACE_PREFIX);
    } */

    private static String getNamespacePrefix() {
        String className = LogEntryEventBuilder.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
    }

    private static Map<String, String> getSObjectSuffixToClassification() {
        return new Map<String, String>{
            // Example: MyBigObject__b
            '__b' => 'Big Object',
            // Example: Log__c
            '__c' => 'Custom Object',
            // Example: LogEntryEvent__e
            '__e' => 'Platform Event Object',
            // Example: LogStatus__mdt
            '__mdt' => 'Custom Metadata Type Object',
            // Examples: AccountChangeEvent and Log__ChangeEvent
            'ChangeEvent' => 'Change Event Object',
            // Examples: AccountFeed and Log__Feed
            'Feed' => 'Chatter Feed Object',
            // Examples: AccountHistory and Log__History
            'History' => 'Field History Tracking Object',
            // Examples: AccountShare and Log__Share
            'Share' => 'Record Share Object'
        };
    }

    // private static String getPrefixWithDelimiter(String delimiter) {
    //     return String.isBlank(getPrefix()) ? '' : getPrefix() + delimiter;
    // }

    private static Organization getOrganization() {
        return [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
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

    // TODO need to revisit Visualforce logic, re-add fields to either Log__c or LogEntry__c, etc.
    /* private static String getVisualforcePageName() {
        String visualforcePageName = ApexPages.currentPage() == null ? null : ApexPages.currentPage().getUrl();
        if (visualforcePageName != null && visualforcePageName.contains('?')) {
            visualforcePageName = visualforcePageName.substringBetween('apex/', '?');
        } else if (visualforcePageName != null) {
            visualforcePageName = visualforcePageName.substringAfter('apex/');
        }

        return visualforcePageName;
    } */

    private static Boolean isValidStackTrace(String stackTraceString) {
        if (String.isEmpty(stackTraceString)) {
            return false;
        }
        if (stackTraceString == '()') {
            return false;
        }
        if (stackTraceString == '(' + getNamespacePrefix() + ')') {
            return false;
        }

        return true;
    }

    private static String getTopicsString(List<String> topics) {
        if (topics == null || topics.isEmpty()) {
            return null;
        }

        // De-duplicate the list of topics
        // TODO remove (help reduce CPU usage)
        // topics = new List<String>(new Set<String>(topics));

        return String.join(topics, '\n');
    }
}
