//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description The core class for logging
 * @see LogEntryEventBuilder
 * @see LogMessage
 */
global with sharing class Logger {
    private static final LoggingLevel DEFAULT_LOGGING_LEVEL = LoggingLevel.DEBUG;
    private static final List<LogEntryEventBuilder> LOG_ENTRIES_BUFFER = new List<LogEntryEventBuilder>();
    private static final String TRANSACTION_ID = setTransactionId();
    private static final Quiddity TRANSACTION_QUIDDITY = System.Request.getCurrent().getQuiddity();

    private static Integer currentTransactionEntryNumber = 1;
    private static String parentLogTransactionId;
    private static Boolean suspendSaving = false;
    private static LoggerSettings__c userSettings;

    @testVisible
    private static SaveMethod transactionSaveMethod {
        get {
            if (transactionSaveMethod == null) {
                transactionSaveMethod = getDefaultSaveMethod();
            }
            return transactionSaveMethod;
        }
        set;
    }

    private static LoggingLevel userLoggingLevel {
        get {
            if (userLoggingLevel == null || userLoggingLevel.name() != getUserSettings().LoggingLevel__c) {
                userLoggingLevel = getLoggingLevel(getUserSettings().LoggingLevel__c);
            }
            return userLoggingLevel;
        }
        set;
    }

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
        REST,
        SYNCHRONOUS_DML
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
        if (parentTransactionId != getTransactionId()) {
            parentLogTransactionId = parentTransactionId;
        }
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
        return getUserSettings().IsEnabled__c;
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
        return userLoggingLevel.ordinal() <= logEntryLoggingLevel.ordinal();
    }

    /**
     * @description Returns the logging level for the current user, based on the custom setting LoggerSettings__c
     * @return LoggingLevel - The matching instance of LoggingLevel
     */
    global static LoggingLevel getUserLoggingLevel() {
        return userLoggingLevel;
    }

    /**
     * @description Returns the current user's instance of `LoggerSettings__c`
     * @return LoggerSettings__c - The current user's instance of the custom settings
     */
    // TODO make this method `global` in a future release
    public static LoggerSettings__c getUserSettings() {
        // Only load the current user's settings once - this allows the instance to be modified in memory (as well as upserted if any changes should be persisted)
        if (userSettings == null) {
            User currentUser = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
            userSettings = getUserSettings(currentUser);
        }
        return userSettings;
    }

    /**
     * @description Returns the specified user's instance of `LoggerSettings__c`
     * @param  user The user record - at a minimum, this record should have the user Id and Profile fields populated
     * @return      LoggerSettings__c - The specified user's instance of the custom settings
     */
    // TODO make this method `global` in a future release
    public static LoggerSettings__c getUserSettings(User loggingUser) {
        // Typically, using LoggerSettings__c.getInstance() would be easier
        // However, some settings fields are expected to have null values, which conflicts with how `getInstance()` behaves
        // So, instead use LoggerSettings__c.getValues(Id userOrProfileId) to load exactly what's been configured (including nulls)

        LoggerSettings__c loggingUserSettings;
        if (loggingUser.Id != null && LoggerSettings__c.getValues(loggingUser.Id) != null) {
            // Check for User-level settings
            loggingUserSettings = LoggerSettings__c.getValues(loggingUser.Id);
        } else if (loggingUserSettings == null && loggingUser.ProfileId != null && LoggerSettings__c.getValues(loggingUser.ProfileId) != null) {
            // Next, check for Profile-level settings
            loggingUserSettings = LoggerSettings__c.getValues(loggingUser.ProfileId);
        } else {
            // Finally, use the org defaults
            loggingUserSettings = LoggerSettings__c.getOrgDefaults();
        }

        // If the settings were loaded from the org or profile level, clear the ID and make the user the SetupOwnerId (since the method is getUserSettings)
        // This allows the ability to then upsert the instance of LoggerSettings__c and it will always be specific to that user...
        // ...which avoids accidentally changing something at the org or profile levels
        if (loggingUser.Id != null && loggingUserSettings.SetupOwnerId != loggingUser.Id) {
            loggingUserSettings.Id = null;
            loggingUserSettings.SetupOwnerId = loggingUser.Id;
        }

        return loggingUserSettings;
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return error().setMessage(logMessage).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.SaveResult saveResult) {
        return error().setMessage(logMessage).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return error().setMessage(logMessage).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return error().setMessage(logMessage).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return error().setMessage(logMessage).setDatabaseResult(undeleteResults);
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
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, Exception apexException) {
        return error().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException);
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
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records, Exception apexException) {
        return error().setMessage(logMessage).setRecord(records).setExceptionDetails(apexException);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.DeleteResult deleteResult) {
        return error().setMessage(message).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.SaveResult saveResult) {
        return error().setMessage(message).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.UpsertResult upsertResult) {
        return error().setMessage(message).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.MergeResult> mergeResults) {
        return error().setMessage(message).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.UndeleteResult> undeleteResults) {
        return error().setMessage(message).setDatabaseResult(undeleteResults);
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
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Id recordId, Exception apexException) {
        return error().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Id recordId) {
        return error().setMessage(message).setRecordId(recordId);
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
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<SObject> records, Exception apexException) {
        return error().setMessage(message).setRecord(records).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return warn().setMessage(logMessage).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.SaveResult saveResult) {
        return warn().setMessage(logMessage).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return warn().setMessage(logMessage).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return warn().setMessage(logMessage).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return warn().setMessage(logMessage).setDatabaseResult(undeleteResults);
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
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, Exception apexException) {
        return warn().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException);
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
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records, Exception apexException) {
        return warn().setMessage(logMessage).setRecord(records).setExceptionDetails(apexException);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.DeleteResult deleteResult) {
        return warn().setMessage(message).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.SaveResult saveResult) {
        return warn().setMessage(message).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.UpsertResult upsertResult) {
        return warn().setMessage(message).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.MergeResult> mergeResults) {
        return warn().setMessage(message).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.UndeleteResult> undeleteResults) {
        return warn().setMessage(message).setDatabaseResult(undeleteResults);
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
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Id recordId, Exception apexException) {
        return warn().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Id recordId) {
        return warn().setMessage(message).setRecordId(recordId);
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
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<SObject> records, Exception apexException) {
        return warn().setMessage(message).setRecord(records).setExceptionDetails(apexException);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
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
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.MergeResult mergeResult) {
        return info().setMessage(logMessage).setDatabaseResult(mergeResult);
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
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return info().setMessage(logMessage).setDatabaseResult(undeleteResult);
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
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return info().setMessage(logMessage).setDatabaseResult(deleteResults);
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
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return info().setMessage(logMessage).setDatabaseResult(saveResults);
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
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return info().setMessage(logMessage).setDatabaseResult(upsertResults);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.DeleteResult deleteResult) {
        return info().setMessage(message).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.SaveResult saveResult) {
        return info().setMessage(message).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.UpsertResult upsertResult) {
        return info().setMessage(message).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.MergeResult> mergeResults) {
        return info().setMessage(message).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.UndeleteResult> undeleteResults) {
        return info().setMessage(message).setDatabaseResult(undeleteResults);
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
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Id recordId) {
        return info().setMessage(message).setRecordId(recordId);
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
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return debug().setMessage(logMessage).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.SaveResult saveResult) {
        return debug().setMessage(logMessage).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return debug().setMessage(logMessage).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return debug().setMessage(logMessage).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return debug().setMessage(logMessage).setDatabaseResult(undeleteResults);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Id recordId) {
        return debug().setMessage(logMessage).setRecordId(recordId);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.DeleteResult deleteResult) {
        return debug().setMessage(message).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.SaveResult saveResult) {
        return debug().setMessage(message).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.UpsertResult upsertResult) {
        return debug().setMessage(message).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.MergeResult> mergeResults) {
        return debug().setMessage(message).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.UndeleteResult> undeleteResults) {
        return debug().setMessage(message).setDatabaseResult(undeleteResults);
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
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Id recordId) {
        return debug().setMessage(message).setRecordId(recordId);
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
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return fine().setMessage(logMessage).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.SaveResult saveResult) {
        return fine().setMessage(logMessage).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return fine().setMessage(logMessage).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return fine().setMessage(logMessage).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return fine().setMessage(logMessage).setDatabaseResult(undeleteResults);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Id recordId) {
        return fine().setMessage(logMessage).setRecordId(recordId);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.DeleteResult deleteResult) {
        return fine().setMessage(message).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.SaveResult saveResult) {
        return fine().setMessage(message).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.UpsertResult upsertResult) {
        return fine().setMessage(message).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.MergeResult> mergeResults) {
        return fine().setMessage(message).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.UndeleteResult> undeleteResults) {
        return fine().setMessage(message).setDatabaseResult(undeleteResults);
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
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Id recordId) {
        return fine().setMessage(message).setRecordId(recordId);
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
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return finer().setMessage(logMessage).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.SaveResult saveResult) {
        return finer().setMessage(logMessage).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return finer().setMessage(logMessage).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return finer().setMessage(logMessage).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return finer().setMessage(logMessage).setDatabaseResult(undeleteResults);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Id recordId) {
        return finer().setMessage(logMessage).setRecordId(recordId);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.DeleteResult deleteResult) {
        return finer().setMessage(message).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.SaveResult saveResult) {
        return finer().setMessage(message).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.UpsertResult upsertResult) {
        return finer().setMessage(message).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.MergeResult> mergeResults) {
        return finer().setMessage(message).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.UndeleteResult> undeleteResults) {
        return finer().setMessage(message).setDatabaseResult(undeleteResults);
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
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Id recordId) {
        return finer().setMessage(message).setRecordId(recordId);
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
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return finest().setMessage(logMessage).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.SaveResult saveResult) {
        return finest().setMessage(logMessage).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return finest().setMessage(logMessage).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return finest().setMessage(logMessage).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return finest().setMessage(logMessage).setDatabaseResult(undeleteResults);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Id recordId) {
        return finest().setMessage(logMessage).setRecordId(recordId);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.DeleteResult deleteResult) {
        return finest().setMessage(message).setDatabaseResult(deleteResult);
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
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.SaveResult saveResult) {
        return finest().setMessage(message).setDatabaseResult(saveResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.UpsertResult upsertResult) {
        return finest().setMessage(message).setDatabaseResult(upsertResult);
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
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.MergeResult> mergeResults) {
        return finest().setMessage(message).setDatabaseResult(mergeResults);
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
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.UndeleteResult> undeleteResults) {
        return finest().setMessage(message).setDatabaseResult(undeleteResults);
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
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Id recordId) {
        return finest().setMessage(message).setRecordId(recordId);
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
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
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
        if (LOG_ENTRIES_BUFFER.isEmpty()) {
            return;
        }

        if (suspendSaving == true) {
            if (getUserSettings().EnableSystemMessages__c == true) {
                finest(getSuspendSavingLogSystemMessage());
            }

            return;
        }

        if (getUserSettings().EnableSystemMessages__c == true) {
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

        // Platform events don't support BEFORE_INSERT operations (only AFTER_INSERT is supported)
        // ... but here we are, getting ready to insert the records, but we haven't.... yet
        // It's... it's... almost like... this part of the code IS a BEFORE_INSERT context. Huzzah!
        // This gives us a chance to run the handler class & handler plugins before insert,
        // allowing the plugins to make further changes to the `LogEntryEvent__e` records
        // So, execute the handler, which internally then executes any plugins
        new LogEntryEventHandler(TriggerOperation.BEFORE_INSERT, logEntryEvents).execute();

        // Now that the plugins have run, double check to make sure that saving should still happen
        if (getBufferSize() == 0) {
            return;
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
            when SYNCHRONOUS_DML {
                new LogEntryEventHandler(TriggerOperation.AFTER_INSERT, logEntryEvents).execute();
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
                if (getUserSettings().EnableSystemMessages__c == true) {
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
        logFieldNames.addAll(new List<String>{ 'Owner.Name', 'Owner.Type' });
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
        LogEntryEventBuilder logEntryEventBuilder = new LogEntryEventBuilder(LoggingLevel, shouldSave);
        if (logEntryEventBuilder.shouldSave() == true) {
            logEntryEventBuilder.getLogEntryEvent().TransactionEntryNumber__c = currentTransactionEntryNumber++;
            LOG_ENTRIES_BUFFER.add(logEntryEventBuilder);
        }

        return logEntryEventBuilder;
    }

    private static String setTransactionId() {
        String transactionId = System.Request.getCurrent().getRequestId();
        return String.isNotBlank(transactionId) ? transactionId : new Uuid().getValue();
    }

    private static SaveMethod getDefaultSaveMethod() {
        SaveMethod defaultSaveMethod;

        String saveMethodName = getUserSettings().DefaultSaveMethod__c?.toUpperCase();
        switch on saveMethodName {
            when 'QUEUEABLE' {
                defaultSaveMethod = SaveMethod.QUEUEABLE;
            }
            when 'REST' {
                defaultSaveMethod = SaveMethod.REST;
            }
            when 'SYNCHRONOUS_DML' {
                defaultSaveMethod = SaveMethod.SYNCHRONOUS_DML;
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

    /******************************************************************************************
    * This code is based on the Apex UUID project, released under the MIT License.            *
    * See LICENSE file or go to https://github.com/jongpie/ApexUuid for full license details. *
    ******************************************************************************************/
    @testVisible
    private without sharing class Uuid {

        private final String HEX_CHARACTERS           = '0123456789abcdef';
        private final String HEX_PREFIX               = '0x';
        private final List<String> HEX_CHARACTER_LIST = HEX_CHARACTERS.split('');
        private final Integer UUID_V4_LENGTH          = 36;
        private final String UUID_V4_REGEX            = '[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}';


        private final String value;

        public Uuid() {
            this.value = this.generateValue();
        }

        public String getValue() {
            return this.value;
        }

        private String generateValue() {
            String hexValue = EncodingUtil.convertToHex(Crypto.generateAesKey(128));

            // Version Calculation: (i & 0x0f) | 0x40
            // Version Format: Always begins with 4
            String versionShiftedHexBits = this.getShiftedHexBits(hexValue.substring(14, 16), this.convertHexToInteger('0x0f'), this.convertHexToInteger('0x40'));

            // Variant Calculation: (i & 0x3f) | 0x80
            // Variant Format: Always begins with 8, 9, A or B
            String variantShiftedHexBits = this.getShiftedHexBits(hexValue.substring(18, 20), this.convertHexToInteger('0x3f'), this.convertHexToInteger('0x80'));

            String uuidValue = hexValue.substring(0, 8)              // time-low
                + hexValue.substring(8, 12)                          // time-mid
                + versionShiftedHexBits + hexValue.substring(14, 16) // time-high-and-version
                + variantShiftedHexBits + hexValue.substring(18, 20) // clock-seq-and-reserved + clock-seq-low
                + hexValue.substring(20);                            // node

            return formatValue(uuidValue);
        }

        private String formatValue(String unformattedValue) {
            final String invalidValueError = unformattedValue + ' is not a valid UUID value';

            // Remove any non-alphanumeric characters
            unformattedValue = unformattedValue.replaceAll('[^a-zA-Z0-9]', '');

            // UUID Pattern: 8-4-4-4-12
            String formattedValue = unformattedValue.substring(0, 8)
                + '-' + unformattedValue.substring(8, 12)
                + '-' + unformattedValue.substring(12, 16)
                + '-' + unformattedValue.substring(16, 20)
                + '-' + unformattedValue.substring(20);

            return formattedValue.toLowerCase();
        }

        private String getShiftedHexBits(String hexSubstring, Integer lowerThreshold, Integer upperThreshold) {
            Integer shiftedIntegerBits = (this.convertHexToInteger(hexSubstring) & lowerThreshold) | upperThreshold;
            return this.convertIntegerToHex(shiftedIntegerBits);
        }

        private Integer convertHexToInteger(String hexValue) {
            hexValue = hexValue.toLowerCase();

            if(hexValue.startsWith(HEX_PREFIX)) hexValue = hexValue.substringAfter(HEX_PREFIX);

            Integer integerValue = 0;
            for(String hexCharacter : hexValue.split('')) {
                Integer hexCharacterIndex = HEX_CHARACTERS.indexOf(hexCharacter);

                integerValue = HEX_CHARACTERS.length() * integerValue + hexCharacterIndex;
            }
            return integerValue;
        }

        private String convertIntegerToHex(Integer integerValue) {
            String hexValue = '';
            while(integerValue > 0) {
                Integer hexCharacterIndex = Math.mod(integerValue, HEX_CHARACTERS.length());

                hexValue     = HEX_CHARACTER_LIST[hexCharacterIndex] + hexValue;
                integerValue = integerValue / HEX_CHARACTERS.length();
            }
            return hexValue;
        }
    }
}
