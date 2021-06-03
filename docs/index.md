---
layout: default
---

# Classes

## Logger Engine

### [FlowLogEntry](logger-engine/FlowLogEntry)

Handles adding new log entries in Flow

### [FlowRecordLogEntry](logger-engine/FlowRecordLogEntry)

Handles adding new log entries in Flow for a particular `SObject` record

### [LogEntryEventBuilder](logger-engine/LogEntryEventBuilder)

Builder class that generates each `LogEntryEvent__e` record

### [LogMessage](logger-engine/LogMessage)

Provides the ability to generate string messages on demand, using String.format()

### [Logger](logger-engine/Logger)

The core class for logging

## Log Management

### [LogBatchPurgeScheduler](log-management/LogBatchPurgeScheduler)

Schedulable class used to schedule the batch job `LogBatchPurger`

### [LogBatchPurger](log-management/LogBatchPurger)

Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c <= :System.today()`

### [LogEntryEventHandler](log-management/LogEntryEventHandler)

Subscribes to `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records

### [LogEntryFieldSetPicklist](log-management/LogEntryFieldSetPicklist)

Dynamically returns `LogEntry__c` field sets in App Builder when configuring the component RelatedLogEntries

### [LogEntryHandler](log-management/LogEntryHandler)

Manages setting fields on `LogEntry__c` before insert & before update

### [LogHandler](log-management/LogHandler)

Manages setting fields on `Log__c` before insert & before update

### [LogMassDeleteExtension](log-management/LogMassDeleteExtension)

Manages mass deleting `Log__c` records that have been selected by a user on a `Log__c` list view

### [RelatedLogEntriesController](log-management/RelatedLogEntriesController)

Controller class for the component RelatedLogEntries
