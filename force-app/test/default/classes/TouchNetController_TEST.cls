/**
 * Copyright 2021 University of St. Thomas - Minnesota. All rights reserved.
 * Use of this source code is governed by a BSD Revised
 * license that can be found in the LICENSE file.
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 11/3/2021.
 */


@IsTest
private class TouchNetController_TEST {
    @IsTest
    static void testNoTouchNetConfig() {
        /* TouchNet gateway settings are not set and should give an error message on the page */
        /* Add Event data */
        List<summit__Summit_Events_Instance__c> seaTestInstances = SeaTouchNetDataFactory.createTestEvent();
        SeaTouchNetDataFactory.createEventRegistration(seaTestInstances[1], 'TestFirst', 'TestLast', 'test@valleyhill.net', '55418', '1971-03-22', '2012', null);
        SeaTouchNetDataFactory.AddFeesToEvent(seaTestInstances[1].summit__Event__c);
        User testUser = SeaTouchNetDataFactory.userToRunWith('Standard User', 'Summit_Events_Registrant');
        SeaTouchNetDataFactory.checkSeaCustomSettings();

        System.runAs(testUser) {
            Test.startTest();
            PageReference p = Page.TouchNet;
            Test.setCurrentPage(p);
            TouchNetController tNController = new TouchNetController();

            PageReference eventPageRef = tNController.checkDefaultEventInfo();
            System.assertEquals('https://google.com/summit__SummitEventsSubmit?error=Error%3A+Payment+gateway+setup+information+is+incomplete.', eventPageRef.getUrl());

            Boolean messageFound = false;
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            for (ApexPages.Message message : pageMessages) {
                if (message.getSummary() == 'Error: Payment gateway setup information is incomplete.' && message.getSeverity() == ApexPages.Severity.FATAL) {
                    messageFound = true;
                }
            }
            System.assert(messageFound);
            Test.stopTest();
        }
    }

    @IsTest
    static void testTouchNoRegistration() {
        /* Touchnet gateway settings are set, but no event registration is detectable so a page erro message is given */
        User testUser = SeaTouchNetDataFactory.userToRunWith('Standard User', 'Summit_Events_Registrant');
        System.runAs(testUser) {
            Touchnet_Payment_Gateway__c tNCustomSettings = Touchnet_Payment_Gateway__c.getOrgDefaults();
            tNCustomSettings.Validation_Key__c = 'FAKE';
            tNCustomSettings.Upay_Id__c = '0';
            tNCustomSettings.Tlink_URL__c = 'https://test.secure.touchnet.net:8703/TESTtest_tlink/services/TPGSecureLink';
            tNCustomSettings.Upay_URL__c = 'https://test.secure.touchnet.net:8443/TESTtest_tlink/web/index.jsp';
            tNCustomSettings.Gateway_Origin__c = 'https://test.secure.touchnet.net';
            insert tNCustomSettings;

            SeaTouchNetDataFactory.checkSeaCustomSettings();

            Test.startTest();
            PageReference p = Page.TouchNet;
            Test.setCurrentPage(p);
            TouchNetController tNController = new TouchNetController();

            /* Check to see if when no registration is present correct pageRef returned. */
            PageReference eventPageRef = tNController.checkDefaultEventInfo();
            System.assertEquals('https://google.com/summit__SummitEventsSubmit?error=Error%3A+Could+not+detect+a+registration.',eventPageRef.getUrl());

            /* Get the correct page error when no registration is present */
            Boolean messageFound = false;
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            for (ApexPages.Message message : pageMessages) {
                if (message.getSummary() == 'Error: Could not detect a registration.' && message.getSeverity() == ApexPages.Severity.FATAL) {
                    messageFound = true;
                }
            }
            System.Assert(messageFound);

            Test.stopTest();
        }
    }

    @IsTest
    static void testTouchNetWithRegistration() {
        /* Add Event data */
        List<summit__Summit_Events_Instance__c> seaTestInstances = SeaTouchNetDataFactory.createTestEvent();
        summit__Summit_Events_Registration__c seaTestRegistration = SeaTouchNetDataFactory.createEventRegistration(seaTestInstances[1], 'TestFirst', 'TestLast', 'test@valleyhill.net', '55418', '1971-03-22', '2012', null);
        List<summit__Summit_Events_Fee_Allocation__c> testFeeAllocations = SeaTouchNetDataFactory.AddFeesToEvent(seaTestInstances[1].summit__Event__c);
        User testUser = SeaTouchNetDataFactory.userToRunWith('Standard User', 'Summit_Events_Registrant');

        /* Add a fee to the registration */
        summit__Summit_Events_Fee__c seaFee = new summit__Summit_Events_Fee__c();
        seaFee.summit__Event_Registration__c = seaTestRegistration.Id;
        seaFee.summit__Event_Fee_Allocation__c = testFeeAllocations[1].Id;
        seaFee.summit__Event_Fee__c = 100.00;
        insert seaFee;

        /* Add fake TouchNet gateway information into custom settings */
        Touchnet_Payment_Gateway__c tNCustomSettings = Touchnet_Payment_Gateway__c.getOrgDefaults();
        tNCustomSettings.Validation_Key__c = 'FAKE';
        tNCustomSettings.Upay_Id__c = '0';
        tNCustomSettings.Tlink_URL__c = 'https://test.secure.touchnet.net:8703/TESTtest_tlink/services/TPGSecureLink';
        tNCustomSettings.Upay_URL__c = 'https://test.secure.touchnet.net:8443/TESTtest_tlink/web/index.jsp';
        tNCustomSettings.Gateway_Origin__c = 'https://test.secure.touchnet.net';
        insert tNCustomSettings;

        /* Create a mock call out to get SOAP connection ticket */
        Test.setMock(HttpCalloutMock.class, new TouchNetTicketRequestMock());

        System.runAs(testUser) {
            Test.startTest();
            PageReference pageRef = Page.TouchNet;
            Test.setCurrentPage(pageRef);
            TouchNetHelper tNHelper = new TouchNetHelper();

            /* Create an encrypted cookie so the page knows what registration it is referencing */
            tNHelper.createEncryptedCookie('Transfer', seaTestInstances[1].Id, seaTestInstances[1].summit__Event__c, seaTestRegistration.Id);

            TouchNetController tNController = new TouchNetController();
            tNController.checkDefaultEventInfo();

            System.assertEquals('TEST_TICKET', tNController.ticket);

            Test.stopTest();
        }
    }

}
