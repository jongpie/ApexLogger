---
layout: default
---

## RelatedLogEntriesController class

Controller class for the component RelatedLogEntries

---

### Methods

#### `getQueryResult(Id recordId,String fieldSetName,Integer rowLimit,Integer rowOffset,String sortByFieldName,String sortDirection,String search)` → `LogEntryQueryResult`

Used by the component relatedLogEntries to get log entries for a particular record (based on record ID)

##### Parameters

| Param             | Description                                                      |
| ----------------- | ---------------------------------------------------------------- |
| `recordId`        | Used to filter LogEntry**c records where RecordId**c == recordId |
| `fieldSetName`    | The API/developer name of the field set                          |
| `rowLimit`        | The max number of rows to query                                  |
| `rowOffset`       | Reserved for future use                                          |
| `sortByFieldName` | The field to sort by                                             |
| `sortDirection`   | The direction to sort by (asc or desc))                          |
| `search`          | An optional search term to filter by                             |

##### Return

**Type**

LogEntryQueryResult

**Description**

The instance of LogEntryQueryResult, containing matching records and metadata

---

### Inner Classes

#### RelatedLogEntriesController.FieldMetadata class

---

##### Properties

###### `fieldName` → `String`

###### `isNameField` → `Boolean`

###### `label` → `String`

###### `lookupDisplayFieldName` → `String`

###### `relationshipName` → `String`

###### `sortable` → `Boolean`

###### `type` → `String`

---

#### RelatedLogEntriesController.FieldSetMetadata class

---

##### Properties

###### `fields` → `List<FieldMetadata>`

###### `label` → `String`

###### `name` → `String`

---

#### RelatedLogEntriesController.LogEntryQueryResult class

---

##### Properties

###### `fieldSet` → `FieldSetMetadata`

###### `isAccessible` → `Boolean`

###### `label` → `String`

###### `labelPlural` → `String`

###### `records` → `List<LogEntry__c>`

###### `tabIcon` → `String`

###### `totalLogEntriesCount` → `Integer`

---
