//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class FlowLogEntry_Tests {
    static FlowLogEntry createFlowLogEntry() {
        FlowLogEntry flowRecordEntry = new FlowLogEntry();
        flowRecordEntry.flowName = 'MyFlowOrProcessBuilder';
        flowRecordEntry.message = 'my test message';
        flowRecordEntry.saveLog = false;

        return flowRecordEntry;
    }

    @isTest
    static void it_should_save_entry_when_logging_level_met() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowRecordEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowRecordEntryLoggingLevel.ordinal());

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        Logger.getUserSettings().EnableSystemMessages__c = false;

        FlowLogEntry flowRecordEntry = createFlowLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel.name();
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowRecordEntry });

        System.assertEquals(1, Logger.getBufferSize());

        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(flowRecordEntry.loggingLevelName, logEntry.LoggingLevel__c);
        System.assertEquals(flowRecordEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
    }

    @isTest
    static void it_should_auto_save_entry_when_saveLog_is_true() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowRecordEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowRecordEntryLoggingLevel.ordinal());

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        Logger.getUserSettings().EnableSystemMessages__c = false;

        FlowLogEntry flowRecordEntry = createFlowLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel.name();
        flowRecordEntry.saveLog = true;
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowRecordEntry });

        Test.stopTest();

        LogEntry__c logEntry = [
            SELECT Id, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c, RecordId__c, RecordJson__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
        System.assertEquals(flowRecordEntry.loggingLevelName, logEntry.LoggingLevel__c);
        System.assertEquals(flowRecordEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
    }

    @isTest
    static void it_should_not_save_entry_when_logging_level_not_met() {
        LoggingLevel userLoggingLevel = LoggingLevel.ERROR;
        LoggingLevel flowRecordEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() > flowRecordEntryLoggingLevel.ordinal());

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        Logger.getUserSettings().EnableSystemMessages__c = false;

        FlowLogEntry flowRecordEntry = createFlowLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel.name();
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowRecordEntry });

        System.assertEquals(0, Logger.getBufferSize());

        Test.stopTest();
    }

    @isTest
    static void it_should_use_debug_as_default_level_when_faultMessage_is_null() {
        LoggingLevel expectedEntryLoggingLevel = LoggingLevel.DEBUG;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = expectedEntryLoggingLevel.name();
        Logger.getUserSettings().EnableSystemMessages__c = false;

        FlowLogEntry flowEntry = createFlowLogEntry();
        System.assertEquals(null, flowEntry.faultMessage);
        System.assertEquals(null, flowEntry.loggingLevelName);

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.assertEquals(expectedEntryLoggingLevel.name(), flowEntry.loggingLevelName);

        System.assertEquals(1, Logger.getBufferSize());

        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [
            SELECT Id, ExceptionMessage__c, ExceptionType__c, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
        System.assertEquals(null, logEntry.ExceptionMessage__c);
        System.assertEquals(null, logEntry.ExceptionType__c);
        System.assertEquals(expectedEntryLoggingLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
    }

    @isTest
    static void it_should_use_error_as_default_level_when_faultMessage_is_not_null() {
        LoggingLevel expectedEntryLoggingLevel = LoggingLevel.ERROR;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();
        Logger.getUserSettings().EnableSystemMessages__c = false;

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.faultMessage = 'Whoops, a Flow error has occurred.';
        System.assertEquals(null, flowEntry.loggingLevelName);

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.assertEquals(expectedEntryLoggingLevel.name(), flowEntry.loggingLevelName);

        System.assertEquals(1, Logger.getBufferSize());

        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [
            SELECT Id, ExceptionMessage__c, ExceptionType__c, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
        System.assertEquals(flowEntry.faultMessage, logEntry.ExceptionMessage__c);
        System.assertEquals('Flow.FaultError', logEntry.ExceptionType__c);
        System.assertEquals(expectedEntryLoggingLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
    }
}
