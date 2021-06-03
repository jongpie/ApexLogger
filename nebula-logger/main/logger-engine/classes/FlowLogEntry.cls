//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Handles adding new log entries in Flow
 * @see FlowRecordLogEntry
 * @see Logger
 * @see LogEntryEventBuilder
 */
global inherited sharing class FlowLogEntry {
    /**
     * @description The name of the Flow creating the log entry.
     *   Due to Salesforce limitations, this cannot be automatically determined.
     */
    @InvocableVariable(required=true label='Flow or Process Builder Name')
    global String flowName;

    /**
     * @description The message to log.
     */
    @InvocableVariable(required=true label='Log Entry Message')
    global String message;

    /**
     * @description Optionally log a Flow fault error message
     */
    @InvocableVariable(required=false label='(Optional) Flow Fault Error Message')
    global String faultMessage;

    /**
     * @description Optionally choose to save any pending log entries.
     */
    @InvocableVariable(required=false label='(Optional) Save Log')
    global Boolean saveLog = false;

    /**
     * @description Optionally relate the log entry to a particular record ID
     */
    @InvocableVariable(required=false label='(Optional) Record ID')
    global Id recordId;

    /**
     * @description Optionally specify a logging level - the default is 'DEBUG'
     */
    @InvocableVariable(required=false label='(Optional) Logging Level')
    global String loggingLevelName;

    /**
     * @description Optionally provide a list of topics to dynamically assign to the log entry
     */
    @InvocableVariable(required=false label='(Optional) Topics')
    public List<String> topics;

    private DateTime timestamp = System.now();

    /**
     * addFlowEntries description
     * @param  flowLogEntries The list of FlowLogEntry instances to save
     * @return                The current transaction's ID (based on `Logger.getTransactionId()`)
     */
    @InvocableMethod(category='Logging' label='Add Log Entry' description='Creates a log entry for a flow or process builder')
    global static List<String> addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        Boolean saveLog = false;
        for (FlowLogEntry flowLogEntry : flowLogEntries) {
            // Set the logging level if it's blank
            if (String.isBlank(flowLogEntry.loggingLevelName)) {
                if (String.isNotBlank(flowLogEntry.faultMessage)) {
                    flowLogEntry.loggingLevelName = 'ERROR';
                } else {
                    flowLogEntry.loggingLevelName = 'DEBUG';
                }
            }

            LoggingLevel loggingLevel = Logger.getLoggingLevel(flowLogEntry.loggingLevelName);

            LogEntryEventBuilder logEntryEventBuilder = Logger.newEntry(loggingLevel, flowLogEntry.message)
                .setRecordId(flowLogEntry.recordId)
                .setTopics(flowLogEntry.topics);

            LogEntryEvent__e logEntryEvent = logEntryEventBuilder.getLogEntryEvent();

            if (logEntryEventBuilder.shouldSave() == false) {
                continue;
            }

            logEntryEvent.OriginLocation__c = flowLogEntry.flowName;
            logEntryEvent.OriginType__c = 'Flow';
            logEntryEvent.Timestamp__c = flowLogEntry.timestamp;

            if (String.isNotBlank(flowLogEntry.faultMessage)) {
                logEntryEvent.ExceptionMessage__c = flowLogEntry.faultMessage;
                logEntryEvent.ExceptionType__c = 'Flow.FaultError';
            }

            if (flowLogEntry.saveLog == true) {
                saveLog = flowLogEntry.saveLog;
            }
        }

        if (saveLog == true) {
            Logger.saveLog();
        }

        // Event though it's the same transaction ID, Salesforce expects the returned list...
        // ...to have the same number of items as the initial input.
        // When there's a mismatch, Salesforce throws an error:
        // FLOW_ELEMENT_ERROR The number of results does not match the number of interviews that were executed in a single bulk execution request.|FlowActionCall
        List<String> transactionIds = new List<String>();
        for (Integer i = 0; i < flowLogEntries.size(); i++) {
            transactionIds.add(Logger.getTransactionId());
        }
        return transactionIds;
    }
}
