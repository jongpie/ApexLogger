//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class LoggerInstallHandler_Tests {
    @isTest
    static void it_should_initialize_logger_settings_when_installed() {
        // Quick sanity check to make sure there are no existing records
        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(0, existingSettings.size());

        // Currently, there's no logic in LoggerInstallerHandler that checks for a specific version number or upgrades...
        // so null/false are fine for this test right now
        // TODO update this if/when version-specific logic is added in future releases
        Version version = null;
        Boolean isUpgrade = false;

        Test.startTest();
        LoggerInstallHandler installHandler = new LoggerInstallHandler();
        Test.testInstall(installHandler, version, isUpgrade);
        Test.stopTest();

        // Verify that we now have 1 record...
        List<LoggerSettings__c> loggerSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(1, loggerSettings.size());

        // ..and verify that it's the org defaults
        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        System.assertEquals(orgDefaults.Id, loggerSettings.get(0).Id);
    }

    @isTest
    static void it_should_update_defaultSaveMethod_when_null() {
        // DefaultSaveMethod__c was added in a later release as a required field, so some orgs may not have it set
        // Verify the install handler correctly updates any null values

        // Quick sanity check to make sure there are no existing records
        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(0, existingSettings.size());

        List<LoggerSettings__c> mockSettings = new List<LoggerSettings__c>{
            LoggerSettings__c.getOrgDefaults(),
            LoggerSettings__c.getInstance(UserInfo.getProfileId()),
            LoggerSettings__c.getInstance(UserInfo.getUserId())
        };
        for (LoggerSettings__c setting : mockSettings) {
            setting.DefaultSaveMethod__c = null;
        }

        // Currently, there's no logic in LoggerInstallerHandler that checks for a specific version number or upgrades...
        // so null/false are fine for this test right now
        // TODO update this if/when version-specific logic is added in future releases
        Version version = null;
        Boolean isUpgrade = false;

        Test.startTest();

        LoggerInstallHandler installHandler = new LoggerInstallHandler();
        installHandler.settingsWithouDefaultSaveMethod = mockSettings;

        Test.testInstall(installHandler, version, isUpgrade);

        Test.stopTest();

        for (LoggerSettings__c setting : mockSettings) {
            System.assertNotEquals(null, setting.DefaultSaveMethod__c);
        }

        // Verify that all records have been updated with a default save method
        List<LoggerSettings__c> loggerSettings = [SELECT Id, DefaultSaveMethod__c FROM LoggerSettings__c];
        System.assertEquals(3, loggerSettings.size());
        for (LoggerSettings__c setting : loggerSettings) {
            System.assertNotEquals(null, setting.DefaultSaveMethod__c);
        }
    }
}
