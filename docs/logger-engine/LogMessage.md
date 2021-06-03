---
layout: default
---

## LogMessage class

Provides the ability to generate string messages on demand, using String.format()

### Related

[Logger](Logger)

[LogEntryEventBuilder](LogEntryEventBuilder)

---

### Constructors

#### `LogMessage(String unformattedMessage, Object messageInput)`

Constructor to handle dynamically formatting a string with 1 input

##### Parameters

| Param                | Description                                                              |
| -------------------- | ------------------------------------------------------------------------ |
| `unformattedMessage` | The base string to use for your log message                              |
| `messageInput`       | The replacement text to use for 1 placeholder in the unformatted message |

##### Example

```java
String formattedMessage = new LogMessage('Today is {0}', System.today()).getMessage();
```

#### `LogMessage(String unformattedMessage, Object messageInput1, Object messageInput2)`

Constructor to handle dynamically formatting a string with 2 inputs

##### Parameters

| Param                | Description                                                                       |
| -------------------- | --------------------------------------------------------------------------------- |
| `unformattedMessage` | The base string to use for your log message                                       |
| `messageInput1`      | The replacement text to use for the first placeholder in the unformatted message  |
| `messageInput2`      | The replacement text to use for the second placeholder in the unformatted message |

##### Example

```java
String unformattedMessage = 'my string with 2 inputs: {0} and {1}';
String formattedMessage = new LogMessage(unformattedMessage, 'something', 'something else').getMessage();
```

#### `LogMessage(String unformattedMessage, Object messageInput1, Object messageInput2, Object messageInput3)`

Constructor to handle dynamically formatting a string with 3 inputs

##### Parameters

| Param                | Description                                                                       |
| -------------------- | --------------------------------------------------------------------------------- |
| `unformattedMessage` | The base string to use for your log message                                       |
| `messageInput1`      | The replacement text to use for the first placeholder in the unformatted message  |
| `messageInput2`      | The replacement text to use for the second placeholder in the unformatted message |
| `messageInput3`      | The replacement text to use for the third placeholder in the unformatted message  |

##### Example

```java
String unformattedMessage = 'my string with 3 inputs: {0} and then {1} and finally {2}';
String formattedMessage = new LogMessage(unformattedMessage, 'something', 'something else', 'one more').getMessage();
```

#### `LogMessage(String unformattedMessage, List<Object> messageInputs)`

Constructor to handle dynamically formatting a string with a list of inputs

##### Parameters

| Param                | Description                                                                    |
| -------------------- | ------------------------------------------------------------------------------ |
| `unformattedMessage` | The base string to use for your log message                                    |
| `messageInputs`      | The list of inputs text to use for any placeholders in the unformatted message |

##### Example

```java
String unformattedMessage = 'my string with 1 input: {0}';
List<Object> arguments = new List<Object>{ System.now() };
String formattedMessage = new LogMessage(unformattedMessage, arguments).getMessage();
```

---

### Methods

#### `getMessage()` → `String`

Returns the formatted string to use as the log entry's message

##### Return

**Type**

String

**Description**

String

---
