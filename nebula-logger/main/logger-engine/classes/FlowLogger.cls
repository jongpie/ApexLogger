//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Handles some common logic used by `FlowLogEntry`, `FlowRecordLogEntry` and `FlowCollectionLogEntry`
 * @see FlowLogEntry
 * @see FlowRecordLogEntry
 * @see FlowCollectionLogEntry
 * @see Logger
 * @see LogEntryEventBuilder
 */
public inherited sharing class FlowLogger {
    // Invocable methods and properties are goofy, but we can be goofier
    // Properties goofiness: you can’t keep common properties in a parent class & extend properties in other classes,
    //                       which also causes issues with sharing logic between classes (via abstract and virtual classes)
    // +3 goofiness points: if we duplicate properties between classes, we can convert all other classes
    //                      to one common class (FlowLogger.LogEntry), and use it for shared logic.
    //                      For maximum goofiness, the conversion between classes happens using JSON.deserialize()
    public class LogEntry {
        // Public member variables - all other Flow classes should duplicate these public variables
        public String flowName;
        public String message;
        public String faultMessage;
        public String loggingLevelName;
        public List<String> tags;
        public List<String> topics; // TODO: deprecated, remove in a future release
        public Boolean saveLog = false;
        public DateTime timestamp;

        // Private member variables
        private LoggingLevel loggingLevel;
        private LogEntryEventBuilder logEntryEventBuilder;
        private LogEntryEvent__e logEntryEvent;

        public LogEntryEventBuilder addToLoggerBuffer() {
            if (this.logEntryEventBuilder != null) {
                return this.logEntryEventBuilder;
            }

            // Set the logging level if it's blank
            if (String.isBlank(this.loggingLevelName)) {
                if (String.isNotBlank(this.faultMessage)) {
                    this.loggingLevelName = 'ERROR';
                } else {
                    this.loggingLevelName = 'DEBUG';
                }
            }

            this.loggingLevel = Logger.getLoggingLevel(this.loggingLevelName);
            this.logEntryEventBuilder = Logger.newEntry(this.loggingLevel, this.message).setTopics(this.topics).addTags(this.tags);
            this.logEntryEvent = logEntryEventBuilder.getLogEntryEvent();

            if (this.logEntryEventBuilder.shouldSave() == false) {
                return this.logEntryEventBuilder;
            }

            this.logEntryEvent.OriginLocation__c = this.flowName;
            this.logEntryEvent.OriginType__c = 'Flow';
            this.logEntryEvent.Timestamp__c = this.timestamp;

            if (String.isNotBlank(this.faultMessage)) {
                this.logEntryEvent.ExceptionMessage__c = this.faultMessage;
                this.logEntryEvent.ExceptionType__c = 'Flow.FaultError';
            }

            return this.logEntryEventBuilder;
        }
    }

    // Static methods
    public static List<String> addEntries(List<LogEntry> flowEntries) {
        Boolean saveLog = false;
        for (LogEntry flowEntry : flowEntries) {
            flowEntry.addToLoggerBuffer();

            if (flowEntry.saveLog == true) {
                saveLog = flowEntry.saveLog;
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
        for (Integer i = 0; i < flowEntries.size(); i++) {
            transactionIds.add(Logger.getTransactionId());
        }
        return transactionIds;
    }
}
