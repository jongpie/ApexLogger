//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Additional integration tests for logging from an instance of `Messaging.InboundEmailHandler`
 */
@isTest
private class Logger_Tests_InboundEmailHandler {
    @isTest
    private static void it_should_save_logs_when_running_email_service() {
        // Create a new email and envelope object
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        // Create the email body
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = 'Example email content';
        email.fromAddress = 'test@test.com';
        String contactEmail = 'someone@salesforce.com';
        email.subject = 'My example email';

        // Create an instance of the example handler class
        ExampleInboundEmailHandler handler = new ExampleInboundEmailHandler();

        Test.startTest();

        String transactionId = Logger.getTransactionId();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);

        Test.stopTest();

        System.assert(result.success, 'InboundEmailResult returned a failure message');

        List<Log__c> logs = [SELECT Id, TransactionId__c FROM Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals(transactionId, logs.get(0).TransactionId__c);

        List<LogEntry__c> logEntries = [SELECT Id, Message__c FROM LogEntry__c];
        System.assertEquals(1, logEntries.size());
        System.assertEquals(ExampleInboundEmailHandler.logEntryMessage, logEntries.get(0).Message__c);
    }
}
