//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Additional integration tests for merging records.
 *              Since merging is only supported on some standard objects, there's not a good way to test merging...
 *              ...from within the normal tests, and each org might have additional required fields, VR, etc on the std objects
 */
@isTest
private class Logger_Tests_MergeResult {
    static String getMessage() {
        return 'Hello, world';
    }

    static LogMessage getLogMessage() {
        return new LogMessage('The current date is {0}', System.today());
    }

    static Database.MergeResult getMergeResult() {
        Account mainAccount = new Account(Name = 'Main');
        Account duplicateAccount = new Account(Name = 'Duplicate');
        List<Account> accounts = new List<Account>{ mainAccount, duplicateAccount };
        insert accounts;

        Database.MergeResult mergeResult = Database.merge(mainAccount, duplicateAccount);
        return mergeResult;
    }

    static List<Database.MergeResult> getMergeResultList() {
        return new List<Database.MergeResult>{ getMergeResult() };
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('List', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('List', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('List', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('List', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('List', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('List', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_mergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        Database.MergeResult mergeResult = getMergeResult();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), mergeResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Single', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_mergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.MergeResult> mergeResults = getMergeResultList();

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), mergeResults);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('List', entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
}
