//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Manages setting fields on `Log__c` before insert & before update
 */
public without sharing class LogHandler extends LoggerSObjectHandler {
    @testVisible
    private static Map<String, LogStatus__mdt> logStatusByName = loadActiveLogStatuses();

    private static Map<String, LogStatus__mdt> loadActiveLogStatuses() {
        Map<String, LogStatus__mdt> logStatusByName = new Map<String, LogStatus__mdt>();
        for (LogStatus__mdt logStatus : LogStatus__mdt.getAll().values()) {
            if (logStatus.IsActive__c == true) {
                logStatusByName.put(logStatus.MasterLabel, logStatus);
            }
        }

        return logStatusByName;
    }

    // Trigger-based variables - tests can override these with mock objects
    @testVisible
    private List<Log__c> logs {
        get {
            return (List<Log__c>) this.triggerNew;
        }
    }

    @testVisible
    private Map<Id, Log__c> oldLogsById {
        get {
            return (Map<Id, Log__c>) this.triggerOldMap;
        }
    }

    public LogHandler() {
    }

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override SObjectType getSObjectType() {
        return Schema.Log__c.SObjectType;
    }

    /**
     * @description Runs the trigger handler's logic for the `Log__c` custom object
     */
    public override void execute() {
        if (this.isEnabled() == false) {
            return;
        }

        switch on this.triggerOperationType {
            when BEFORE_INSERT {
                this.setOrgReleaseCycle();
                this.setClosedStatusFields();
                // The log retention date field should support being manually changed, so only auto-set it on insert
                this.setLogRetentionDate();
            }
            when BEFORE_UPDATE {
                this.setClosedStatusFields();
                // Priority logic relies on roll-up fields, so only run on update (after log entries are inserted)
                this.setPriority();
            }
            when AFTER_INSERT {
                this.shareLogsWithLoggingUsers();
            }
        }

        // Run any plugins configured in the LoggerSObjectHandlerPlugin__mdt custom metadata type
        this.executePlugins();
    }

    private void setOrgReleaseCycle() {
        // Currently, there doesn't seem to be a way within Apex or api.status.salesforce.com...
        // ...to know if your org is on a preview instance or non-preview instance
        // So, that unfortunately leaves hardcoding the instances for now
        // Source: https://help.salesforce.com/articleView?id=000357271&type=1&mode=1
        // And no need for this to be static since it's only used internally for BEFORE_INSERT context
        String apiVersion = JSON.serialize(new User(Id = UserInfo.getUserId())).substringAfter('/data/').substringBefore('/sobjects/User');
        Set<String> previewInstances = new Set<String>(LoggerParameter.Handler.getStringList('LogHandler_PreviewInstances_' + apiVersion, new List<String>()));
        Set<String> nonPreviewInstances = new Set<String>(
            LoggerParameter.Handler.getStringList('LogHandler_NonPreviewInstances_' + apiVersion, new List<String>())
        );

        String releaseCycle;

        for (Log__c log : this.logs) {
            if (
                log.OrganizationInstanceName__c == 'Production' || nonPreviewInstances != null && nonPreviewInstances.contains(log.OrganizationInstanceName__c)
            ) {
                releaseCycle = 'Non-Preview Instance';
            } else if (previewInstances != null && previewInstances.contains(log.OrganizationInstanceName__c)) {
                releaseCycle = 'Preview Instance';
            }

            // Use 'Unknown' as the default for private instances and situations where the hardcoded sets above are missing some values
            log.OrganizationInstanceReleaseCycle__c = String.isNotBlank(releaseCycle) ? releaseCycle : 'Unknown';
        }
    }

    private void setClosedStatusFields() {
        for (Log__c log : this.logs) {
            // Determine if the status is considered closed (based on `LogStatus__mdt` custom metadata)
            LogStatus__mdt logStatus = logStatusByName.get(log.Status__c);
            if (logStatus != null) {
                log.IsClosed__c = logStatus.IsClosed__c;
                log.IsResolved__c = logStatus.IsResolved__c;
            }

            // Now set the Closed By & Date fields based on IsClosed
            if (log.IsClosed__c == false) {
                log.ClosedBy__c = null;
                log.ClosedDate__c = null;
            } else {
                log.ClosedBy__c = log.ClosedBy__c == null ? UserInfo.getUserId() : log.ClosedBy__c;
                log.ClosedDate__c = log.ClosedDate__c == null ? System.now() : log.ClosedDate__c;
            }
        }
    }

    private void setLogRetentionDate() {
        for (Log__c log : this.logs) {
            // If the retention date has already been populated, leave it as-is
            if (log.LogRetentionDate__c != null) {
                continue;
            }

            // Load the logging user's settings
            User loggingUser = new User(Id = log.LoggedBy__c, ProfileId = log.ProfileId__c);
            LoggerSettings__c loggingUserSettings = Logger.getUserSettings(loggingUser);
            Integer daysToRetainLog = Integer.valueOf(loggingUserSettings.DefaultNumberOfDaysToRetainLogs__c);

            // When loggerSettings.DefaultNumberOfDaysToRetainLogs__c is null, assume that the log should be kept forever,
            // ...and set the retention date to null so that LogBatchPurger filters out/ignores the record
            log.LogRetentionDate__c = daysToRetainLog == null ? null : System.today().addDays(daysToRetainLog);
        }
    }

    private void setPriority() {
        List<PicklistEntry> picklistEntries = Schema.Log__c.Priority__c.getDescribe().getPicklistValues();

        // 3 assumptions
        //   1. Assume that that there will always be 3+ picklist values for the Priority__c field (out of the box, the values are: High, Medium, Low)
        //   2. Assume that not everyone will want those exact values, so dynamiclly get picklist entries (e.g., some orgs may instead use Critical, High, Medium, Low)
        //   3. Assume that the picklist entries are sorted in order of priority (not alphabetically, etc.)
        final String FIRST_PRIORITY = picklistEntries.get(0).getValue();
        final String SECOND_PRIORITY = picklistEntries.get(1).getValue();

        for (Log__c log : this.logs) {
            Log__c oldLog = this.oldLogsById.get(log.Id);

            if (log.TotalERRORLogEntries__c != oldLog.TotalERRORLogEntries__c && log.TotalERRORLogEntries__c > 0) {
                log.Priority__c = FIRST_PRIORITY;
            } else if (log.TotalWARNLogEntries__c != oldLog.TotalWARNLogEntries__c && log.TotalWARNLogEntries__c > 0) {
                log.Priority__c = SECOND_PRIORITY;
            }
        }
    }

    private void shareLogsWithLoggingUsers() {
        // For each log record, share the record with the user that created the log (Log__c.LoggedBy__c)
        List<Log__Share> logShares = new List<Log__Share>();
        for (Log__c log : this.logs) {
            // Load the logging user's settings
            User loggingUser = new User(Id = log.LoggedBy__c, ProfileId = log.ProfileId__c);
            LoggerSettings__c loggingUserSettings = Logger.getUserSettings(loggingUser);

            // Ignore blank and unsupported values
            if (loggingUserSettings.DefaultLogShareAccessLevel__c != 'Read' && loggingUserSettings.DefaultLogShareAccessLevel__c != 'Edit') {
                continue;
            }

            Log__Share logShare = new Log__Share(
                AccessLevel = loggingUserSettings.DefaultLogShareAccessLevel__c,
                ParentId = log.Id,
                RowCause = Schema.Log__Share.RowCause.LoggedByUser__c,
                UserOrGroupId = log.LoggedBy__c
            );
            logShares.add(logShare);
        }
        List<Database.SaveResult> saveResults = Database.insert(logShares, false);
        System.debug('saveResults==' + saveResults);
    }
}
