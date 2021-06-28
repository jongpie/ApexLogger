//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Handles adding new log entries in Flow for a particular `SObject` record collection
 * @see FlowLogEntry
 * @see FlowRecordLogEntry
 * @see FlowLogger
 * @see Logger
 * @see LogEntryEventBuilder
 */
global inherited sharing class FlowCollectionLogEntry {
    /**
     * @description The name of the Flow creating the log entry.
     *   Due to Salesforce limitations, this cannot be automatically determined
     */
    @InvocableVariable(required=true label='Flow or Process Builder Name')
    global String flowName;

    /**
     * @description The message to log
     */
    @InvocableVariable(required=true label='Log Entry Message')
    global String message;

    /**
     * @description The records to relate to this log entry - the records' JSON is automatically added to the log entry
     */
    @InvocableVariable(required=true label='Records')
    global List<SObject> records;

    /**
     * @description Optionally log a Flow fault error message
     */
    @InvocableVariable(required=false label='(Optional) Flow Fault Error Message')
    global String faultMessage;
    /**
     * @description Optionally choose to save any pending log entries
     */
    @InvocableVariable(required=false label='(Optional) Save Log')
    global Boolean saveLog = false;

    /**
     * @description Optionally specify a logging level - the default is 'DEBUG'
     */
    @InvocableVariable(required=false label='(Optional) Logging Level')
    global String loggingLevelName;

    /**
     * @description Optionally provide a list of topics to dynamically assign to the log entry
     */
    @InvocableVariable(required=false label='(Optional) Tags')
    global List<String> tags;

    /**
     * @description Optionally provide a list of topics to dynamically assign to the log entry
     */
    @InvocableVariable(required=false label='DEPRECATED: Use \'Tags\' Instead')
    public List<String> topics;

    public DateTime timestamp = System.now();

    /**
     * addFlowRecordEntries description
     * @param  flowRecordLogEntries The list of FlowRecordLogEntry instances to save
     * @return                      The current transaction's ID (based on `Logger.getTransactionId()`)
     */
    @InvocableMethod(
        category='Logging'
        label='Add Log Entry for an SObject Record Collection'
        description='Creates a log entry for a flow or process builder and stores the record as JSON'
    )
    global static List<String> addFlowCollectionEntries(List<FlowCollectionLogEntry> flowCollectionLogEntries) {
        List<FlowLogger.LogEntry> shadowLogEntries = new List<FlowLogger.LogEntry>();
        for (FlowCollectionLogEntry flowCollectionLogEntry : flowCollectionLogEntries) {
            FlowLogger.LogEntry shadowLogEntry = (FlowLogger.LogEntry) JSON.deserialize(JSON.serialize(flowCollectionLogEntry), FlowLogger.LogEntry.class);
            shadowLogEntry.addToLoggerBuffer()?.setRecord(flowCollectionLogEntry.records);

            shadowLogEntries.add(shadowLogEntry);
        }

        return FlowLogger.addEntries(shadowLogEntries);
    }
}
