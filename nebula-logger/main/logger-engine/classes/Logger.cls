//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group logger-engine
 * @description The core class for logging
 * @see LogEntryEventBuilder
 * @see LogMessage
 */
global with sharing class Logger {
    private static final LoggingLevel DEFAULT_LOGGING_LEVEL = LoggingLevel.DEBUG;
    private static final List<LogEntryEventBuilder> LOG_ENTRIES_BUFFER = new List<LogEntryEventBuilder>();
    private static final Boolean SYSTEM_MESSAGES_ENABLED = LoggerSettings__c.getInstance().EnableSystemMessages__c;
    private static final String TRANSACTION_ID = System.Request.getCurrent().getRequestId();
    private static final Quiddity TRANSACTION_QUIDDITY = System.Request.getCurrent().getQuiddity();
    private static final Boolean USER_CAN_CREATE_LOG_ENTRY_EVENTS = SObjectType.LogEntryEvent__e.isCreateable();
    private static final Boolean USER_HAS_LOGGING_ENABLED = LoggerSettings__c.getInstance().IsEnabled__c;
    private static final LoggingLevel USER_LOGGING_LEVEL = getLoggingLevel(LoggerSettings__c.getInstance().LoggingLevel__c);

    private static Integer currentTransactionEntryNumber = 1;
    private static String parentLogTransactionId;
    private static Boolean suspendSaving = false;
    @testVisible
    private static SaveMethod transactionSaveMethod = getDefaultSaveMethod();

    static {
        System.debug(LoggingLevel.INFO, 'Logger.getTransactionId() == ' + getTransactionId());

        // If settings have not been configured, then insert the org defaults
        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        if (orgDefaults.Id == null) {
            insert orgDefaults;
        }
    }

    /**
     * @description Enum used to control how LogEntryEvent__e records are inserted
     */
    global enum SaveMethod {
        EVENT_BUS,
        QUEUEABLE,
        REST
    }

    // Settings management methods

    /**
     * @description Returns the unique ID for a particular transaction, stored in Log__c.TransactionId__c
     * @return String - The value of System.Request.getCurrent().getRequestId()
     */
    global static String getTransactionId() {
        return TRANSACTION_ID;
    }

    /**
     * @description Returns the Quiddity context of the current transaction.
     * @return Quiddity - The value of System.Request.getCurrent().getQuiddity()
     */
    global static Quiddity getCurrentQuiddity() {
        return TRANSACTION_QUIDDITY;
    }

    /**
     * @description Relates the current transaction's log to a parent log via the field Log__c.ParentLog__c
     *   This is useful for relating multiple asynchronous operations together, such as batch & queueable jobs.
     * @param  parentTransactionId - The transaction ID of the original parent transaction
     */
    global static void setParentLogTransactionId(String parentTransactionId) {
        parentLogTransactionId = parentTransactionId;
    }

    /**
     * @description Returns the transaction ID value that will be used to relate the current transaction's log to a parent log
     * @return String - The parent log's transaction ID. This must be explicitly set by calling setParentLogTransactionId(String)
     */
    global static String getParentLogTransactionId() {
        return parentLogTransactionId;
    }

    /**
     * @description Indicates if logging has been enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isEnabled() {
        return USER_HAS_LOGGING_ENABLED;
    }

    /**
     * @description Indicates if logging for the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
     * @param  loggingLevel - The logging level to check
     * @return Boolean
     */
    global static Boolean isEnabled(LoggingLevel loggingLevel) {
        return isEnabled() && meetsUserLoggingLevel(loggingLevel);
    }

    /**
     * @description Indicates if logging level 'ERROR' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isErrorEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.ERROR);
    }

    /**
     * @description Indicates if logging level 'WARN' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isWarnEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.WARN);
    }

    /**
     * @description Indicates if logging level 'INFO' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isInfoEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.INFO);
    }

    /**
     * @description Indicates if logging level 'DEBUG' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isDebugEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.DEBUG);
    }

    /**
     * @description Indicates if logging level 'FINE' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFineEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINE);
    }

    /**
     * @description Indicates if logging level 'FINER' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFinerEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINER);
    }

    /**
     * @description Indicates if logging level 'FINEST' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFinestEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINEST);
    }

    /**
     * @description Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean meetsUserLoggingLevel(LoggingLevel logEntryLoggingLevel) {
        return USER_LOGGING_LEVEL.ordinal() <= logEntryLoggingLevel.ordinal();
    }

    /**
     * @description Returns the logging level for the current user, based on the custom setting LoggerSettings__c
     * @return LoggingLevel - The matching instance of LoggingLevel
     */
    global static LoggingLevel getUserLoggingLevel() {
        return USER_LOGGING_LEVEL;
    }

    // Transaction control methods

    /**
     * @description Indicates if saving has been temporarily suspended for the current transaction
     * @return Boolean
     */
    global static Boolean isSavingSuspended() {
        return suspendSaving;
    }

    /**
     * @description Pauses saving for the current transaction.
     *   Any calls to saveLog() are ignored until saving is resumed.
     */
    global static void suspendSaving() {
        suspendSaving = true;
    }

    /**
     * @description Resumes saving for the current transaction, used to reverse suspendSaving().
     *   Any calls to saveLog() are ignored until saving is resumed.
     */
    global static void resumeSaving() {
        suspendSaving = false;
    }

    /**
     * @description Returns the number of entries that have been generated but not yet saved
     * @return Integer
     */
    global static Integer getBufferSize() {
        return LOG_ENTRIES_BUFFER.size();
    }

    /**
     * @description Discards any entries that have been generated but not yet saved
     */
    global static void flushBuffer() {
        LOG_ENTRIES_BUFFER.clear();
    }

    // ERROR logging level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return error().setMessage(logMessage).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return error().setMessage(logMessage).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return error().setMessage(logMessage).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.MergeResult mergeResult) {
        return error().setMessage(logMessage).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return error().setMessage(logMessage).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.SaveResult saveResult) {
        return error().setMessage(logMessage).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return error().setMessage(logMessage).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return error().setMessage(logMessage).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return error().setMessage(logMessage).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return error().setMessage(logMessage).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return error().setMessage(logMessage).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return error().setMessage(logMessage).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, List<Database.MergeResult> mergeResults, List<String> topics) {
        return error().setMessage(logMessage).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return error().setMessage(logMessage).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, List<Database.SaveResult> saveResults, List<String> topics) {
        return error().setMessage(logMessage).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return error().setMessage(logMessage).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return error().setMessage(logMessage).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return error().setMessage(logMessage).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return error().setMessage(logMessage).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return error().setMessage(logMessage).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Exception apexException) {
        return error().setMessage(logMessage).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, Exception apexException) {
        return error().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId) {
        return error().setMessage(logMessage).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, List<String> topics) {
        return error().setMessage(logMessage).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, SObject record, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(record).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record, Exception apexException) {
        return error().setMessage(logMessage).setRecordId(record).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, SObject record, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record) {
        return error().setMessage(logMessage).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setRecord(records).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records, Exception apexException) {
        return error().setMessage(logMessage).setRecord(records).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records, List<String> topics) {
        return error().setMessage(logMessage).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records) {
        return error().setMessage(logMessage).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage) {
        return error().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return error().setMessage(message).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.DeleteResult deleteResult) {
        return error().setMessage(message).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, Database.MergeResult mergeResult, List<String> topics) {
        return error().setMessage(message).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.MergeResult mergeResult) {
        return error().setMessage(message).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, Database.SaveResult saveResult, List<String> topics) {
        return error().setMessage(message).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.SaveResult saveResult) {
        return error().setMessage(message).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return error().setMessage(message).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.UndeleteResult undeleteResult) {
        return error().setMessage(message).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return error().setMessage(message).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.UpsertResult upsertResult) {
        return error().setMessage(message).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return error().setMessage(message).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.DeleteResult> deleteResults) {
        return error().setMessage(message).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, List<Database.MergeResult> mergeResults, List<String> topics) {
        return error().setMessage(message).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.MergeResult> mergeResults) {
        return error().setMessage(message).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, List<Database.SaveResult> saveResults, List<String> topics) {
        return error().setMessage(message).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.SaveResult> saveResults) {
        return error().setMessage(message).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return error().setMessage(message).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.UndeleteResult> undeleteResults) {
        return error().setMessage(message).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return error().setMessage(message).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.UpsertResult> upsertResults) {
        return error().setMessage(message).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, Exception apexException, List<String> topics) {
        return error().setMessage(message).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Exception apexException) {
        return error().setMessage(message).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, Id recordId, Exception apexException, List<String> topics) {
        return error().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Id recordId, Exception apexException) {
        return error().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @param  topics   The instance of `List<String>` to use as topics for the current entry
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, Id recordId, List<String> topics) {
        return error().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Id recordId) {
        return error().setMessage(message).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, List<String> topics) {
        return error().setMessage(message).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, SObject record, Exception apexException, List<String> topics) {
        return error().setMessage(message).setRecordId(record).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, SObject record, Exception apexException) {
        return error().setMessage(message).setRecordId(record).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, SObject record, List<String> topics) {
        return error().setMessage(message).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, SObject record) {
        return error().setMessage(message).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, List<SObject> records, Exception apexException, List<String> topics) {
        return error().setMessage(message).setRecord(records).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<SObject> records, Exception apexException) {
        return error().setMessage(message).setRecord(records).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder error(String message, List<SObject> records, List<String> topics) {
        return error().setMessage(message).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<SObject> records) {
        return error().setMessage(message).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message) {
        return error().setMessage(message);
    }

    // WARN logging level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return warn().setMessage(logMessage).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return warn().setMessage(logMessage).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return warn().setMessage(logMessage).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.MergeResult mergeResult) {
        return warn().setMessage(logMessage).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return warn().setMessage(logMessage).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.SaveResult saveResult) {
        return warn().setMessage(logMessage).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return warn().setMessage(logMessage).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return warn().setMessage(logMessage).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return warn().setMessage(logMessage).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return warn().setMessage(logMessage).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return warn().setMessage(logMessage).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return warn().setMessage(logMessage).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.MergeResult> mergeResults, List<String> topics) {
        return warn().setMessage(logMessage).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return warn().setMessage(logMessage).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.SaveResult> saveResults, List<String> topics) {
        return warn().setMessage(logMessage).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return warn().setMessage(logMessage).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return warn().setMessage(logMessage).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return warn().setMessage(logMessage).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return warn().setMessage(logMessage).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return warn().setMessage(logMessage).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, Exception apexException, List<String> topics) {
        return warn().setMessage(logMessage).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Exception apexException) {
        return warn().setMessage(logMessage).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, Exception apexException, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, Exception apexException) {
        return warn().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId) {
        return warn().setMessage(logMessage).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, List<String> topics) {
        return warn().setMessage(logMessage).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, SObject record, Exception apexException, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(record).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record, Exception apexException) {
        return warn().setMessage(logMessage).setRecordId(record).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, SObject record, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record) {
        return warn().setMessage(logMessage).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records, Exception apexException, List<String> topics) {
        return warn().setMessage(logMessage).setRecord(records).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records, Exception apexException) {
        return warn().setMessage(logMessage).setRecord(records).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records, List<String> topics) {
        return warn().setMessage(logMessage).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records) {
        return warn().setMessage(logMessage).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage) {
        return warn().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return warn().setMessage(message).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.DeleteResult deleteResult) {
        return warn().setMessage(message).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, Database.MergeResult mergeResult, List<String> topics) {
        return warn().setMessage(message).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.MergeResult mergeResult) {
        return warn().setMessage(message).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, Database.SaveResult saveResult, List<String> topics) {
        return warn().setMessage(message).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.SaveResult saveResult) {
        return warn().setMessage(message).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return warn().setMessage(message).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.UndeleteResult undeleteResult) {
        return warn().setMessage(message).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return warn().setMessage(message).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.UpsertResult upsertResult) {
        return warn().setMessage(message).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return warn().setMessage(message).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.DeleteResult> deleteResults) {
        return warn().setMessage(message).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, List<Database.MergeResult> mergeResults, List<String> topics) {
        return warn().setMessage(message).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.MergeResult> mergeResults) {
        return warn().setMessage(message).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, List<Database.SaveResult> saveResults, List<String> topics) {
        return warn().setMessage(message).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.SaveResult> saveResults) {
        return warn().setMessage(message).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return warn().setMessage(message).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.UndeleteResult> undeleteResults) {
        return warn().setMessage(message).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return warn().setMessage(message).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.UpsertResult> upsertResults) {
        return warn().setMessage(message).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, Exception apexException, List<String> topics) {
        return warn().setMessage(message).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Exception apexException) {
        return warn().setMessage(message).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, Id recordId, Exception apexException, List<String> topics) {
        return warn().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Id recordId, Exception apexException) {
        return warn().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @param  topics   The instance of `List<String>` to use as topics for the current entry
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, Id recordId, List<String> topics) {
        return warn().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Id recordId) {
        return warn().setMessage(message).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, List<String> topics) {
        return warn().setMessage(message).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, SObject record, Exception apexException, List<String> topics) {
        return warn().setMessage(message).setRecordId(record).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, SObject record, Exception apexException) {
        return warn().setMessage(message).setRecordId(record).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, SObject record, List<String> topics) {
        return warn().setMessage(message).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, SObject record) {
        return warn().setMessage(message).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, List<SObject> records, Exception apexException, List<String> topics) {
        return warn().setMessage(message).setRecord(records).setExceptionDetails(apexException).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<SObject> records, Exception apexException) {
        return warn().setMessage(message).setRecord(records).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder warn(String message, List<SObject> records, List<String> topics) {
        return warn().setMessage(message).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<SObject> records) {
        return warn().setMessage(message).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message) {
        return warn().setMessage(message);
    }

    // INFO logging level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return info().setMessage(logMessage).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return info().setMessage(logMessage).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return info().setMessage(logMessage).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.MergeResult mergeResult) {
        return info().setMessage(logMessage).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return info().setMessage(logMessage).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.SaveResult saveResult) {
        return info().setMessage(logMessage).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return info().setMessage(logMessage).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return info().setMessage(logMessage).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return info().setMessage(logMessage).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return info().setMessage(logMessage).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return info().setMessage(logMessage).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return info().setMessage(logMessage).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, List<Database.MergeResult> mergeResults, List<String> topics) {
        return info().setMessage(logMessage).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return info().setMessage(logMessage).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, List<Database.SaveResult> saveResults, List<String> topics) {
        return info().setMessage(logMessage).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return info().setMessage(logMessage).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return info().setMessage(logMessage).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return info().setMessage(logMessage).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return info().setMessage(logMessage).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return info().setMessage(logMessage).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, Id recordId, List<String> topics) {
        return info().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Id recordId) {
        return info().setMessage(logMessage).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, List<String> topics) {
        return info().setMessage(logMessage).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, SObject record, List<String> topics) {
        return info().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, SObject record) {
        return info().setMessage(logMessage).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(LogMessage logMessage, List<SObject> records, List<String> topics) {
        return info().setMessage(logMessage).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<SObject> records) {
        return info().setMessage(logMessage).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage) {
        return info().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return info().setMessage(message).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.DeleteResult deleteResult) {
        return info().setMessage(message).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, Database.MergeResult mergeResult, List<String> topics) {
        return info().setMessage(message).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.MergeResult mergeResult) {
        return info().setMessage(message).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, Database.SaveResult saveResult, List<String> topics) {
        return info().setMessage(message).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.SaveResult saveResult) {
        return info().setMessage(message).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return info().setMessage(message).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.UndeleteResult undeleteResult) {
        return info().setMessage(message).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return info().setMessage(message).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.UpsertResult upsertResult) {
        return info().setMessage(message).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return info().setMessage(message).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.DeleteResult> deleteResults) {
        return info().setMessage(message).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, List<Database.MergeResult> mergeResults, List<String> topics) {
        return info().setMessage(message).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.MergeResult> mergeResults) {
        return info().setMessage(message).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, List<Database.SaveResult> saveResults, List<String> topics) {
        return info().setMessage(message).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.SaveResult> saveResults) {
        return info().setMessage(message).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return info().setMessage(message).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.UndeleteResult> undeleteResults) {
        return info().setMessage(message).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return info().setMessage(message).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.UpsertResult> upsertResults) {
        return info().setMessage(message).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @param  topics   The instance of `List<String>` to use as topics for the current entry
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, Id recordId, List<String> topics) {
        return info().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Id recordId) {
        return info().setMessage(message).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, List<String> topics) {
        return info().setMessage(message).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, SObject record, List<String> topics) {
        return info().setMessage(message).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, SObject record) {
        return info().setMessage(message).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder info(String message, List<SObject> records, List<String> topics) {
        return info().setMessage(message).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<SObject> records) {
        return info().setMessage(message).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message) {
        return info().setMessage(message);
    }

    // DEBUG log level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return debug().setMessage(logMessage).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return debug().setMessage(logMessage).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return debug().setMessage(logMessage).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.MergeResult mergeResult) {
        return debug().setMessage(logMessage).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return debug().setMessage(logMessage).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.SaveResult saveResult) {
        return debug().setMessage(logMessage).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return debug().setMessage(logMessage).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return debug().setMessage(logMessage).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return debug().setMessage(logMessage).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return debug().setMessage(logMessage).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return debug().setMessage(logMessage).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return debug().setMessage(logMessage).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.MergeResult> mergeResults, List<String> topics) {
        return debug().setMessage(logMessage).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return debug().setMessage(logMessage).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.SaveResult> saveResults, List<String> topics) {
        return debug().setMessage(logMessage).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return debug().setMessage(logMessage).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return debug().setMessage(logMessage).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return debug().setMessage(logMessage).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return debug().setMessage(logMessage).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return debug().setMessage(logMessage).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, Id recordId, List<String> topics) {
        return debug().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Id recordId) {
        return debug().setMessage(logMessage).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, List<String> topics) {
        return debug().setMessage(logMessage).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, SObject record, List<String> topics) {
        return debug().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, SObject record) {
        return debug().setMessage(logMessage).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(LogMessage logMessage, List<SObject> records, List<String> topics) {
        return debug().setMessage(logMessage).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<SObject> records) {
        return debug().setMessage(logMessage).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage) {
        return debug().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return debug().setMessage(message).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.DeleteResult deleteResult) {
        return debug().setMessage(message).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, Database.MergeResult mergeResult, List<String> topics) {
        return debug().setMessage(message).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.MergeResult mergeResult) {
        return debug().setMessage(message).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, Database.SaveResult saveResult, List<String> topics) {
        return debug().setMessage(message).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.SaveResult saveResult) {
        return debug().setMessage(message).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return debug().setMessage(message).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.UndeleteResult undeleteResult) {
        return debug().setMessage(message).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return debug().setMessage(message).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.UpsertResult upsertResult) {
        return debug().setMessage(message).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return debug().setMessage(message).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.DeleteResult> deleteResults) {
        return debug().setMessage(message).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, List<Database.MergeResult> mergeResults, List<String> topics) {
        return debug().setMessage(message).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.MergeResult> mergeResults) {
        return debug().setMessage(message).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, List<Database.SaveResult> saveResults, List<String> topics) {
        return debug().setMessage(message).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.SaveResult> saveResults) {
        return debug().setMessage(message).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return debug().setMessage(message).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.UndeleteResult> undeleteResults) {
        return debug().setMessage(message).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return debug().setMessage(message).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.UpsertResult> upsertResults) {
        return debug().setMessage(message).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @param  topics   The instance of `List<String>` to use as topics for the current entry
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, Id recordId, List<String> topics) {
        return debug().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Id recordId) {
        return debug().setMessage(message).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, List<String> topics) {
        return debug().setMessage(message).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, SObject record, List<String> topics) {
        return debug().setMessage(message).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, SObject record) {
        return debug().setMessage(message).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder debug(String message, List<SObject> records, List<String> topics) {
        return debug().setMessage(message).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<SObject> records) {
        return debug().setMessage(message).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message) {
        return debug().setMessage(message);
    }

    // FINE log level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return fine().setMessage(logMessage).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return fine().setMessage(logMessage).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return fine().setMessage(logMessage).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.MergeResult mergeResult) {
        return fine().setMessage(logMessage).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return fine().setMessage(logMessage).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.SaveResult saveResult) {
        return fine().setMessage(logMessage).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return fine().setMessage(logMessage).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return fine().setMessage(logMessage).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return fine().setMessage(logMessage).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return fine().setMessage(logMessage).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return fine().setMessage(logMessage).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return fine().setMessage(logMessage).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.MergeResult> mergeResults, List<String> topics) {
        return fine().setMessage(logMessage).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return fine().setMessage(logMessage).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.SaveResult> saveResults, List<String> topics) {
        return fine().setMessage(logMessage).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return fine().setMessage(logMessage).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return fine().setMessage(logMessage).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return fine().setMessage(logMessage).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return fine().setMessage(logMessage).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return fine().setMessage(logMessage).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, Id recordId, List<String> topics) {
        return fine().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Id recordId) {
        return fine().setMessage(logMessage).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, List<String> topics) {
        return fine().setMessage(logMessage).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, SObject record, List<String> topics) {
        return fine().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, SObject record) {
        return fine().setMessage(logMessage).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(LogMessage logMessage, List<SObject> records, List<String> topics) {
        return fine().setMessage(logMessage).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<SObject> records) {
        return fine().setMessage(logMessage).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage) {
        return fine().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return fine().setMessage(message).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.DeleteResult deleteResult) {
        return fine().setMessage(message).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, Database.MergeResult mergeResult, List<String> topics) {
        return fine().setMessage(message).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.MergeResult mergeResult) {
        return fine().setMessage(message).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, Database.SaveResult saveResult, List<String> topics) {
        return fine().setMessage(message).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.SaveResult saveResult) {
        return fine().setMessage(message).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return fine().setMessage(message).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.UndeleteResult undeleteResult) {
        return fine().setMessage(message).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return fine().setMessage(message).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.UpsertResult upsertResult) {
        return fine().setMessage(message).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return fine().setMessage(message).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.DeleteResult> deleteResults) {
        return fine().setMessage(message).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, List<Database.MergeResult> mergeResults, List<String> topics) {
        return fine().setMessage(message).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.MergeResult> mergeResults) {
        return fine().setMessage(message).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, List<Database.SaveResult> saveResults, List<String> topics) {
        return fine().setMessage(message).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.SaveResult> saveResults) {
        return fine().setMessage(message).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return fine().setMessage(message).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.UndeleteResult> undeleteResults) {
        return fine().setMessage(message).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return fine().setMessage(message).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.UpsertResult> upsertResults) {
        return fine().setMessage(message).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @param  topics   The instance of `List<String>` to use as topics for the current entry
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, Id recordId, List<String> topics) {
        return fine().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Id recordId) {
        return fine().setMessage(message).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, List<String> topics) {
        return fine().setMessage(message).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, SObject record, List<String> topics) {
        return fine().setMessage(message).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, SObject record) {
        return fine().setMessage(message).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder fine(String message, List<SObject> records, List<String> topics) {
        return fine().setMessage(message).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<SObject> records) {
        return fine().setMessage(message).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message) {
        return fine().setMessage(message);
    }

    // FINER log level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return finer().setMessage(logMessage).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return finer().setMessage(logMessage).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return finer().setMessage(logMessage).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.MergeResult mergeResult) {
        return finer().setMessage(logMessage).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return finer().setMessage(logMessage).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.SaveResult saveResult) {
        return finer().setMessage(logMessage).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return finer().setMessage(logMessage).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return finer().setMessage(logMessage).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return finer().setMessage(logMessage).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return finer().setMessage(logMessage).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return finer().setMessage(logMessage).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return finer().setMessage(logMessage).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.MergeResult> mergeResults, List<String> topics) {
        return finer().setMessage(logMessage).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return finer().setMessage(logMessage).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.SaveResult> saveResults, List<String> topics) {
        return finer().setMessage(logMessage).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return finer().setMessage(logMessage).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return finer().setMessage(logMessage).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return finer().setMessage(logMessage).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return finer().setMessage(logMessage).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return finer().setMessage(logMessage).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, Id recordId, List<String> topics) {
        return finer().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Id recordId) {
        return finer().setMessage(logMessage).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, List<String> topics) {
        return finer().setMessage(logMessage).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, SObject record, List<String> topics) {
        return finer().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, SObject record) {
        return finer().setMessage(logMessage).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(LogMessage logMessage, List<SObject> records, List<String> topics) {
        return finer().setMessage(logMessage).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<SObject> records) {
        return finer().setMessage(logMessage).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage) {
        return finer().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return finer().setMessage(message).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.DeleteResult deleteResult) {
        return finer().setMessage(message).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, Database.MergeResult mergeResult, List<String> topics) {
        return finer().setMessage(message).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.MergeResult mergeResult) {
        return finer().setMessage(message).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, Database.SaveResult saveResult, List<String> topics) {
        return finer().setMessage(message).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.SaveResult saveResult) {
        return finer().setMessage(message).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return finer().setMessage(message).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.UndeleteResult undeleteResult) {
        return finer().setMessage(message).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return finer().setMessage(message).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.UpsertResult upsertResult) {
        return finer().setMessage(message).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return finer().setMessage(message).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.DeleteResult> deleteResults) {
        return finer().setMessage(message).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, List<Database.MergeResult> mergeResults, List<String> topics) {
        return finer().setMessage(message).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.MergeResult> mergeResults) {
        return finer().setMessage(message).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, List<Database.SaveResult> saveResults, List<String> topics) {
        return finer().setMessage(message).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.SaveResult> saveResults) {
        return finer().setMessage(message).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return finer().setMessage(message).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.UndeleteResult> undeleteResults) {
        return finer().setMessage(message).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return finer().setMessage(message).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.UpsertResult> upsertResults) {
        return finer().setMessage(message).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @param  topics   The instance of `List<String>` to use as topics for the current entry
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, Id recordId, List<String> topics) {
        return finer().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Id recordId) {
        return finer().setMessage(message).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, List<String> topics) {
        return finer().setMessage(message).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, SObject record, List<String> topics) {
        return finer().setMessage(message).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, SObject record) {
        return finer().setMessage(message).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finer(String message, List<SObject> records, List<String> topics) {
        return finer().setMessage(message).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<SObject> records) {
        return finer().setMessage(message).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message) {
        return finer().setMessage(message);
    }

    // FINEST log level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return finest().setMessage(logMessage).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return finest().setMessage(logMessage).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return finest().setMessage(logMessage).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.MergeResult mergeResult) {
        return finest().setMessage(logMessage).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return finest().setMessage(logMessage).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.SaveResult saveResult) {
        return finest().setMessage(logMessage).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return finest().setMessage(logMessage).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return finest().setMessage(logMessage).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return finest().setMessage(logMessage).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return finest().setMessage(logMessage).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return finest().setMessage(logMessage).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return finest().setMessage(logMessage).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.MergeResult> mergeResults, List<String> topics) {
        return finest().setMessage(logMessage).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return finest().setMessage(logMessage).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.SaveResult> saveResults, List<String> topics) {
        return finest().setMessage(logMessage).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return finest().setMessage(logMessage).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return finest().setMessage(logMessage).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return finest().setMessage(logMessage).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return finest().setMessage(logMessage).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return finest().setMessage(logMessage).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, Id recordId, List<String> topics) {
        return finest().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Id recordId) {
        return finest().setMessage(logMessage).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, List<String> topics) {
        return finest().setMessage(logMessage).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, SObject record, List<String> topics) {
        return finest().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, SObject record) {
        return finest().setMessage(logMessage).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(LogMessage logMessage, List<SObject> records, List<String> topics) {
        return finest().setMessage(logMessage).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<SObject> records) {
        return finest().setMessage(logMessage).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage) {
        return finest().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return finest().setMessage(message).setDatabaseResult(deleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.DeleteResult deleteResult) {
        return finest().setMessage(message).setDatabaseResult(deleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, Database.MergeResult mergeResult, List<String> topics) {
        return finest().setMessage(message).setDatabaseResult(mergeResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.MergeResult mergeResult) {
        return finest().setMessage(message).setDatabaseResult(mergeResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, Database.SaveResult saveResult, List<String> topics) {
        return finest().setMessage(message).setDatabaseResult(saveResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.SaveResult saveResult) {
        return finest().setMessage(message).setDatabaseResult(saveResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @param  topics         The instance of `List<String>` to use as topics for the current entry
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return finest().setMessage(message).setDatabaseResult(undeleteResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.UndeleteResult undeleteResult) {
        return finest().setMessage(message).setDatabaseResult(undeleteResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return finest().setMessage(message).setDatabaseResult(upsertResult).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.UpsertResult upsertResult) {
        return finest().setMessage(message).setDatabaseResult(upsertResult);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, List<Database.DeleteResult> deleteResults, List<String> topics) {
        return finest().setMessage(message).setDatabaseResult(deleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.DeleteResult> deleteResults) {
        return finest().setMessage(message).setDatabaseResult(deleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @param  topics       The instance of `List<String>` to use as topics for the current entry
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, List<Database.MergeResult> mergeResults, List<String> topics) {
        return finest().setMessage(message).setDatabaseResult(mergeResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.MergeResult> mergeResults) {
        return finest().setMessage(message).setDatabaseResult(mergeResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @param  topics      The instance of `List<String>` to use as topics for the current entry
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, List<Database.SaveResult> saveResults, List<String> topics) {
        return finest().setMessage(message).setDatabaseResult(saveResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.SaveResult> saveResults) {
        return finest().setMessage(message).setDatabaseResult(saveResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @param  topics          The instance of `List<String>` to use as topics for the current entry
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, List<Database.UndeleteResult> undeleteResults, List<String> topics) {
        return finest().setMessage(message).setDatabaseResult(undeleteResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.UndeleteResult> undeleteResults) {
        return finest().setMessage(message).setDatabaseResult(undeleteResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @param  topics        The instance of `List<String>` to use as topics for the current entry
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, List<Database.UpsertResult> upsertResults, List<String> topics) {
        return finest().setMessage(message).setDatabaseResult(upsertResults).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.UpsertResult> upsertResults) {
        return finest().setMessage(message).setDatabaseResult(upsertResults);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @param  topics   The instance of `List<String>` to use as topics for the current entry
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, Id recordId, List<String> topics) {
        return finest().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Id recordId) {
        return finest().setMessage(message).setRecordId(recordId);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, List<String> topics) {
        return finest().setMessage(message).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @param  topics  The instance of `List<String>` to use as topics for the current entry
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, SObject record, List<String> topics) {
        return finest().setMessage(message).setRecordId(record).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, SObject record) {
        return finest().setMessage(message).setRecordId(record);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @param  topics     The instance of `List<String>` to use as topics for the current entry
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    public static LogEntryEventBuilder finest(String message, List<SObject> records, List<String> topics) {
        return finest().setMessage(message).setRecord(records).setTopics(topics);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<SObject> records) {
        return finest().setMessage(message).setRecord(records);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message) {
        return finest().setMessage(message);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if shouldSave == true
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  logMessage   The instance of LogMessage to use as the entry's message
     * @param  shouldSave   Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, LogMessage logMessage, Boolean shouldSave) {
        return newEntry(loggingLevel, shouldSave).setMessage(logMessage);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  logMessage   The instance of LogMessage to use as the entry's message
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, LogMessage logMessage) {
        return newEntry(loggingLevel).setMessage(logMessage);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  message      The string to use as the entry's message
     * @param  shouldSave   Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, String message, Boolean shouldSave) {
        return newEntry(loggingLevel, shouldSave).setMessage(message);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  message      The string to use as the entry's message
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, String message) {
        return newEntry(loggingLevel).setMessage(message);
    }

    // Save control methods
    /**
     * @description Sets the default save method used when calling saveLog() - any subsequent calls to saveLog() will use the specified save method
     * @param  saveMethod - The enum value of Logger.SaveMethod to use for any other calls to saveLog() in the current transaction
     */
    global static void setSaveMethod(SaveMethod saveMethod) {
        transactionSaveMethod = saveMethod;
    }

    /**
     * @description Saves any entries in Logger's buffer. By default, entries are saved via Apex's EventBus and can be overridden with setSaveMethod(SaveMethod saveMethod)
     */
    @InvocableMethod(category='Logging' label='Save Log' description='Saves any log entries that have been generated')
    global static void saveLog() {
        saveLog(transactionSaveMethod);
    }

    /**
     * @description Saves any entries in Logger's buffer, using the specified save method for only this call.
     *   All subsequent calls to saveLog() will use the transaction save method.
     * @param  saveMethod The enum value of Logger.SaveMethod to use for this specific save action.
     */
    global static void saveLog(SaveMethod saveMethod) {
        // Verify that the user has create access
        if (USER_CAN_CREATE_LOG_ENTRY_EVENTS == false) {
            return;
        }

        if (LOG_ENTRIES_BUFFER.isEmpty()) {
            return;
        }

        if (suspendSaving) {
            if (SYSTEM_MESSAGES_ENABLED) {
                finest(getSuspendSavingLogSystemMessage());
            }

            return;
        }

        if (SYSTEM_MESSAGES_ENABLED) {
            finest(getSavingLogSystemMessage(saveMethod));
        }

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        for (LogEntryEventBuilder logEntryEventBuilder : LOG_ENTRIES_BUFFER) {
            if (logEntryEventBuilder.shouldSave()) {
                LogEntryEvent__e logEntryEvent = logEntryEventBuilder.getLogEntryEvent();
                logEntryEvent.ParentLogTransactionId__c = getParentLogTransactionId();
                logEntryEvent.SystemMode__c = getCurrentQuiddity().name();
                logEntryEvent.TransactionId__c = getTransactionId();

                logEntryEvents.add(logEntryEvent);
            }
        }

        switch on saveMethod {
            when EVENT_BUS {
                // TODO add error handling for when event bus fails to publish
                List<Database.SaveResult> results = EventBus.publish(logEntryEvents);
                System.debug('saveResults =' + results);
            }
            when QUEUEABLE {
                System.enqueueJob(new QueueableSaver(logEntryEvents));
            }
            when REST {
                // If the user doesn't have a session ID (e.g., site guest user), the REST API call will fail
                // To avoid that, use the EventBus instead (even though REST was specified)
                if (String.isBlank(UserInfo.getUserId())) {
                    saveLog(Logger.SaveMethod.EVENT_BUS);
                } else {
                    new RestApiSaver().insertRecords(logEntryEvents);
                }
            }
        }

        flushBuffer();
    }

    // Utility methods

    /**
     * @description Converts a String to an instance of LoggingLevel
     * @param  loggingLevelName The string name of an Apex logging level
     * @return                  The matching instance of LoggingLevel (or a default value if a match is not found)
     */
    global static LoggingLevel getLoggingLevel(String loggingLevelName) {
        if (loggingLevelName != null) {
            loggingLevelName = loggingLevelName.trim().toUpperCase();
        }

        switch on loggingLevelName {
            when 'NONE' {
                return LoggingLevel.NONE;
            }
            when 'ERROR' {
                return LoggingLevel.ERROR;
            }
            when 'WARN' {
                return LoggingLevel.WARN;
            }
            when 'INFO' {
                return LoggingLevel.INFO;
            }
            when 'DEBUG' {
                return LoggingLevel.DEBUG;
            }
            when 'FINE' {
                return LoggingLevel.FINE;
            }
            when 'FINER' {
                return LoggingLevel.FINER;
            }
            when 'FINEST' {
                return LoggingLevel.FINEST;
            }
            when else {
                if (SYSTEM_MESSAGES_ENABLED) {
                    String message = 'Unknown logging level ' + loggingLevelName + 'specified, using ' + DEFAULT_LOGGING_LEVEL.name();
                    finest(message);
                }
                return DEFAULT_LOGGING_LEVEL;
            }
        }
    }

    // For orgs that already have the aura cmp + quickAction deployed, this method is still needed (otherwise, deployment errors will occur)
    // TODO consider removing this method after converting aura cmp to lwc (and presumably create a dedicated Apex ctrl w/ this method)
    // But the safe choice is to just keep it now/forever
    /**
     * @description Returns a Log__c record from the database, using either the Salesforce ID or transaction ID
     * @param  logId The Salesforce ID or TransactionId__c of the Log__c
     * @return       The matching record, with all fields that the current user can access
     */
    @AuraEnabled(cacheable=true)
    public static Log__c getLog(String logId) {
        List<String> logFieldNames = new List<String>(Schema.Log__c.SObjectType.getDescribe().fields.getMap().keySet());
        List<String> logEntryFieldNames = new List<String>(Schema.LogEntry__c.SObjectType.getDescribe().fields.getMap().keySet());

        List<String> textReplacements = new List<String>{ String.join(logFieldNames, ','), String.join(logEntryFieldNames, ',') };
        String query = String.format(
            'SELECT {0}, (SELECT {1} FROM LogEntries__r) FROM Log__c WHERE Id = :logId OR TransactionId__c = :logId',
            textReplacements
        );

        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, Database.query(query));

        if (securityDecision.getRecords().isEmpty()) {
            return null;
        } else {
            return (Log__c) securityDecision.getRecords().get(0);
        }
    }

    // Private logging level methods to keep global methods simpler/cleaner
    private static LogEntryEventBuilder error() {
        return newEntry(LoggingLevel.ERROR);
    }

    private static LogEntryEventBuilder warn() {
        return newEntry(LoggingLevel.WARN);
    }

    private static LogEntryEventBuilder info() {
        return newEntry(LoggingLevel.INFO);
    }

    private static LogEntryEventBuilder debug() {
        return newEntry(LoggingLevel.DEBUG);
    }

    private static LogEntryEventBuilder fine() {
        return newEntry(LoggingLevel.FINE);
    }

    private static LogEntryEventBuilder finer() {
        return newEntry(LoggingLevel.FINER);
    }

    private static LogEntryEventBuilder finest() {
        return newEntry(LoggingLevel.FINEST);
    }

    private static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel) {
        return newEntry(loggingLevel, isEnabled(loggingLevel));
    }

    private static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, Boolean shouldSave) {
        shouldSave = shouldSave && USER_CAN_CREATE_LOG_ENTRY_EVENTS;

        LogEntryEventBuilder logEntryEventBuilder = new LogEntryEventBuilder(LoggingLevel, shouldSave);
        if (logEntryEventBuilder.shouldSave() == true) {
            logEntryEventBuilder.getLogEntryEvent().TransactionEntryNumber__c = currentTransactionEntryNumber++;
            LOG_ENTRIES_BUFFER.add(logEntryEventBuilder);
        }

        return logEntryEventBuilder;
    }

    private static SaveMethod getDefaultSaveMethod() {
        SaveMethod defaultSaveMethod;

        String saveMethodName = LoggerSettings__c.getInstance().DefaultSaveMethod__c?.toUpperCase();
        switch on saveMethodName {
            when 'QUEUEABLE' {
                defaultSaveMethod = SaveMethod.QUEUEABLE;
            }
            when 'REST' {
                defaultSaveMethod = SaveMethod.REST;
            }
            when else {
                defaultSaveMethod = SaveMethod.EVENT_BUS;
            }
        }

        return defaultSaveMethod;
    }

    private static String getSuspendSavingLogSystemMessage() {
        return 'Logging suspended, ignoring call to saveLog()';
    }

    private static String getSavingLogSystemMessage(SaveMethod saveMethod) {
        String savingLogMessage = 'Saving ' + LOG_ENTRIES_BUFFER.size() + ' log entries via ';
        switch on getCurrentQuiddity() {
            when ANONYMOUS {
                savingLogMessage += 'Anonymous Apex';
            }
            when AURA, VF {
                savingLogMessage += 'Aura/Lightning/VF component';
            }
            when BATCH_ACS, BATCH_APEX, BATCH_CHUNK_PARALLEL, BATCH_CHUNK_SERIAL {
                savingLogMessage += 'Apex batch job';
            }
            when INVOCABLE_ACTION {
                savingLogMessage += 'Flow invocation';
            }
            when QUEUEABLE {
                savingLogMessage += 'Apex queueable job';
            }
            when REST {
                savingLogMessage += 'Apex REST callout';
            }
            when SCHEDULED {
                savingLogMessage += 'Scheduled job';
            }
            when SYNCHRONOUS {
                savingLogMessage += 'Apex synchronous DML';
            }
            when else {
                savingLogMessage += getCurrentQuiddity().name();
            }
        }
        savingLogMessage += ', save method is ' + saveMethod.name();

        return savingLogMessage;
    }

    // Inner class for saving log entries via a queuable job
    global class QueueableSaver implements Queueable {
        private Id jobId;

        private List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();

        private QueueableSaver(List<LogEntryEvent__e> logEntryEvents) {
            this.logEntryEvents = logEntryEvents;
        }

        global void execute(System.QueueableContext queueableContext) {
            EventBus.publish(this.logEntryEvents);
        }
    }

    // Inner class for saving log entries via the REST API (using the current user's session ID)
    private class RestApiSaver {
        private final String BASE_URL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/data/v51.0';
        private final String COMPOSITE_ENDPOINT = '/composite/sobjects';

        public void insertRecords(List<SObject> records) {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(BASE_URL + COMPOSITE_ENDPOINT);
            request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            request.setHeader('Content-Type', 'application/json; charset=utf-8');
            request.setMethod('POST');

            Boolean allOrNone = true;
            RestSaveRequest saveRequest = new RestSaveRequest(records, allOrNone);
            request.setBody(JSON.serialize(saveRequest));

            HttpResponse response = new Http().send(request);
            this.validateResponse(response);
        }

        private void validateResponse(Httpresponse response) {
            Integer statusCode = response.getStatusCode();
            if (statusCode >= 400) {
                String errorMessage = 'Saving via REST API failed. Received request status code ' + statusCode + ', status message: ' + response.getStatus();
                throw new RestResponseException(errorMessage);
            }
        }
    }

    @testVisible
    private class RestResponseException extends Exception {
    }

    // Inner class that matches the format expected by the REST API for saving SObjects
    private class RestSaveRequest {
        public Boolean allOrNone { get; set; }
        public List<SObject> records { get; set; }

        private RestSaveRequest(List<SObject> records, Boolean allOrNone) {
            this.allOrNone = allOrNone;
            this.records = records;
        }
    }
}
