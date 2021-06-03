//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

// An example queueable job that will run several chained instances
// Each instance uses the parentLogTransactionId to relate its log back to the original instance's log
public with sharing class Account_Queueable_Logger_Example implements Queueable {
    private Integer numberOfJobsToChain;
    private String parentLogTransactionId;

    private List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();

    public Account_Queueable_Logger_Example(Integer numberOfJobsToChain) {
        this(numberOfJobsToChain, null);
    }

    public Account_Queueable_Logger_Example(Integer numberOfJobsToChain, String parentLogTransactionId) {
        this.numberOfJobsToChain = numberOfJobsToChain;
        this.parentLogTransactionId = parentLogTransactionId;
    }

    public void execute(System.QueueableContext queueableContext) {
        Logger.setParentLogTransactionId(this.parentLogTransactionId);

        Logger.fine('queueableContext==' + queueableContext);
        Logger.info('this.numberOfJobsToChain==' + this.numberOfJobsToChain);
        Logger.info('this.parentLogTransactionId==' + this.parentLogTransactionId);

        Logger.saveLog();

        --this.numberOfJobsToChain;
        if (this.numberOfJobsToChain > 0) {
            String parentLogTransactionId = this.parentLogTransactionId != null ? this.parentLogTransactionId : Logger.getTransactionId();
            System.enqueueJob(new Account_Queueable_Logger_Example(this.numberOfJobsToChain, parentLogTransactionId));
        }
    }
}