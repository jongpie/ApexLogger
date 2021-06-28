//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LogEntryTag__c` object
 */
public without sharing class LogEntryTagHandler extends LoggerSObjectHandler {
    private static final Map<String, Log__c> TRANSACTION_ID_TO_LOG = new Map<String, Log__c>();

    // Trigger-based variables - tests can override these with mock objects
    @testVisible
    private List<LogEntryTag__c> logEntryTags {
        get {
            return (List<LogEntryTag__c>) this.triggerNew;
        }
    }

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override SObjectType getSObjectType() {
        return Schema.LogEntryTag__c.SObjectType;
    }

    /**
     * @description Runs the trigger handler's logic for the `LogEntryTag__c` custom object
     */
    public override void execute() {
        if (this.isEnabled() == false) {
            return;
        }

        switch on this.triggerOperationType {
            when BEFORE_INSERT, BEFORE_UPDATE {
                this.setUniqueIdField();
                this.setLogField();
            }
        }

        this.executePlugins();
    }

    private void setUniqueIdField() {
        for (LogEntryTag__c logEntryTag : this.logEntryTags) {
            logEntryTag.UniqueId__c = logEntryTag.LogEntry__c + '' + logEntryTag.Tag__c;
        }
    }

    private void setLogField() {
        // Auto-set the Log__c lookup field - this lets the LogEntryTag__c record show as related to both the LogEntry__c and Log__c
        List<Id> logEntryIds = new List<Id>();
        for (LogEntryTag__c logEntryTag : this.logEntryTags) {
            logEntryIds.add(logEntryTag.LogEntry__c);
        }
        Map<Id, LogEntry__c> logEntryIdToRecord = new Map<Id, LogEntry__c>([SELECT Id, Log__c FROM LogEntry__c WHERE Id IN :logEntryIds]);

        for (LogEntryTag__c logEntryTag : this.logEntryTags) {
            logEntryTag.Log__c = logEntryIdToRecord.get(logEntryTag.LogEntry__c).Log__c;
        }
    }
}
