/**
 * Copyright 2021 University of St. Thomas - Minnesota. All rights reserved.
 * Use of this source code is governed by a BSD Revised
 * license that can be found in the LICENSE file.
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 11/3/2021.
 */


@IsTest
private class TouchNetPaymentProcessController_TEST {
    @IsTest
    static void testBehavior() {
        List<summit__Summit_Events_Instance__c> seaTestInstances = SeaTouchNetDataFactory.createTestEvent();
        summit__Summit_Events_Registration__c seaTestRegistration = SeaTouchNetDataFactory.createEventRegistration(seaTestInstances[1], 'TestFirst', 'TestLast', 'test@valleyhill.net', '55418', '1971-03-22', '2012', null);
        List<summit__Summit_Events_Fee_Allocation__c> testFeeAllocations = SeaTouchNetDataFactory.AddFeesToEvent(seaTestInstances[1].summit__Event__c);
        SeaTouchNetDataFactory.AddDonationsToEvents(seaTestInstances[1].summit__Event__c, testFeeAllocations);
        User testUser = SeaTouchNetDataFactory.userToRunWith('Standard User','Summit_Events_Registrant');
        System.runAs(testUser) {
            TouchNetPaymentProcessController touchNetController = new TouchNetPaymentProcessController();
            touchNetController.checkReturnedHeader();
        }
    }
}