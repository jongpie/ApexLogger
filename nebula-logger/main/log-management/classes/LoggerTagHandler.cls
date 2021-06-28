//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LoggerTag__c` object
 */
public without sharing class LoggerTagHandler extends LoggerSObjectHandler {
    private static final Map<String, Log__c> TRANSACTION_ID_TO_LOG = new Map<String, Log__c>();

    // Trigger-based variables - tests can override these with mock objects
    @testVisible
    private List<LoggerTag__c> loggerTags {
        get {
            return (List<LoggerTag__c>) this.triggerNew;
        }
    }

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override SObjectType getSObjectType() {
        return Schema.LoggerTag__c.SObjectType;
    }

    /**
     * @description Runs the trigger handler's logic for the `LoggerTag__c` custom object
     */
    public override void execute() {
        if (this.isEnabled() == false) {
            return;
        }

        switch on this.triggerOperationType {
            when BEFORE_INSERT, BEFORE_UPDATE {
                this.setUniqueIdField();
            }
        }

        this.executePlugins();
    }

    private void setUniqueIdField() {
        for (LoggerTag__c loggerTag : this.loggerTags) {
            loggerTag.UniqueId__c = loggerTag.Name;
        }

    }
}
