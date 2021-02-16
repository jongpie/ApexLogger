## FlowRecordLogEntry class

Handles adding new log entryies in Flow for a particular SObject record

### Related

[FlowLogEntry](/logger-engine/FlowLogEntry.md)


[Logger](/logger-engine/Logger.md)


LogEntryBuilder

---
### Properties

#### `flowName` → `String`

The name of the Flow creating the log entry. Due to Salesforce limitations, this cannot be automatically determined.

#### `loggingLevelName` → `String`

Optionally specify a logging level. The default is 'DEBUG'

#### `message` → `String`

The message to log.

#### `record` → `SObject`

The record to relate to this log entry. The record's JSON will be automatically added to the entry.

#### `saveLog` → `Boolean`

Optionally choose to save any pending log entries.

#### `topics` → `List<String>`

Optionally provide a list of topics to dynamically assign to the log entry.

---
### Methods
#### `addFlowRecordEntries(List<FlowRecordLogEntry> flowRecordLogEntries)` → `List<String>`

 addFlowRecordEntries description

##### Parameters
|Param|Description|
|-----|-----------|
|`flowRecordLogEntries` |  The list of FlowRecordLogEntry instances to save |

##### Return

**Type**

List<String>

**Description**

The current transaction's ID (based on Logger.getTransactionId())

---
