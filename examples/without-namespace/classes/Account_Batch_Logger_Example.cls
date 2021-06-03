// An example trigger to demo logging Account records, using all trigger operations
// This , you should use a trigger handler framework, but this trigger is just for demo purposes
public with sharing class Account_Batch_Logger_Example implements Database.Batchable<SObject>, Database.Stateful {
    private String originalTransactionId;

    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        // Each batchable method runs in a separate transaction
        // ...so store the first transaction ID to later relate the other transactions
        this.originalTransactionId = Logger.getTransactionId();

        Logger.info('Starting Account_Batch_Logger_Example');
        Logger.saveLog();

        // Just as an example, query 100 accounts
        return Database.getQueryLocator([SELECT Id, Name, OwnerId, Owner.Name, Type FROM Account LIMIT 100]);
    }

    public void execute(Database.BatchableContext batchableContext, List<Account> scope) {
        // One-time call (per transaction) to set the parent log
        Logger.fine('this.originalTransactionId==' + this.originalTransactionId);
        Logger.setParentLogTransactionId(this.originalTransactionId);

        for (Account account : scope) {
            // TODO add your batch job's logic

            // Then log the result
            Logger.info('Processed an account record', account);
        }

        Logger.debug('Saving account records', scope);
        update scope;

        Logger.saveLog();
    }

    public void finish(Database.BatchableContext batchableContext) {
        // The finish method runs in yet-another transaction, so set the parent log again
        Logger.fine('this.originalTransactionId==' + this.originalTransactionId);
        Logger.setParentLogTransactionId(this.originalTransactionId);

        Logger.info('Finishing running Account_Batch_Logger_Example');
        Logger.saveLog();
    }
}