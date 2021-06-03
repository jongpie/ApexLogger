//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Dynamically returns `LogEntry__c` field sets in App Builder when configuring the component RelatedLogEntries
 */
public without sharing class LogEntryFieldSetPicklist extends VisualEditor.DynamicPickList {
    /**
     * Returns a default value of null - admins must select a field set within App Builder
     * @return   null (no default value)
     */
    public override VisualEditor.DataRow getDefaultValue() {
        return null;
    }

    /**
     * @description Returns the list of fields sets on `LogEntry__c`, allowing admins to specify any
     *   field set for each instance of the `RelatedLogEntries` component
     * @return   The list of field sets on the LogEntry__c object
     */
    public override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows picklistRows = new VisualEditor.DynamicPickListRows();

        List<FieldSet> fieldSets = Schema.SObjectType.LogEntry__c.fieldSets.getMap().values();
        for (FieldSet fieldSet : fieldSets) {
            String namespacePrefix = String.isEmpty(fieldSet.getNameSpace()) ? '' : fieldSet.getNameSpace() + '__';

            VisualEditor.DataRow picklistRow = new VisualEditor.DataRow(fieldSet.getLabel(), namespacePrefix + fieldSet.getName());
            picklistRows.addRow(picklistRow);
        }

        return picklistRows;
    }
}
