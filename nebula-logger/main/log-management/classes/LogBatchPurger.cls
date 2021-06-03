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
    private String originalTransactionId;
    private Integer totalProcessedRecords = 0;

    private class LogBatchPurgerException extends Exception {
    }

    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        if (!Schema.Log__c.SObjectType.getDescribe().isDeletable()) {
            throw new LogBatchPurgerException('User does not have access to delete logs');
        }

        // Each batchable method runs in a separate transaction
        // ...so store the first transaction ID to later relate the other transactions
        this.originalTransactionId = Logger.getTransactionId();

        if (Logger.getUserSettings().EnableSystemMessages__c == true) {
            Logger.info('Starting LogBatchPurger job');
            Logger.saveLog();
        }

        return Database.getQueryLocator(
            [SELECT Id, (SELECT Id FROM LogEntries__r) FROM Log__c WHERE LogRetentionDate__c <= :System.today() AND LogRetentionDate__c != NULL]
        );
    }

    global void execute(Database.BatchableContext batchableContext, List<Log__c> logsToDelete) {
        if (!Schema.Log__c.SObjectType.getDescribe().isDeletable()) {
            throw new LogBatchPurgerException('User does not have access to delete logs');
        }

        this.totalProcessedRecords += logsToDelete.size();

        try {
            if (Logger.getUserSettings().EnableSystemMessages__c == true) {
                Logger.setParentLogTransactionId(this.originalTransactionId);
                Logger.info(new LogMessage('Starting deletion of {0} records', logsToDelete.size()));
            }

            // Delete the child log entries first
            List<LogEntry__c> logEntriesToDelete = [SELECT Id FROM LogEntry__c WHERE Log__c IN :logsToDelete];
            delete logEntriesToDelete;
            Database.emptyRecycleBin(logEntriesToDelete);

            // Now delete the parent logs
            delete logsToDelete;
            Database.emptyRecycleBin(logsToDelete);
        } catch (Exception apexException) {
            if (Logger.getUserSettings().EnableSystemMessages__c == true) {
                Logger.error('Error deleting logs', apexException);
            }
        } finally {
            Logger.saveLog();
        }
    }

    global void finish(Database.BatchableContext batchableContext) {
        if (Logger.getUserSettings().EnableSystemMessages__c == true) {
            Logger.setParentLogTransactionId(this.originalTransactionId);
            Logger.info(new LogMessage('Finished LogBatchPurger job, {0} total log records processed', this.totalProcessedRecords));
            Logger.saveLog();
        }
    }
}
