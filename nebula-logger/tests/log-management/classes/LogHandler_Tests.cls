//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class LogHandler_Tests {
    private static final String HIGH_PRIORITY = Schema.Log__c.Priority__c.getDescribe().getPicklistValues().get(0).getValue();
    private static final String MEDIUM_PRIORITY = Schema.Log__c.Priority__c.getDescribe().getPicklistValues().get(1).getValue();
    private static final String LOW_PRIORITY = Schema.Log__c.Priority__c.getDescribe().getPicklistValues().get(2).getValue();

    private static final String FIRST_STATUS = Schema.Log__c.Status__c.getDescribe().getPicklistValues().get(0).getValue();
    private static final String SECOND_STATUS = Schema.Log__c.Status__c.getDescribe().getPicklistValues().get(1).getValue();

    @testSetup
    static void setupData() {
        Map<String, LogStatus__mdt> logStatusByName = new Map<String, LogStatus__mdt>();
        LogStatus__mdt openStatus = new LogStatus__mdt(IsActive__c = true, MasterLabel = FIRST_STATUS, IsClosed__c = false, IsResolved__c = false);
        logStatusByName.put(openStatus.MasterLabel, openStatus);

        LogStatus__mdt closedStatus = new LogStatus__mdt(IsActive__c = true, MasterLabel = SECOND_STATUS, IsClosed__c = true, IsResolved__c = true);
        logStatusByName.put(closedStatus.MasterLabel, closedStatus);

        LogHandler.logStatusByName = logStatusByName;
    }

    @isTest
    static void it_should_set_org_release_cycle_on_insert() {
        Set<String> previewInstances = new Set<String>{
            'CS2',
            'CS4',
            'CS5',
            'CS7',
            'CS9',
            'CS11',
            'CS14',
            'CS15',
            'CS17',
            'CS19',
            'CS20',
            'CS21',
            'CS23',
            'CS25',
            'CS26',
            'CS27',
            'CS28',
            'CS31',
            'CS32',
            'CS34',
            'CS35',
            'CS36',
            'CS37',
            'CS41',
            'CS42',
            'CS44',
            'CS45',
            'CS47',
            'CS53',
            'CS57',
            'CS59',
            'CS61',
            'CS63',
            'CS67',
            'CS69',
            'CS72',
            'CS74',
            'CS75',
            'CS76',
            'CS77',
            'CS78',
            'CS79',
            'CS80',
            'CS81',
            'CS84',
            'CS87',
            'CS88',
            'CS91',
            'CS95',
            'CS96',
            'CS97',
            'CS99',
            'CS105',
            'CS106',
            'CS107',
            'CS108',
            'CS109',
            'CS111',
            'CS112',
            'CS113',
            'CS116',
            'CS122',
            'CS123',
            'CS124',
            'CS125',
            'CS126',
            'CS127',
            'CS128',
            'CS129',
            'CS133',
            'CS137',
            'CS138',
            'CS142',
            'CS152',
            'CS159',
            'CS160',
            'CS166',
            'CS167',
            'CS169',
            'CS172',
            'CS174',
            'CS189',
            'CS190',
            'CS191',
            'CS192',
            'CS193',
            'CS194',
            'CS195',
            'CS196',
            'CS197',
            'CS198',
            'CS199',
            'CS201',
            'CS203',
            'AUS2S',
            'IND3S',
            'USA3S'
        };

        Set<String> nonPreviewInstances = new Set<String>{
            'CS1',
            'CS6',
            'CS8',
            'CS10',
            'CS16',
            'CS18',
            'CS22',
            'CS24',
            'CS29',
            'CS33',
            'CS40',
            'CS43',
            'CS50',
            'CS58',
            'CS60',
            'CS62',
            'CS64',
            'CS65',
            'CS66',
            'CS68',
            'CS73',
            'CS86',
            'CS89',
            'CS90',
            'CS92',
            'CS94',
            'CS98',
            'CS100',
            'CS101',
            'CS102',
            'CS110',
            'CS114',
            'CS115',
            'CS117',
            'CS119',
            'CS121',
            'CS132',
            'CS148',
            'CS151',
            'CS162',
            'CS165',
            'CS171',
            'CS173',
            'CS200',
            'CS202',
            'AUS4S',
            'IND2S',
            'USA2S'
        };

        Organization organization = [SELECT Id, InstanceName, IsSandbox FROM Organization];

        String expectedReleaseCycle;
        if (organization.IsSandbox == false || nonPreviewInstances.contains(organization.InstanceName)) {
            expectedReleaseCycle = 'Non-Preview Instance';
        } else if (previewInstances.contains(organization.InstanceName)) {
            expectedReleaseCycle = 'Preview Instance';
        } else {
            // Use 'Unknown' as the default for private instances and situations where the hardcoded sets above are missing some values
            expectedReleaseCycle = 'Unknown';
        }

        Log__c log = new Log__c(TransactionId__c = '1234');

        Test.startTest();
        insert log;
        Test.stopTest();

        log = [SELECT Id, OrganizationInstanceReleaseCycle__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(expectedReleaseCycle, log.OrganizationInstanceReleaseCycle__c);
    }

    @isTest
    static void it_should_clear_closed_status_fields_when_open() {
        Log__c log = new Log__c(
            ClosedBy__c = UserInfo.getUserId(),
            ClosedDate__c = System.now(),
            IsClosed__c = true,
            IsResolved__c = true,
            Status__c = FIRST_STATUS,
            TransactionId__c = '1234'
        );

        Test.startTest();
        insert log;
        Test.stopTest();

        log = [SELECT Id, ClosedBy__c, ClosedDate__c, IsClosed__c, IsResolved__c, Status__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(null, log.ClosedBy__c);
        System.assertEquals(null, log.ClosedDate__c);
        System.assertEquals(false, log.IsClosed__c);
        System.assertEquals(false, log.IsResolved__c);
    }

    @isTest
    static void it_should_set_closed_status_fields_when_closed() {
        Log__c log = new Log__c(
            ClosedBy__c = null,
            ClosedDate__c = null,
            IsClosed__c = false,
            IsResolved__c = false,
            Status__c = SECOND_STATUS,
            TransactionId__c = '1234'
        );

        Test.startTest();
        insert log;
        Test.stopTest();

        log = [SELECT Id, ClosedBy__c, ClosedDate__c, IsClosed__c, IsResolved__c, Status__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(UserInfo.getUserId(), log.ClosedBy__c);
        System.assertEquals(System.today(), log.ClosedDate__c.date());
        System.assertEquals(true, log.IsClosed__c);
    }

    @isTest
    static void it_should_keep_existing_retention_date_when_populated() {
        Integer defaultDaysToRetainLog = 10;

        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultNumberOfDaysToRetainLogs__c = defaultDaysToRetainLog;
        upsert settings;

        Test.startTest();

        Integer specifiedDaysToRetainLog = 50;
        Date retentionDate = System.today().addDays(specifiedDaysToRetainLog);
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), LogRetentionDate__c = retentionDate, TransactionId__c = '1234');
        insert log;

        Test.stopTest();

        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assertNotEquals(defaultDaysToRetainLog, specifiedDaysToRetainLog);
        System.assertEquals(retentionDate, log.LogRetentionDate__c);
    }

    @isTest
    static void it_should_set_retention_date_when_configured() {
        Integer daysToRetainLog = 90;
        Date expectedRetentionDate = System.today().addDays(daysToRetainLog);

        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultNumberOfDaysToRetainLogs__c = daysToRetainLog;
        upsert settings;

        Test.startTest();

        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;

        Test.stopTest();

        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(expectedRetentionDate, log.LogRetentionDate__c);
    }

    @isTest
    static void it_should_have_null_retention_date_when_no_retention_configured() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultNumberOfDaysToRetainLogs__c = null;
        upsert settings;

        Test.startTest();

        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;

        Test.stopTest();

        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(null, log.LogRetentionDate__c);
    }

    @isTest
    static void it_should_set_priority_to_high_when_there_are_errors() {
        Log__c log = new Log__c(Priority__c = LOW_PRIORITY, TransactionId__c = '1234');
        insert log;
        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(LOW_PRIORITY, log.Priority__c);

        Test.startTest();
        insert new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR');
        Test.stopTest();

        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(HIGH_PRIORITY, log.Priority__c);
    }

    @isTest
    static void it_should_set_priority_to_medium_when_there_are_warnings() {
        Log__c log = new Log__c(Priority__c = LOW_PRIORITY, TransactionId__c = '1234');
        insert log;
        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(LOW_PRIORITY, log.Priority__c);

        Test.startTest();
        insert new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'WARN');
        Test.stopTest();

        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(MEDIUM_PRIORITY, log.Priority__c);
    }

    @isTest
    static void it_should_grant_read_access_to_user_when_access_level_is_read() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = 'Read';
        upsert settings;

        Test.startTest();
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;
        Test.stopTest();

        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];

        System.assertEquals(1, logShares.size(), logShares);
        System.assertEquals('Read', logShares.get(0).AccessLevel);
        System.assertEquals(log.Id, logShares.get(0).ParentId);
        System.assertEquals(Schema.Log__Share.RowCause.LoggedByUser__c, logShares.get(0).RowCause);
        System.assertEquals(log.LoggedBy__c, logShares.get(0).UserOrGroupId);
    }

    @isTest
    static void it_should_grant_edit_access_to_user_when_access_level_is_edit() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = 'Edit';
        upsert settings;

        Test.startTest();
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;
        Test.stopTest();

        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];

        System.assertEquals(1, logShares.size(), logShares);
        System.assertEquals('Edit', logShares.get(0).AccessLevel);
        System.assertEquals(log.Id, logShares.get(0).ParentId);
        System.assertEquals(Schema.Log__Share.RowCause.LoggedByUser__c, logShares.get(0).RowCause);
        System.assertEquals(log.LoggedBy__c, logShares.get(0).UserOrGroupId);
    }

    @isTest
    static void it_should_not_grant_access_to_user_when_access_level_is_null() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = null;
        upsert settings;

        Test.startTest();
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;
        Test.stopTest();

        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];

        System.assertEquals(0, logShares.size(), logShares);
    }

    @isTest
    static void it_should_not_grant_access_to_user_when_access_level_is_an_unknown_string() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = 'FAKE LEVEL';
        upsert settings;

        Test.startTest();
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;
        Test.stopTest();

        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];

        System.assertEquals(0, logShares.size(), logShares);
    }
}
