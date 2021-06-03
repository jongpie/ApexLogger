---
layout: default
---

## FlowLogEntry class

Handles adding new log entries in Flow

### Related

[FlowRecordLogEntry](FlowRecordLogEntry)

[Logger](Logger)

[LogEntryEventBuilder](LogEntryEventBuilder)

---

### Properties

#### `faultMessage` → `String`

Optionally log a Flow fault error message

#### `flowName` → `String`

The name of the Flow creating the log entry. Due to Salesforce limitations, this cannot be automatically determined.

#### `loggingLevelName` → `String`

Optionally specify a logging level - the default is 'DEBUG'

#### `message` → `String`

The message to log.

#### `recordId` → `Id`

Optionally relate the log entry to a particular record ID

#### `saveLog` → `Boolean`

Optionally choose to save any pending log entries.

#### `topics` → `List<String>`

Optionally provide a list of topics to dynamically assign to the log entry

---

### Methods

#### `addFlowEntries(List<FlowLogEntry> flowLogEntries)` → `List<String>`

addFlowEntries description

##### Parameters

| Param            | Description                                |
| ---------------- | ------------------------------------------ |
| `flowLogEntries` | The list of FlowLogEntry instances to save |

##### Return

**Type**

List<String>

**Description**

The current transaction's ID (based on `Logger.getTransactionId()`)

---
