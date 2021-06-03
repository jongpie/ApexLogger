global with sharing class ExampleInboundEmailHandler implements Messaging.InboundEmailHandler {
    @testVisible
    private static String logEntryMessage = 'Testing logging from InboundEmailHandler';

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        try {
            String nullString = null;
            nullString.length();
        } catch (Exception apexException) {
            Logger.error(logEntryMessage, apexException);
        } finally {
            result.success = true;
            System.debug('Logger buffer size before save: ' + Logger.getBufferSize());
            Logger.saveLog();
            System.debug('Logger buffer size after save: ' + Logger.getBufferSize());
        }

        return result;
    }
}
