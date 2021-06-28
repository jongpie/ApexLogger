//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c <= :System.today()`
 * @see LogBatchPurgeScheduler
 */
global with sharing class LogBatchPurger implements Database.Batchable<SObject>, Database.Stateful {
    private final Boolean isSystemDebuggingEnabled;

    private SObjectType currentSObjectType;
    private String originalTransactionId;
    private Integer totalProcessedRecords;

    private class LogBatchPurgerException extends Exception {
    }

    global LogBatchPurger() {
        this.isSystemDebuggingEnabled = Logger.getUserSettings()?.EnableSystemMessages__c == true;
        this.totalProcessedRecords = 0;
    }

    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        if (!Schema.Log__c.SObjectType.getDescribe().isDeletable()) {
            throw new LogBatchPurgerException('User does not have access to delete logs');
        }

        // Each batchable method runs in a separate transaction,
        // so store the first transaction ID to later relate the other transactions
        this.originalTransactionId = Logger.getTransactionId();

        if ( this.currentSObjectType == null) {
             this.currentSObjectType = this.getInitialSObjectType();
        }

        if (this.isSystemDebuggingEnabled) {
            Logger.info('Starting LogBatchPurger job for SObject type: ' + this.currentSObjectType);
            Logger.saveLog();
        }

        return this.getQueryLocator(this.currentSObjectType);
    }

    global void execute(Database.BatchableContext batchableContext, List<SObject> loggerRecords) {
        if (!Schema.Log__c.SObjectType.getDescribe().isDeletable()) {
            throw new LogBatchPurgerException('User does not have access to delete logs');
        }

        try {
            this.totalProcessedRecords += loggerRecords.size();
            this.hardDelete(loggerRecords);
        } catch (Exception apexException) {
            if (this.isSystemDebuggingEnabled) {
                Logger.error('Error deleting logs', apexException);
            }
        } finally {
            Logger.saveLog();
        }
    }

    global void finish(Database.BatchableContext batchableContext) {
        Id nextBatchJobId;
        if (this.currentSObjectType != Schema.Log__c.SObjectType) {
            nextBatchJobId = Database.executeBatch(new LogBatchPurger());
        }

        if (this.isSystemDebuggingEnabled) {
            Logger.setParentLogTransactionId(this.originalTransactionId);
            Logger.info(
                new LogMessage('Finished LogBatchPurger job for {0}, {1} total log records processed', this.currentSObjectType, this.totalProcessedRecords)
            );
            if (nextBatchJobId != null) {
                Logger.info(new LogMessage('Starting a new instance of LogBatchPurger job, job ID is: {0}', nextBatchJobId));
            }
            Logger.saveLog();
        }
    }

    private void hardDelete(List<SObject> records) {
        // normally this would be an anti-pattern since most DML operations
        // are a no-op with an empty list - but emptyRecycleBin throws
        // for empty lists!
        if (!records.isEmpty()) {
            delete records;
            Database.emptyRecycleBin(records);
        }
    }

    private Schema.SObjectType getInitialSObjectType() {
        Schema.SObjectType initialSObjectType;
        if (this.getLogEntryTagCount() > 0) {
            initialSObjectType = Schema.LogEntryTag__c.SObjectType;
        } else if (this.getLogEntryCount() > 0) {
            initialSObjectType = Schema.LogEntry__c.SObjectType;
        } else {
            initialSObjectType = Schema.Log__c.SObjectType;
        }
        return initialSObjectType;
    }

    private Integer getLogEntryTagCount() {
        return [
            SELECT COUNT()
            FROM LogEntryTag__c
            WHERE LogEntry__r.Log__r.LogRetentionDate__c <= :System.today() AND LogEntry__r.Log__r.LogRetentionDate__c != NULL
        ];
    }

    private Integer getLogEntryCount() {
        return [SELECT COUNT() FROM LogEntry__c WHERE Log__r.LogRetentionDate__c <= :System.today() AND Log__r.LogRetentionDate__c != NULL];
    }

    private Integer getLogCount() {
        return [SELECT COUNT() FROM Log__c WHERE LogRetentionDate__c <= :System.today() AND LogRetentionDate__c != NULL];
    }

    /**
     * @description Determines which of the 3 Logger objects (LogEntryTag__c, LogEntry__c or Log__c) should be deleted next.
     *              Records for each SObject type are deleted in separate instances of the LogBatchPurger job,
     *              starting with the lowest-level object (LogEntryTag__c). This helps to avoid running into DML limits that occurred
     *              when this job tried to delete records in multiple SObject types within 1 job
     * @return      The instance of Database.QueryLocator for the lowest-level Logger object
     */
    private Database.QueryLocator getQueryLocator(Schema.SObjectType sobjectType) {
        Database.QueryLocator queryLocator;

        switch on sobjectType.newSObject() {
            when LogEntryTag__c logEntryTag {
                queryLocator = Database.getQueryLocator(
                    [
                        SELECT Id
                        FROM LogEntryTag__c
                        WHERE LogEntry__r.Log__r.LogRetentionDate__c <= :System.today() AND LogEntry__r.Log__r.LogRetentionDate__c != NULL
                    ]
                );
            }
            when LogEntry__c logEntry {
                queryLocator = Database.getQueryLocator(
                    [SELECT Id FROM LogEntry__c WHERE Log__r.LogRetentionDate__c <= :System.today() AND Log__r.LogRetentionDate__c != NULL]
                );
            }
            when Log__c log {
                queryLocator = Database.getQueryLocator([SELECT Id FROM Log__c WHERE LogRetentionDate__c <= :System.today() AND LogRetentionDate__c != NULL]);
            }
        }

        return queryLocator;
    }
}
