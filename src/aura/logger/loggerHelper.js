({
    addEntry : function(component, event) {
        var timestamp = new Date().toISOString();

        var logEntries = component.get('v.logEntries');
        var args = event.getParam('arguments');
        var logEntry = {
            componentName:  args.component.getName(),
            message:        args.message,
            error:          args.error,
            originLocation: args.originLocation,
            topics:         args.topics,
            timestamp:      timestamp
            //componentName:  component.getName()
        };
        console.log(logEntry);
        logEntries.push(logEntry);
        component.set('v.logEntries', logEntries);
    },
    save : function(component, event) {
        var logEntries = component.get('v.logEntries');

        if(logEntries == null) return;

        var action = component.get('c.saveLightningEntries');
        action.setParams({
            logEntriesJson : JSON.stringify(logEntries)
        });
        action.setCallback(this, function(response) {
            if(response.getState() === 'SUCCESS') {
                component.set('v.logEntries', null);
            } else if(response.getState() === 'ERROR') {
                // TODO this.processCallbackErrors(response);
            }
        });
        $A.enqueueAction(action);
    }
})