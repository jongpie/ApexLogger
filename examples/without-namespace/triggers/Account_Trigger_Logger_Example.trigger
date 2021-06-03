// An example trigger to demo logging Account records, using all trigger operations
// Normally, you should use a trigger handler framework, but this trigger is just for demo purposes
trigger Account_Trigger_Logger_Example on Account (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    // Get the trigger's list of records
    List<Account> triggerRecords = Trigger.new != null ? Trigger.new : Trigger.old;

    // Log using an instance of LogMessage for more complex strings
    String messageTemplate = 'Example log entry from Account trigger, processing {0} records';
    LogMessage logMessage = new LogMessage(messageTemplate, triggerRecords.size());
    Logger.fine(logMessage, triggerRecords);

    for (Account account : triggerRecords) {
        // Log a string for simpler log entries
        Logger.fine('Here\'s an entry for a specific Account record', account);
    }

    // Save any pending log entries
    Logger.saveLog();
}