---
layout: default
---

## LogEntryFieldSetPicklist class

Dynamically returns `LogEntry__c` field sets in App Builder when configuring the component RelatedLogEntries

---

### Methods

#### `getDefaultValue()` → `VisualEditor.DataRow`

Returns a default value of null - admins must select a field set within App Builder

##### Return

**Type**

VisualEditor.DataRow

**Description**

null (no default value)

#### `getValues()` → `VisualEditor.DynamicPickListRows`

Returns the list of fields sets on `LogEntry__c`, allowing admins to specify any field set for each instance of the `RelatedLogEntries` component

##### Return

**Type**

VisualEditor.DynamicPickListRows

**Description**

The list of field sets on the LogEntry\_\_c object

---
