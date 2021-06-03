---
layout: default
---

## Logger class

The core class for logging

### Related

[LogEntryEventBuilder](LogEntryEventBuilder)

[LogMessage](LogMessage)

---

### Enums

#### SaveMethod

Enum used to control how LogEntryEvent\_\_e records are inserted

---

### Properties

#### `allOrNone` → `Boolean`

#### `records` → `List<SObject>`

---

### Methods

#### `debug(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log                         |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param            | Description                                                          |
| ---------------- | -------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResults` | The instance of `List<Database.DeleteResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResults` | The instance of `List<Database.MergeResult>` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `saveResults` | The instance of `List<Database.SaveResult>` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param             | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResults` | The instance of `List<Database.UndeleteResult>` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResults` | The instance of `List<Database.UpsertResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `recordId`   | The record ID of an `SObject` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `record`     | The `SObject` record to log                                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `records`    | The list of `SObject` records to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                        |
| ------------ | -------------------------------------------------- |
| `message`    | The string to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param            | Description                                        |
| ---------------- | -------------------------------------------------- |
| `message`        | The string to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `deleteResults` | The list of `Database.DeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                         |
| -------------- | --------------------------------------------------- |
| `message`      | The string to use to set the entry's message field  |
| `mergeResults` | The list of `Database.MergeResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `saveResults` | The list of `Database.SaveResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `message`         | The string to use to set the entry's message field     |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `upsertResults` | The list of `Database.UpsertResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param      | Description                                        |
| ---------- | -------------------------------------------------- |
| `message`  | The string to use to set the entry's message field |
| `recordId` | The record ID of an `SObject` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `record`  | The `SObject` record to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `records` | The list of `SObject` records to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log                         |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param            | Description                                                          |
| ---------------- | -------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResults` | The instance of `List<Database.DeleteResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResults` | The instance of `List<Database.MergeResult>` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `saveResults` | The instance of `List<Database.SaveResult>` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param             | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResults` | The instance of `List<Database.UndeleteResult>` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResults` | The instance of `List<Database.UpsertResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `apexException` | The instance of `Exception` to log                                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Id recordId, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `recordId`      | The record ID of an `SObject` to log                                 |
| `apexException` | The instance of `Exception` to log                                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `recordId`   | The record ID of an `SObject` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, SObject record, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `record`        | The `SObject` record to log                                          |
| `apexException` | The instance of `Exception` to log                                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `record`     | The `SObject` record to log                                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<SObject> records, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `records`       | The list of `SObject` records to log                                 |
| `apexException` | The instance of `Exception` to log                                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `records`    | The list of `SObject` records to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                        |
| ------------ | -------------------------------------------------- |
| `message`    | The string to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param            | Description                                        |
| ---------------- | -------------------------------------------------- |
| `message`        | The string to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `deleteResults` | The list of `Database.DeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                         |
| -------------- | --------------------------------------------------- |
| `message`      | The string to use to set the entry's message field  |
| `mergeResults` | The list of `Database.MergeResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `saveResults` | The list of `Database.SaveResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `message`         | The string to use to set the entry's message field     |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `upsertResults` | The list of `Database.UpsertResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                        |
| --------------- | -------------------------------------------------- |
| `message`       | The string to use to set the entry's message field |
| `apexException` | The instance of `Exception` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Id recordId, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                        |
| --------------- | -------------------------------------------------- |
| `message`       | The string to use to set the entry's message field |
| `recordId`      | The record ID of an `SObject` to log               |
| `apexException` | The instance of `Exception` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param      | Description                                        |
| ---------- | -------------------------------------------------- |
| `message`  | The string to use to set the entry's message field |
| `recordId` | The record ID of an `SObject` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, SObject record, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                        |
| --------------- | -------------------------------------------------- |
| `message`       | The string to use to set the entry's message field |
| `record`        | The `SObject` record to log                        |
| `apexException` | The instance of `Exception` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `record`  | The `SObject` record to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<SObject> records, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `records`       | The list of `SObject` records to log                                 |
| `apexException` | The instance of `Exception` to log                                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `records` | The list of `SObject` records to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.ERROR`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log                         |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param            | Description                                                          |
| ---------------- | -------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResults` | The instance of `List<Database.DeleteResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResults` | The instance of `List<Database.MergeResult>` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `saveResults` | The instance of `List<Database.SaveResult>` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param             | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResults` | The instance of `List<Database.UndeleteResult>` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResults` | The instance of `List<Database.UpsertResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `recordId`   | The record ID of an `SObject` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `record`     | The `SObject` record to log                                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `records`    | The list of `SObject` records to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param        | Description                                        |
| ------------ | -------------------------------------------------- |
| `message`    | The string to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param            | Description                                        |
| ---------------- | -------------------------------------------------- |
| `message`        | The string to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `deleteResults` | The list of `Database.DeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param          | Description                                         |
| -------------- | --------------------------------------------------- |
| `message`      | The string to use to set the entry's message field  |
| `mergeResults` | The list of `Database.MergeResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `saveResults` | The list of `Database.SaveResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `message`         | The string to use to set the entry's message field     |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `upsertResults` | The list of `Database.UpsertResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param      | Description                                        |
| ---------- | -------------------------------------------------- |
| `message`  | The string to use to set the entry's message field |
| `recordId` | The record ID of an `SObject` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `record`  | The `SObject` record to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `records` | The list of `SObject` records to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINE`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log                         |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param            | Description                                                          |
| ---------------- | -------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResults` | The instance of `List<Database.DeleteResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResults` | The instance of `List<Database.MergeResult>` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `saveResults` | The instance of `List<Database.SaveResult>` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param             | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResults` | The instance of `List<Database.UndeleteResult>` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResults` | The instance of `List<Database.UpsertResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `recordId`   | The record ID of an `SObject` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `record`     | The `SObject` record to log                                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `records`    | The list of `SObject` records to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param        | Description                                        |
| ------------ | -------------------------------------------------- |
| `message`    | The string to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param            | Description                                        |
| ---------------- | -------------------------------------------------- |
| `message`        | The string to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `deleteResults` | The list of `Database.DeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param          | Description                                         |
| -------------- | --------------------------------------------------- |
| `message`      | The string to use to set the entry's message field  |
| `mergeResults` | The list of `Database.MergeResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `saveResults` | The list of `Database.SaveResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `message`         | The string to use to set the entry's message field     |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `upsertResults` | The list of `Database.UpsertResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param      | Description                                        |
| ---------- | -------------------------------------------------- |
| `message`  | The string to use to set the entry's message field |
| `recordId` | The record ID of an `SObject` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `record`  | The `SObject` record to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `records` | The list of `SObject` records to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINER`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log                         |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param            | Description                                                          |
| ---------------- | -------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResults` | The instance of `List<Database.DeleteResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResults` | The instance of `List<Database.MergeResult>` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `saveResults` | The instance of `List<Database.SaveResult>` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param             | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResults` | The instance of `List<Database.UndeleteResult>` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResults` | The instance of `List<Database.UpsertResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `recordId`   | The record ID of an `SObject` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `record`     | The `SObject` record to log                                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `records`    | The list of `SObject` records to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                        |
| ------------ | -------------------------------------------------- |
| `message`    | The string to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param            | Description                                        |
| ---------------- | -------------------------------------------------- |
| `message`        | The string to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `deleteResults` | The list of `Database.DeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                         |
| -------------- | --------------------------------------------------- |
| `message`      | The string to use to set the entry's message field  |
| `mergeResults` | The list of `Database.MergeResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `saveResults` | The list of `Database.SaveResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `message`         | The string to use to set the entry's message field     |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `upsertResults` | The list of `Database.UpsertResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param      | Description                                        |
| ---------- | -------------------------------------------------- |
| `message`  | The string to use to set the entry's message field |
| `recordId` | The record ID of an `SObject` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `record`  | The `SObject` record to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `records` | The list of `SObject` records to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.FINEST`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `flushBuffer()` → `void`

Discards any entries that have been generated but not yet saved

#### `getBufferSize()` → `Integer`

Returns the number of entries that have been generated but not yet saved

##### Return

**Type**

Integer

**Description**

Integer

#### `getCurrentQuiddity()` → `Quiddity`

Returns the Quiddity context of the current transaction.

##### Return

**Type**

Quiddity

**Description**

Quiddity - The value of System.Request.getCurrent().getQuiddity()

#### `getLog(String logId)` → `Log__c`

Returns a Log\_\_c record from the database, using either the Salesforce ID or transaction ID

##### Parameters

| Param   | Description                                         |
| ------- | --------------------------------------------------- |
| `logId` | The Salesforce ID or TransactionId**c of the Log**c |

##### Return

**Type**

Log\_\_c

**Description**

The matching record, with all fields that the current user can access

#### `getLoggingLevel(String loggingLevelName)` → `LoggingLevel`

Converts a String to an instance of LoggingLevel

##### Parameters

| Param              | Description                              |
| ------------------ | ---------------------------------------- |
| `loggingLevelName` | The string name of an Apex logging level |

##### Return

**Type**

LoggingLevel

**Description**

The matching instance of LoggingLevel (or a default value if a match is not found)

#### `getParentLogTransactionId()` → `String`

Returns the transaction ID value that will be used to relate the current transaction's log to a parent log

##### Return

**Type**

String

**Description**

String - The parent log's transaction ID. This must be explicitly set by calling setParentLogTransactionId(String)

#### `getTransactionId()` → `String`

Returns the unique ID for a particular transaction, stored in Log**c.TransactionId**c

##### Return

**Type**

String

**Description**

String - The value of System.Request.getCurrent().getRequestId()

#### `getUserLoggingLevel()` → `LoggingLevel`

Returns the logging level for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

LoggingLevel

**Description**

LoggingLevel - The matching instance of LoggingLevel

#### `getUserSettings()` → `LoggerSettings__c`

Returns the current user's instance of `LoggerSettings__c`

##### Return

**Type**

LoggerSettings\_\_c

**Description**

LoggerSettings\_\_c - The current user's instance of the custom settings

#### `getUserSettings(User loggingUser)` → `LoggerSettings__c`

Returns the specified user's instance of `LoggerSettings__c`

##### Parameters

| Param  | Description                                                                                      |
| ------ | ------------------------------------------------------------------------------------------------ |
| `user` | The user record - at a minimum, this record should have the user Id and Profile fields populated |

##### Return

**Type**

LoggerSettings\_\_c

**Description**

LoggerSettings\_\_c - The specified user's instance of the custom settings

#### `info(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log                         |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param            | Description                                                          |
| ---------------- | -------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResults` | The instance of `List<Database.DeleteResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResults` | The instance of `List<Database.MergeResult>` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `saveResults` | The instance of `List<Database.SaveResult>` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param             | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResults` | The instance of `List<Database.UndeleteResult>` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResults` | The instance of `List<Database.UpsertResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `recordId`   | The record ID of an `SObject` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `record`     | The `SObject` record to log                                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `records`    | The list of `SObject` records to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param        | Description                                        |
| ------------ | -------------------------------------------------- |
| `message`    | The string to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param            | Description                                        |
| ---------------- | -------------------------------------------------- |
| `message`        | The string to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `deleteResults` | The list of `Database.DeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param          | Description                                         |
| -------------- | --------------------------------------------------- |
| `message`      | The string to use to set the entry's message field  |
| `mergeResults` | The list of `Database.MergeResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `saveResults` | The list of `Database.SaveResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `message`         | The string to use to set the entry's message field     |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `upsertResults` | The list of `Database.UpsertResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param      | Description                                        |
| ---------- | -------------------------------------------------- |
| `message`  | The string to use to set the entry's message field |
| `recordId` | The record ID of an `SObject` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `record`  | The `SObject` record to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `records` | The list of `SObject` records to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.INFO`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `insertRecords(List<SObject> records)` → `void`

#### `isDebugEnabled()` → `Boolean`

Indicates if logging level 'DEBUG' is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isEnabled()` → `Boolean`

Indicates if logging has been enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isEnabled(LoggingLevel loggingLevel)` → `Boolean`

Indicates if logging for the specified logging level is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Parameters

| Param          | Description                  |
| -------------- | ---------------------------- |
| `loggingLevel` | - The logging level to check |

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isErrorEnabled()` → `Boolean`

Indicates if logging level 'ERROR' is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFineEnabled()` → `Boolean`

Indicates if logging level 'FINE' is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFinerEnabled()` → `Boolean`

Indicates if logging level 'FINER' is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFinestEnabled()` → `Boolean`

Indicates if logging level 'FINEST' is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isInfoEnabled()` → `Boolean`

Indicates if logging level 'INFO' is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isSavingSuspended()` → `Boolean`

Indicates if saving has been temporarily suspended for the current transaction

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isWarnEnabled()` → `Boolean`

Indicates if logging level 'WARN' is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `meetsUserLoggingLevel(LoggingLevel logEntryLoggingLevel)` → `Boolean`

Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `newEntry(LoggingLevel loggingLevel, LogMessage logMessage, Boolean shouldSave)` → `LogEntryEventBuilder`

Adds a new instance of LogEntryEventBuilder to Logger's buffer, if shouldSave == true

##### Parameters

| Param          | Description                                                                                                                                         |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `loggingLevel` | The logging level enum value for the new entry                                                                                                      |
| `logMessage`   | The instance of LogMessage to use as the entry's message                                                                                            |
| `shouldSave`   | Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of LogEntryEventBuilder

#### `newEntry(LoggingLevel loggingLevel, LogMessage logMessage)` → `LogEntryEventBuilder`

Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level

##### Parameters

| Param          | Description                                              |
| -------------- | -------------------------------------------------------- |
| `loggingLevel` | The logging level enum value for the new entry           |
| `logMessage`   | The instance of LogMessage to use as the entry's message |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of LogEntryEventBuilder

#### `newEntry(LoggingLevel loggingLevel, String message, Boolean shouldSave)` → `LogEntryEventBuilder`

Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level

##### Parameters

| Param          | Description                                                                                                                                         |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `loggingLevel` | The logging level enum value for the new entry                                                                                                      |
| `message`      | The string to use as the entry's message                                                                                                            |
| `shouldSave`   | Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of LogEntryEventBuilder

#### `newEntry(LoggingLevel loggingLevel, String message)` → `LogEntryEventBuilder`

Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level

##### Parameters

| Param          | Description                                    |
| -------------- | ---------------------------------------------- |
| `loggingLevel` | The logging level enum value for the new entry |
| `message`      | The string to use as the entry's message       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of LogEntryEventBuilder

#### `resumeSaving()` → `void`

Resumes saving for the current transaction, used to reverse suspendSaving(). Any calls to saveLog() are ignored until saving is resumed.

#### `saveLog()` → `void`

Saves any entries in Logger's buffer. By default, entries are saved via Apex's EventBus and can be overridden with setSaveMethod(SaveMethod saveMethod)

#### `saveLog(SaveMethod saveMethod)` → `void`

Saves any entries in Logger's buffer, using the specified save method for only this call. All subsequent calls to saveLog() will use the transaction save method.

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `saveMethod` | The enum value of Logger.SaveMethod to use for this specific save action. |

#### `setParentLogTransactionId(String parentTransactionId)` → `void`

Relates the current transaction's log to a parent log via the field Log**c.ParentLog**c This is useful for relating multiple asynchronous operations together, such as batch & queueable jobs.

##### Parameters

| Param                 | Description                                             |
| --------------------- | ------------------------------------------------------- |
| `parentTransactionId` | - The transaction ID of the original parent transaction |

#### `setSaveMethod(SaveMethod saveMethod)` → `void`

Sets the default save method used when calling saveLog() - any subsequent calls to saveLog() will use the specified save method

##### Parameters

| Param        | Description                                                                                              |
| ------------ | -------------------------------------------------------------------------------------------------------- |
| `saveMethod` | - The enum value of Logger.SaveMethod to use for any other calls to saveLog() in the current transaction |

#### `suspendSaving()` → `void`

Pauses saving for the current transaction. Any calls to saveLog() are ignored until saving is resumed.

#### `warn(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log                         |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param            | Description                                                          |
| ---------------- | -------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `deleteResults` | The instance of `List<Database.DeleteResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param          | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry's message field |
| `mergeResults` | The instance of `List<Database.MergeResult>` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param         | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry's message field |
| `saveResults` | The instance of `List<Database.SaveResult>` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param             | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry's message field |
| `undeleteResults` | The instance of `List<Database.UndeleteResult>` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `upsertResults` | The instance of `List<Database.UpsertResult>` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `apexException` | The instance of `Exception` to log                                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Id recordId, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `recordId`      | The record ID of an `SObject` to log                                 |
| `apexException` | The instance of `Exception` to log                                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `recordId`   | The record ID of an `SObject` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, SObject record, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `record`        | The `SObject` record to log                                          |
| `apexException` | The instance of `Exception` to log                                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `record`     | The `SObject` record to log                                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<SObject> records, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `records`       | The list of `SObject` records to log                                 |
| `apexException` | The instance of `Exception` to log                                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |
| `records`    | The list of `SObject` records to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `mergeResult` | The instance of `Database.MergeResult` to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param        | Description                                        |
| ------------ | -------------------------------------------------- |
| `message`    | The string to use to set the entry's message field |
| `saveResult` | The instance of `Database.SaveResult` to log       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param            | Description                                        |
| ---------------- | -------------------------------------------------- |
| `message`        | The string to use to set the entry's message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param          | Description                                        |
| -------------- | -------------------------------------------------- |
| `message`      | The string to use to set the entry's message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `deleteResults` | The list of `Database.DeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param          | Description                                         |
| -------------- | --------------------------------------------------- |
| `message`      | The string to use to set the entry's message field  |
| `mergeResults` | The list of `Database.MergeResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `message`     | The string to use to set the entry's message field |
| `saveResults` | The list of `Database.SaveResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `message`         | The string to use to set the entry's message field     |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `message`       | The string to use to set the entry's message field   |
| `upsertResults` | The list of `Database.UpsertResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                        |
| --------------- | -------------------------------------------------- |
| `message`       | The string to use to set the entry's message field |
| `apexException` | The instance of `Exception` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Id recordId, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                        |
| --------------- | -------------------------------------------------- |
| `message`       | The string to use to set the entry's message field |
| `recordId`      | The record ID of an `SObject` to log               |
| `apexException` | The instance of `Exception` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param      | Description                                        |
| ---------- | -------------------------------------------------- |
| `message`  | The string to use to set the entry's message field |
| `recordId` | The record ID of an `SObject` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, SObject record, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                        |
| --------------- | -------------------------------------------------- |
| `message`       | The string to use to set the entry's message field |
| `record`        | The `SObject` record to log                        |
| `apexException` | The instance of `Exception` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `record`  | The `SObject` record to log                        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<SObject> records, Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry's message field |
| `records`       | The list of `SObject` records to log                                 |
| `apexException` | The instance of `Exception` to log                                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |
| `records` | The list of `SObject` records to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `LoggingLevel.WARN`

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

---

### Inner Classes

#### Logger.QueueableSaver class

---

##### Methods

###### `execute(System.QueueableContext queueableContext)` → `void`

---
