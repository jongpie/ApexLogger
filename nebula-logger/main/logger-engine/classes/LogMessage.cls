//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Provides the ability to generate string messages on demand, using String.format()
 * @see Logger
 * @see LogEntryEventBuilder
 */
global inherited sharing virtual class LogMessage {
    private String formattedMessage;
    private String unformattedMessage;
    private List<Object> messageInputs;

    /**
     * @description Constructor to handle dynamically formatting a string with 1 input
     * @param  unformattedMessage The base string to use for your log message
     * @param  messageInput       The replacement text to use for 1 placeholder in the unformatted message
     * @example
     * String formattedMessage = new LogMessage('Today is {0}', System.today()).getMessage();
     */
    global LogMessage(String unformattedMessage, Object messageInput) {
        this.unformattedMessage = unformattedMessage;
        this.messageInputs = new List<Object>{ messageInput };
    }

    /**
     * @description Constructor to handle dynamically formatting a string with 2 inputs
     * @param  unformattedMessage The base string to use for your log message
     * @param  messageInput1       The replacement text to use for the first placeholder in the unformatted message
     * @param  messageInput2       The replacement text to use for the second placeholder in the unformatted message
     * @example
     * String unformattedMessage = 'my string with 2 inputs: {0} and {1}';
     * String formattedMessage = new LogMessage(unformattedMessage, 'something', 'something else').getMessage();
     */
    global LogMessage(String unformattedMessage, Object messageInput1, Object messageInput2) {
        this.unformattedMessage = unformattedMessage;
        this.messageInputs = new List<Object>{ messageInput1, messageInput2 };
    }

    /**
     * @description Constructor to handle dynamically formatting a string with 3 inputs
     * @param  unformattedMessage The base string to use for your log message
     * @param  messageInput1       The replacement text to use for the first placeholder in the unformatted message
     * @param  messageInput2       The replacement text to use for the second placeholder in the unformatted message
     * @param  messageInput3       The replacement text to use for the third placeholder in the unformatted message
     * @example
     * String unformattedMessage = 'my string with 3 inputs: {0} and then {1} and finally {2}';
     * String formattedMessage = new LogMessage(unformattedMessage, 'something', 'something else', 'one more').getMessage();
     */
    global LogMessage(String unformattedMessage, Object messageInput1, Object messageInput2, Object messageInput3) {
        this.unformattedMessage = unformattedMessage;
        this.messageInputs = new List<Object>{ messageInput1, messageInput2, messageInput3 };
    }

    /**
     * @description Constructor to handle dynamically formatting a string with a list of inputs
     * @param  unformattedMessage The base string to use for your log message
     * @param  messageInputs       The list of inputs text to use for any placeholders in the unformatted message
     * @example
     * String unformattedMessage = 'my string with 1 input: {0}';
     * List<Object> arguments = new List<Object>{ System.now() };
     * String formattedMessage = new LogMessage(unformattedMessage, arguments).getMessage();
     */
    global LogMessage(String unformattedMessage, List<Object> messageInputs) {
        this.unformattedMessage = unformattedMessage;
        this.messageInputs = messageInputs;
    }

    // Parameterless constructor that can be used by subclasses when extending LogMessage
    protected LogMessage() {
    }

    /**
     * @description Returns the formatted string to use as the log entry's message
     * @return  String
     */
    global virtual String getMessage() {
        // Just in case getMessage() is called multiple times (first by the originating code, then by Logger)
        // ...cache the result (save CPU time from multiple calls) and discard the original parameters (reduce heap size)
        if (this.formattedMessage == null) {
            this.formattedMessage = String.format(this.unformattedMessage, this.messageInputs);

            this.unformattedMessage = null;
            this.messageInputs = null;
        }

        return this.formattedMessage;
    }
}
