//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Additional integration tests for orgs with Experience Sites (Communities) enabled
 */
@isTest
private class Logger_Tests_ExperienceSite {
    private static final String GUEST_USER_PROFILE_NAME = 'Logger Test Site Profile';
    private static final String LOG_CREATOR_PERMISSION_SET_NAME = 'LoggerLogCreator';

    @TestSetup
    static void setupData() {
        Profile loggerSiteProfile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = :GUEST_USER_PROFILE_NAME];
        System.assertEquals('Guest User License', loggerSiteProfile.UserLicense.Name);

        User guestUser = [SELECT Id FROM USER WHERE Profile.NAME = :GUEST_USER_PROFILE_NAME];

        PermissionSet logCreatorPermissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = :LOG_CREATOR_PERMISSION_SET_NAME];
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(AssigneeId = guestUser.Id, PermissionSetId = logCreatorPermissionSet.Id);
        insert permissionSetAssignment;
    }

    @isTest
    private static void it_should_fail_to_save_log_when_assigned_to_guest_user() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Test.startTest();

        User guestUser = [SELECT Id FROM USER WHERE Profile.NAME = :GUEST_USER_PROFILE_NAME];
        try {
            log.OwnerId = guestUser.Id;
            update log;
            System.assert(false, 'Expected exception, this exception should not occur');
        } catch (Exception ex) {
            String expectedExceptionMessage = 'FIELD_INTEGRITY_EXCEPTION, field integrity exception (Guest users cannot be record owners.)';
            System.assert(ex.getMessage().contains(expectedExceptionMessage));
        }
        Test.stopTest();
    }

    @isTest
    private static void it_should_save_log_for_guest_user() {
        Profile loggerSiteProfile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = :GUEST_USER_PROFILE_NAME];
        System.assertEquals('Guest User License', loggerSiteProfile.UserLicense.Name);

        User guestUser = [SELECT Id FROM USER WHERE Profile.NAME = :GUEST_USER_PROFILE_NAME];
        String message = 'testing logging as a guest user';

        System.runAs(guestUser) {
            Logger.debug(message);
            Logger.saveLog();

            Test.getEventBus().deliver();
        }

        LogEntry__c logEntry = [SELECT Id, Log__r.LoggedBy__c, Log__r.OwnerId, Log__r.UserLicenseDefinitionKey__c, Message__c FROM LogEntry__c];
        System.assertEquals(guestUser.Id, logEntry.Log__r.LoggedBy__c);
        System.assertNotEquals(guestUser.Id, logEntry.Log__r.OwnerId);
        System.assertEquals('PID_Guest_User', logEntry.Log__r.UserLicenseDefinitionKey__c);
        System.assertEquals(message, logEntry.Message__c);
    }
}
