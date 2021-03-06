//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Abstract class used by trigger handlers for shared logic
 */
public abstract class LoggerSObjectHandler {
    private static Map<SObjectType, LoggerSObjectHandler__mdt> configurationBySObjectType;
    private static Map<SObjectType, List<LoggerSObjectHandlerPlugin__mdt>> pluginsBySObjectType;

    static {
        // When using CMDT's getAll(), it does not return relationship fields for EntityDefinition fields or child CMDT objects...
        // ... so instead query the LoggerSObjectHandler__mdt CMDT object
        List<LoggerSObjectHandler__mdt> configurations = [
            SELECT
                Id,
                IsEnabled__c,
                SObjectType__r.QualifiedApiName,
                (
                    SELECT Id, PluginType__c, PluginApiName__c
                    FROM LoggerSObjectHandlerPlugins__r
                    WHERE IsEnabled__c = TRUE
                    ORDER BY ExecutionOrder__c NULLS LAST, DeveloperName
                )
            FROM LoggerSObjectHandler__mdt
        ];

        configurationBySObjectType = new Map<SObjectType, LoggerSObjectHandler__mdt>();
        pluginsBySObjectType = new Map<SObjectType, List<LoggerSObjectHandlerPlugin__mdt>>();
        for (LoggerSObjectHandler__mdt config : configurations) {
            // CMDT entity-definition relationship fields are weird, so skip some headaches by copying the Qualified API name
            config.SObjectType__c = config.SObjectType__r.QualifiedApiName;

            // Schema.getGlobalDescribe() is the worst, so don't use it
            SObjectType sobjectType = ((SObject) Type.forName(config.SObjectType__c).newInstance()).getSObjectType();

            configurationBySObjectType.put(sobjectType, config);
            pluginsBySObjectType.put(sobjectType, config?.LoggerSObjectHandlerPlugins__r);
        }

        if (Test.isRunningTest() == true) {
            // Test shouldn't rely on the actual CMDT rules in the org - clear the loaded values, and defaults will be used
            configurationBySObjectType.clear();
            pluginsBySObjectType.clear();
        }
    }

    // Private static testVisible methods
    @testVisible
    private static void setMockConfiguration(Schema.SObjectType sobjectType, LoggerSObjectHandler__mdt configuration) {
        configurationBySObjectType.put(sobjectType, configuration);
    }

    @testVisible
    private static void setMockPlugin(Schema.SObjectType sobjectType, LoggerSObjectHandlerPlugin__mdt plugin) {
        List<LoggerSObjectHandlerPlugin__mdt> plugins = pluginsBySObjectType.get(sobjectType);
        if (plugins == null) {
            plugins = new List<LoggerSObjectHandlerPlugin__mdt>();
        }
        plugins.add(plugin);
        pluginsBySObjectType.put(sobjectType, plugins);
    }

    @testVisible
    protected TriggerOperation triggerOperationType;
    @testVisible
    protected List<SObject> triggerNew;
    @testVisible
    protected Map<Id, SObject> triggerNewMap;
    @testVisible
    protected List<SObject> triggerOld;
    @testVisible
    protected Map<Id, SObject> triggerOldMap;

    private LoggerSObjectHandler__mdt handlerConfiguration;
    private List<LoggerSObjectHandlerPlugin__mdt> plugins;

    public LoggerSObjectHandler() {
        this.setConfigurations();

        if (this.handlerConfiguration.IsEnabled__c == true) {
            this.triggerOperationType = Trigger.operationType;
            this.triggerNew = Trigger.new;
            this.triggerNewMap = Trigger.newMap;
            this.triggerOld = Trigger.old;
            this.triggerOldMap = Trigger.oldMap;
        }
    }

    /**
     * @description Returns the SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public abstract SObjectType getSObjectType();

    /**
     * @description Runs the handler class's logic
     */
    public abstract void execute();

    /**
     * @description Indicates if the current SObject Handler is enabled, based on `LoggerSObjectHandler__mdt.IsEnabled__c`
     * @return   The `Boolean` value (`true` == enabled, `false` == disabled)
     */
    protected Boolean isEnabled() {
        return this.handlerConfiguration.IsEnabled__c;
    }

    protected void executePlugins() {
        if (this.plugins == null || this.plugins.isEmpty() == true) {
            return;
        }

        for (LoggerSObjectHandlerPlugin__mdt pluginConfiguration : this.plugins) {
            switch on pluginConfiguration.PluginType__c {
                when 'Apex' {
                    this.executeApexPlugin(pluginConfiguration.PluginApiName__c);
                }
                when 'Flow' {
                    this.executeFlowPlugin(pluginConfiguration.PluginApiName__c);
                }
            }
        }
    }

    private void setConfigurations() {
        this.handlerConfiguration = configurationBySObjectType.get(this.getSObjectType());
        this.plugins = pluginsBySObjectType.get(this.getSObjectType());

        if (this.handlerConfiguration == null) {
            // If no config exists in the org, then load some in-memory defaults
            this.handlerConfiguration = new LoggerSObjectHandler__mdt(IsEnabled__c = true, SObjectType__c = this.getSObjectType().getDescribe().getName());

            configurationBySObjectType.put(this.getSObjectType(), this.handlerConfiguration);
        }
    }

    private void executeApexPlugin(String apexClassName) {
        LoggerSObjectHandlerPlugin apexPlugin = (LoggerSObjectHandlerPlugin) Type.forName(apexClassName).newInstance();
        apexPlugin.execute(this.triggerOperationType, this.triggerNew, this.triggerNewMap, this.triggerOld, this.triggerOldMap);
    }

    private void executeFlowPlugin(String flowApiName) {
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('triggerOperationType', this.triggerOperationType?.name());
        flowInputs.put('triggerNew', this.triggerNew);
        flowInputs.put('triggerOld', this.triggerOld);

        Flow.Interview flowPlugin = Flow.Interview.createInterview(flowApiName, flowInputs);
        flowPlugin.start();

        List<SObject> updatedTriggerNew = (List<SObject>) flowPlugin.getVariableValue('updatedTriggerNew');
        if (updatedTriggerNew != null && updatedTriggerNew.size() == this.triggerNew.size()) {
            this.triggerNew = updatedTriggerNew;
        }
    }
}
