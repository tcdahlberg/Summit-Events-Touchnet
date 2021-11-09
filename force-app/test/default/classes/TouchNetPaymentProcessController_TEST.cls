/**
 * Copyright 2021 University of St. Thomas - Minnesota. All rights reserved.
 * Use of this source code is governed by a BSD Revised
 * license that can be found in the LICENSE file.
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 11/3/2021.
 */


@IsTest
private class TouchNetPaymentProcessController_TEST {
    @IsTest
    static void testNoHeader() {
        User testUser = SeaTouchNetDataFactory.userToRunWith('Standard User', 'Summit_Events_Registrant');
        System.runAs(testUser) {
            TouchNetPaymentProcessController touchNetController = new TouchNetPaymentProcessController();
            PageReference pageRef = touchNetController.checkReturnedHeader();
            System.assertEquals(pageRef, null);
        }
    }

    @IsTest
    static void testWithWrongHeader() {
        User testUser = SeaTouchNetDataFactory.userToRunWith('Standard User', 'Summit_Events_Registrant');
        System.runAs(testUser) {
            Test.startTest();
            PageReference p = Page.TouchNetPaymentProcess;
            p.getHeaders().put('Referer', 'None');
            Test.setCurrentPage(p);
            TouchNetPaymentProcessController touchNetController = new TouchNetPaymentProcessController();

            PageReference pageRef = touchNetController.checkReturnedHeader();
            System.assertEquals(pageRef, null);

            Boolean messageFound = false;
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            for (ApexPages.Message message : pageMessages) {
                if (message.getSummary() == 'Set your orgs gateway settings or fees will not be collected.' && message.getSeverity() == ApexPages.Severity.WARNING) {
                    messageFound = true;
                }
            }
            System.assert(messageFound);
            Test.stopTest();

        }
    }

    @IsTest
    static void testHeaderNoSessionIdentifier() {
        User testUser = SeaTouchNetDataFactory.userToRunWith('Standard User', 'Summit_Events_Registrant');

        TouchNet_Payment_Gateway__c tNCustomSettings = TouchNet_Payment_Gateway__c.getOrgDefaults();
        tNCustomSettings.Validation_Key__c = 'FAKE';
        tNCustomSettings.UPay_Id__c = '0';
        tNCustomSettings.TLink_URL__c = 'https://test.secure.touchnet.net:8703/TESTtest_tlink/services/TPGSecureLink';
        tNCustomSettings.UPay_URL__c = 'https://test.secure.touchnet.net:8443/TESTtest_tlink/web/index.jsp';
        tNCustomSettings.Gateway_Origin__c = 'https://test.secure.touchnet.net';
        insert tNCustomSettings;

        SeaTouchNetDataFactory.checkSeaCustomSettings();

        System.runAs(testUser) {
            Test.startTest();
            PageReference p = Page.TouchNetPaymentProcess;
            p.getHeaders().put('Referer', tNCustomSettings.Gateway_Origin__c);
            Test.setCurrentPage(p);

            TouchNetPaymentProcessController touchNetController = new TouchNetPaymentProcessController();
            PageReference pageRef = touchNetController.checkReturnedHeader();
            System.assertEquals(pageRef, null);

            Boolean messageFound = false;
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            for (ApexPages.Message message : pageMessages) {
                if (message.getSummary() == 'Your payment is processing was unsuccessful. Please try again.' && message.getSeverity() == ApexPages.Severity.WARNING) {
                    messageFound = true;
                }
            }
            System.assert(messageFound);
            Test.stopTest();
        }
    }

    @IsTest
    static void testHeaderWithSessionIdentifier() {
        /* Add Event data */
        SeaTouchNetDataFactory.checkSeaCustomSettings();
        List<summit__Summit_Events_Instance__c> seaTestInstances = SeaTouchNetDataFactory.createTestEvent();
        summit__Summit_Events_Registration__c seaTestRegistration = SeaTouchNetDataFactory.createEventRegistration(seaTestInstances[1], 'TestFirst', 'TestLast', 'test@valleyhill.net', '55418', '1971-03-22', '2012', null);
        List<summit__Summit_Events_Fee_Allocation__c> testFeeAllocations = SeaTouchNetDataFactory.AddFeesToEvent(seaTestInstances[1].summit__Event__c);
        User testUser = SeaTouchNetDataFactory.userToRunWith('Standard User', 'Summit_Events_Registrant');

        /* Add a fee to the registration */
        summit__Summit_Events_Fee__c seaFee = new summit__Summit_Events_Fee__c();
        seaFee.summit__Event_Registration__c = seaTestRegistration.Id;
        seaFee.summit__Event_Fee_Allocation__c = testFeeAllocations[1].Id;
        seaFee.summit__Summit_Events__c = seaTestInstances[1].summit__Event__c;
        seaFee.summit__Event_Fee__c = 100.00;
        insert seaFee;

        TouchNet_Payment_Gateway__c tNCustomSettings = TouchNet_Payment_Gateway__c.getOrgDefaults();
        tNCustomSettings.Validation_Key__c = 'FAKE';
        tNCustomSettings.UPay_Id__c = '0';
        tNCustomSettings.TLink_URL__c = 'https://test.secure.touchnet.net:8703/TESTtest_tlink/services/TPGSecureLink';
        tNCustomSettings.UPay_URL__c = 'https://test.secure.touchnet.net:8443/TESTtest_tlink/web/index.jsp';
        tNCustomSettings.Gateway_Origin__c = 'https://test.secure.touchnet.net';
        insert tNCustomSettings;

        /* Create a mock call out to get SOAP connection ticket */
        Test.setMock(HttpCalloutMock.class, new TouchNetSuccessRequestMock());

        System.runAs(testUser) {
            Test.startTest();
            PageReference p = Page.TouchNetPaymentProcess;
            p.getHeaders().put('Referer', tNCustomSettings.Gateway_Origin__c);
            p.getParameters().put('session_identifier', 'test_session_identifier');

            /* Create an encrypted cookie so the page knows what registration it is referencing */
            TouchNetHelper tNHelper = new TouchNetHelper();
            String eventInfo = tNHelper.createEncryptedCookie('Transfer', seaTestInstances[1].Id, seaTestInstances[1].summit__Event__c, seaTestRegistration.Id);
            p.getParameters().put('eventInfo', eventInfo);

            Test.setCurrentPage(p);

            TouchNetPaymentProcessController touchNetController = new TouchNetPaymentProcessController();
            PageReference pageRef = touchNetController.checkReturnedHeader();
            System.assertEquals(pageRef.getUrl(), 'https://google.com/summit__SummitEventsConfirmation?eventInfo=');

            Boolean messageFound = false;
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            for (ApexPages.Message message : pageMessages) {
                if (message.getSummary() == 'Your payment is processing. Please do not refresh the page.' && message.getSeverity() == ApexPages.Severity.WARNING) {
                    messageFound = true;
                }
            }
            System.assert(messageFound);

            List<summit__Summit_Events_Payment__c> eventsPayments = [
                    SELECT Id, summit__Payment_Amount__c
                    FROM summit__Summit_Events_Payment__c
                    WHERE summit__Event_Registration__c = :seaTestRegistration.Id
            ];
            /* Check if payment record was created with correct amount */
            System.assert(eventsPayments.size() > 0);
            System.assertEquals(eventsPayments[0].summit__Payment_Amount__c, 100.00);

            List<summit__Summit_Events_Fee__c> fees = [
                    SELECT Id, summit__Summit_Events_Payment__c
                    FROM summit__Summit_Events_Fee__c
                    WHERE summit__Event_Registration__c = :seaTestRegistration.Id
            ];

            /* Make sure fees have payment lookup in place */
            for (summit__Summit_Events_Fee__c fee : fees) {
                System.assertEquals(eventsPayments[0].Id, fee.summit__Summit_Events_Payment__c);
            }

            Test.stopTest();
        }
    }
}