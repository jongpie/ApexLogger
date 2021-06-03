---
layout: default
---

## LogEntryEventBuilder class

Builder class that generates each `LogEntryEvent__e` record

### Related

[Logger](Logger)

---

### Constructors

#### `LogEntryEventBuilder(LoggingLevel entryLoggingLevel, Boolean shouldSave)`

Used by `Logger` to instantiate a new instance of `LogEntryEventBuilder`

##### Parameters

| Param               | Description                                                                     |
| ------------------- | ------------------------------------------------------------------------------- |
| `entryLoggingLevel` | The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e` |
| `shouldSave`        | Determines if the builder's instance of `LogEntryEvent__e` should be saved      |

---

### Methods

#### `getLogEntryEvent()` → `LogEntryEvent__e`

Returns the `LogEntryEvent__e` record for this instance of LogEntryEventBuilder

##### Return

**Type**

LogEntryEvent\_\_e

**Description**

The `LogEntryEvent__e` record

#### `parseStackTrace(String stackTraceString)` → `LogEntryEventBuilder`

Parses the provided stack trace and sets the log entry's origin & stack trace fields

##### Parameters

| Param              | Description                          |
| ------------------ | ------------------------------------ |
| `stackTraceString` | The Apex stack trace string to parse |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Sets the log entry event's database operation result fields

##### Parameters

| Param          | Description                                    |
| -------------- | ---------------------------------------------- |
| `deleteResult` | The instance of `Database.DeleteResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Sets the log entry event's database operation result fields

##### Parameters

| Param         | Description                                   |
| ------------- | --------------------------------------------- |
| `mergeResult` | The instance of `Database.MergeResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Sets the log entry event's database operation result fields

##### Parameters

| Param        | Description                                  |
| ------------ | -------------------------------------------- |
| `saveResult` | The instance of `Database.SaveResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Sets the log entry event's database operation result fields

##### Parameters

| Param          | Description                                    |
| -------------- | ---------------------------------------------- |
| `upsertResult` | The instance of `Database.UpsertResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Sets the log entry event's database operation result fields

##### Parameters

| Param            | Description                                      |
| ---------------- | ------------------------------------------------ |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Sets the log entry event's database operation result fields

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `deleteResults` | The list of `Database.DeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Sets the log entry event's database operation result fields

##### Parameters

| Param          | Description                                         |
| -------------- | --------------------------------------------------- |
| `mergeResults` | The list of `Database.MergeResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Sets the log entry event's database operation result fields

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `saveResults` | The list of `Database.SaveResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Sets the log entry event's database operation result fields

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `upsertResults` | The list of `Database.UpsertResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Sets the log entry event's database operation result fields

##### Parameters

| Param             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setExceptionDetails(Exception apexException)` → `LogEntryEventBuilder`

Sets the log entry event's exception fields

##### Parameters

| Param           | Description                            |
| --------------- | -------------------------------------- |
| `apexException` | The instance of an `Exception` to use. |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setMessage(LogMessage logMessage)` → `LogEntryEventBuilder`

Sets the log entry event's message field

##### Parameters

| Param        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setMessage(String message)` → `LogEntryEventBuilder`

Sets the log entry event's message field

##### Parameters

| Param     | Description                                        |
| --------- | -------------------------------------------------- |
| `message` | The string to use to set the entry's message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setRecord(Id recordId)` → `LogEntryEventBuilder`

Sets the log entry event's record fields

##### Parameters

| Param      | Description                                       |
| ---------- | ------------------------------------------------- |
| `recordId` | The ID of the SObject record related to the entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setRecord(SObject record)` → `LogEntryEventBuilder`

Sets the log entry event's record fields

##### Parameters

| Param    | Description                                                                                           |
| -------- | ----------------------------------------------------------------------------------------------------- |
| `record` | The `SObject` record related to the entry. The JSON of the record is automatically added to the entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setRecord(List<SObject> records)` → `LogEntryEventBuilder`

Sets the log entry event's record fields

##### Parameters

| Param     | Description                                                                                                  |
| --------- | ------------------------------------------------------------------------------------------------------------ |
| `records` | The list of `SObject` records related to the entry. The JSON of the list is automatically added to the entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setRecordId(Id recordId)` → `LogEntryEventBuilder`

Deprecated - use `setRecord(Id recordId)` instead

#### `setRecordId(SObject record)` → `LogEntryEventBuilder`

Deprecated - use `setRecord(SObject record)` instead

#### `setTopics(List<String> topics)` → `LogEntryEventBuilder`

Sets a comma-separate list of strings on the LogEntryEvent**e, which ultimately becomes Topic & TopicAssignment records on Log**c and LogEntry\_\_c

##### Parameters

| Param    | Description                                                |
| -------- | ---------------------------------------------------------- |
| `topics` | The list of strings to use as topics for the current entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `shouldSave()` → `Boolean`

Determines if this instance of `LogEntryEventBuilder` should be saved the next time that `Logger.saveLog()` is called

##### Return

**Type**

Boolean

**Description**

Boolean

---
