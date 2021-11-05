/**
 * Copyright 2021 University of St. Thomas - Minnesota. All rights reserved.
 * Use of this source code is governed by a BSD Revised
 * license that can be found in the LICENSE file.
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 11/3/2021.
 */


@IsTest
public with sharing class SeaTouchNetDataFactory {

    public static void checkSeaCustomSettings() {
        summit__Summit_Events_Settings__c SummitEventsSettings = summit__Summit_Events_Settings__c.getOrgDefaults();
        if (String.isBlank(SummitEventsSettings.summit__Cookie_Encryption_Key__c)) {
            Blob cryptoKey = Crypto.generateAesKey(256);
            String encryptionString = EncodingUtil.base64Encode(cryptoKey).substring(0, 32);
            SummitEventsSettings.summit__Cookie_Encryption_Key__c = encryptionString;
            upsert SummitEventsSettings;
        }
        if (String.isBlank(SummitEventsSettings.summit__Community_Base_URL__c)) {
            SummitEventsSettings.summit__Community_Base_URL__c = 'https://google.com/';
            upsert SummitEventsSettings;
        }
    }

    public static List<summit__Summit_Events_Instance__c> createTestEvent() {

        checkSeaCustomSettings();

        summit__Summit_Events__c testEvent = new summit__Summit_Events__c();
        //Create event
        testEvent = new summit__Summit_Events__c(
                Name = 'Test Event',
                summit__Event_Status__c = 'Active',
                summit__Event_Name__c = 'Test Event',
                summit__Start_Date__c = Date.today().addDays(-20),
                summit__End_Date__c = Date.today().addDays(20),
                summit__Template__c = 'GeneralSLDS',
                summit__Close_Event_Days_Before__c = 0,
                summit__Location_Title__c = 'A location',
                summit__Location_Map_Link__c = 'Map Link 1',
                summit__Location_Address__c = '123 Electric Ave.',
                summit__Location_Type__c = 'On-Site',
                summit__Allow_Other_Attendees__c = true,
                summit__Max_Other_Attendees__c = 10
        );
        insert testEvent;

        List<summit__Summit_Events_Instance__c> seaTestInstances = new List<summit__Summit_Events_Instance__c>();

        for (Integer x = -1; x < 10; x++) {
            summit__Summit_Events_Instance__c seaInstance = new summit__Summit_Events_Instance__c();
            seaInstance.summit__Event__c = testEvent.Id;
            seaInstance.summit__Instance_Title__c = testEvent.Name + ' Session ' + x;
            seaInstance.summit__Instance_Start_Date__c = Date.today().addDays(x);
            seaInstance.summit__Instance_Start_Time__c = Time.newInstance(8, 0, 0, 0);
            seaInstance.summit__Instance_End_Date__c = Date.today().addDays(x);
            seaInstance.summit__Instance_End_Time__c = Time.newInstance(14, 0, 0, 0);
            seaInstance.summit__Instance_Time_Zone__c = 'Central Daylight Time (America/Chicago)';
            seaInstance.summit__Active_Status__c = 'Active';
            seaInstance.summit__Capacity__c = 500;
            seaTestInstances.add(seaInstance);
        }
        insert seaTestInstances;
        return seaTestInstances;
    }

    public static List<summit__Summit_Events_Host__c> createHosts(Id seaInstanceId) {
        Id classRecType = Schema.SObjectType.summit__Summit_Events_Host__c.getRecordTypeInfosByName().get('Class').getRecordTypeId();
        List<summit__Summit_Events_Host__c> testHosts = new List<summit__Summit_Events_Host__c>();
        testHosts.add(new summit__Summit_Events_Host__c(
                summit__Event_Instance__c = seaInstanceId,
                summit__First_Name__c = 'Host1',
                summit__Last_Name__c = 'Host1',
                RecordTypeId = classRecType,
                summit__Preferred_Title__c = 'Mr.',
                summit__Gender__c = 'M',
                summit__Department__c = 'Host Dept 1',
                summit__Course_Name__c = 'Host 1 Course',
                summit__Max_Available__c = 10,
                summit__Location__c = 'TEST LOCATION 1'
        ));

        testHosts.add(new summit__Summit_Events_Host__c(
                summit__Event_Instance__c = seaInstanceId,
                summit__First_Name__c = 'Host2',
                summit__Last_Name__c = 'Host2',
                RecordTypeId = classRecType,
                summit__Preferred_Title__c = 'Mr.',
                summit__Gender__c = 'M',
                summit__Department__c = 'Host Dept 2',
                summit__Course_Name__c = 'Host 2 Course',
                summit__Max_Available__c = 10,
                summit__Assigned__c = 10,
                summit__Location__c = 'TEST LOCATION 2'
        ));
        insert testHosts;
        return testHosts;
    }

    public static summit__Summit_Events__c getEventRecord(Id eventId) {
        summit__Summit_Events__c seaTestEvent = [
                SELECT Name, Id
                FROM summit__Summit_Events__c
                WHERE Id = :eventId
        ];
        return seaTestEvent;
    }
    public static List<summit__Summit_Events_Appointment_Type__c> createAppointmentTypes(Id seaEventId) {
        List<summit__Summit_Events_Appointment_Type__c> seaTestAppointmentTypes = new List<summit__Summit_Events_Appointment_Type__c>();

        //Get all the variations of user input to make a appointment type for each
        List<String> registrantInputValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = summit__Summit_Events_Appointment_Type__c.summit__Registrant_Input__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            registrantInputValues.add(pickListVal.getLabel());
        }

        for (Integer x = 0; x < registrantInputValues.size(); x++) {
            summit__Summit_Events_Appointment_Type__c appointmentType = new summit__Summit_Events_Appointment_Type__c();
            appointmentType.summit__Summit_Events__c = seaEventId;
            appointmentType.summit__Title__c = 'Test Appointment ' + x;
            appointmentType.summit__Appointment_Type_Status__c = 'Active';
            appointmentType.summit__Sort_Order__c = x;
            appointmentType.summit__Registrant_Input__c = registrantInputValues[x];
            if (registrantInputValues[x].containsIgnoreCase('pick list')) {
                appointmentType.summit__Custom_Picklist__c = 'Picklist 1;Picklist 2;Picklist 3; Picklist 4;';
            }
            appointmentType.summit__Description__c = 'Test Appointment Number ' + x;
            seaTestAppointmentTypes.add(appointmentType);
        }
        //Add a category appointment
        summit__Summit_Events_Appointment_Type__c appointmentType = new summit__Summit_Events_Appointment_Type__c();
        appointmentType.summit__Summit_Events__c = seaEventId;
        appointmentType.summit__Title__c = 'Test Appointment Category';
        appointmentType.summit__Appointment_Type_Status__c = 'Active';
        appointmentType.summit__Sort_Order__c = 99;
        appointmentType.summit__Appointment_Category__c = 'Admissions Visit';
        appointmentType.summit__Description__c = 'Test Appointment Category ';
        seaTestAppointmentTypes.add(appointmentType);
        insert seaTestAppointmentTypes;
        return seaTestAppointmentTypes;
    }


    public static summit__Summit_Events_Email__c createTestTransactionEmail(summit__Summit_Events_Instance__c evtInst, String status, String subStatus) {

        // Add email on requested status
        summit__Summit_Events_Email__c testEvtEmail = new summit__Summit_Events_Email__c(
                summit__Action_Status__c = status,
                summit__Action_Sub_status__c = subStatus,
                summit__BCC_Email__c = 'thad+test@valleyhill.net,thad+test2@valleyhill.net',
                summit__Email_Subject__c = 'TEST EMAIL',
                summit__Email_Content__c = 'Name: {!Registrant_First_Name__c} {!Registrant_Last_Name__c} Event Date: {!Event_Instance_Date_Time_Formatted__c} Event Session: {!Instance_Title__c} Attendees:{!Total_Number_of_Guests__c} Email: {!Registrant_Email__c} High School: {!Registrant_High_School__c}',
                summit__Letterhead_HTML__c = '<html><style> p { margin-top: 0px; margin-bottom: 0px;} </style><body id="body" style=" background-color:#FFFFFF; color:#FFFFFF; " ><center><table cellpadding="0" width="500" cellspacing="0" height="450">  <tr valign="top">    <td id="header" style=" background-color:#FFFFFF; color:#FFFFFF; height:100px; " ><img src="https://c.cs65.visual.force.com/servlet/servlet.ImageServer?id=0150m000000AN8V&oid=00D0m000000Cra6"/>    </td>  </tr><tr valign="top"><td id="accent1" style=" background-color:#FFFFFF; color:#FFFFFF; height:5px; " ></tr><tr valign="top"><td height="300" style=" background-color:#FFFFFF; font-family:arial; font-size:12pt; color:#000000; " ><table border="0" cellpadding="5" width="550" cellspacing="5" height="400"><tr valign="top" height="400"><td id="main" style=" background-color:#FFFFFF; font-family:arial; font-size:12pt; color:#000000; " >[[DONT_DELETE_CONTENT_HERE]]</td></tr></table></td></tr><tr valign="top"><td id="accent2" style=" background-color:#FFFFFF; color:#FFFFFF; height:5px; " ></tr>  <tr valign="top">    <td id="footer" style=" background-color:#FFFFFF; color:#FFFFFF; height:100px; " >    </td>  </tr><tr valign="top"><td id="accent3" style=" background-color:#FFFFFF; color:#FFFFFF; height:5px; " ></tr></table></center></body>',
                summit__Event__c = evtInst.summit__Event__c
        );

        List<OrgWideEmailAddress> oweList = [SELECT Id, Address,DisplayName, IsAllowAllProfiles FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = TRUE];

        if (oweList.size() > 0) {
            testEvtEmail.summit__Org_Email_Id__c = oweList[0].Id;
        }

        insert testEvtEmail;

        return testEvtEmail;

    }

    public static Contact createContact(String firstName, String preferredFirst, String lastName, String Email, String Zip, String Phone, String DOB, String ClassYear) {

        Account a = new Account(Name = firstName + ' ' + lastName + ' Account Name');
        insert a;

        //Creating a student contact
        Contact testContact = new Contact(
                FirstName = firstName,
                LastName = lastName,
                Email = Email,
                MailingStreet = '123 Rock Ave',
                MailingCity = 'Bedrock',
                MailingState = 'MN',
                MailingPostalCode = Zip,
                Phone = Phone,
                Birthdate = Date.valueOf(DOB),
                AccountId = a.Id
        );
        insert testContact;

        return testContact;

    }

    public static summit__Summit_Events_Registration__c createEventRegistration(summit__Summit_Events_Instance__c evtI, String firstName, String lastName, String Email, String Zip, String DOB, String ClassYear, Id optionalContactLinkId) {

        summit__Summit_Events_Registration__c testRegistration = new summit__Summit_Events_Registration__c(
                summit__Event__c = evtI.summit__Event__c,
                summit__Event_Instance__c = evtI.Id,
                summit__Registrant_Email__c = Email,
                summit__Registrant_First_Name__c = firstName,
                summit__Registrant_Last_Name__c = lastName,
                summit__Registrant_Zip__c = Zip,
                summit__Registrant_Postal_Code__c = Zip,
                summit__Registrant_Street_1__c = '123 Electric Ave',
                summit__Registrant_Street_2__c = 'Apartment C',
                summit__Registrant_City__c = 'Beach City',
                summit__Registrant_State__c = 'MN',
                summit__Registrant_High_School_Code__c = '000000',
                summit__Registrant_Date_of_Birth__c = Date.valueOf(DOB),
                summit__Preferred_Class_Year__c = ClassYear,
                summit__Status__c = 'Started',
                summit__Registrant_Third_Party_Status__c = 'Primary Registrant'
        );
        insert testRegistration;

        //create encrypted string
        TouchNetHelper tNHelper = new TouchNetHelper();
        String encryptedString = tNHelper.createEncryptedCookie('', testRegistration.summit__Event_Instance__c, testRegistration.summit__Event__c, testRegistration.Id);

        if (encryptedString.length() > 255) {
            testRegistration.summit__Encrypted_Registration_Id_1__c = encryptedString.substring(0, 255);
            testRegistration.summit__Encrypted_Registration_Id_2__c = encryptedString.substring(255, encryptedString.length());
        } else {
            testRegistration.summit__Encrypted_Registration_Id_1__c = encryptedString;
        }
        update testRegistration;

        if (optionalContactLinkId != null) {
            testRegistration.summit__Contact__c = optionalContactLinkId;
            upsert testRegistration;
        }
        return testRegistration;
    }

    static Integer s_num = 1;

    public static String getFakeId(Schema.SObjectType sot) {
        String result = String.valueOf(s_num++);
        return sot.getDescribe().getKeyPrefix() +
                '0'.repeat(12 - result.length()) + result;
    }

    public static List<summit__Summit_Events_Fee_Allocation__c> AddFeesToEvent(Id eventId) {
        summit__Summit_Events__c seaTestEvent = [
                SELECT Id, summit__Event_Fee__c, summit__Event_Fee_Additional__c, summit__Event_Fee_Allocation__c, summit__Event_Fee_Additional_Allocation__c
                FROM summit__Summit_Events__c
                WHERE Id = :eventId
        ];

        List<summit__Summit_Events_Fee_Allocation__c> testFeeAllocations = new List<summit__Summit_Events_Fee_Allocation__c>();
        for (Integer x = 0; x < 10; x++) {
            summit__Summit_Events_Fee_Allocation__c feeAllocation = new summit__Summit_Events_Fee_Allocation__c();
            feeAllocation.Name = 'Test Allocation ' + x;
            testFeeAllocations.add(feeAllocation);
        }
        insert testFeeAllocations;

        seaTestEvent.summit__Event_Fee__c = 100.00;
        seaTestEvent.summit__Event_Fee_Allocation__c = testFeeAllocations[0].Id;
        seaTestEvent.summit__Event_Fee_Additional__c = 50.00;
        seaTestEvent.summit__Event_Fee_Additional_Allocation__c = testFeeAllocations[1].Id;
        upsert seaTestEvent;

        return testFeeAllocations;

    }

    public static void AddDonationsToEvents(Id eventId, List<summit__Summit_Events_Fee_Allocation__c> testFeeAllocations) {
        summit__Summit_Events__c seaTestEvent = [
                SELECT Id, summit__Event_Fee__c, summit__Event_Fee_Additional__c, summit__Event_Fee_Allocation__c, summit__Event_Fee_Additional_Allocation__c,
                        summit__Donation_Allocation_1__c,summit__Donation_Allocation_2__c,summit__Donation_Allocation_3__c,summit__Donation_Allocation_4__c,summit__Donation_Allocation_5__c,
                        summit__Donation_Description__c, summit__Donation_Suggested_Amount_List__c, summit__Display_Optional_Donation__c, summit__Donation_Title__c
                FROM summit__Summit_Events__c
                WHERE Id = :eventId
        ];

        seaTestEvent.summit__Donation_Description__c = 'Test Donation Description';
        seaTestEvent.summit__Display_Optional_Donation__c = true;
        seaTestEvent.summit__Donation_Suggested_Amount_List__c = '100\n200\n300\n400\n';
        seaTestEvent.summit__Donation_Title__c = 'Test Donation Title';
        seaTestEvent.summit__Donation_Allocation_1__c = testFeeAllocations[1].Id;
        seaTestEvent.summit__Donation_Allocation_2__c = testFeeAllocations[2].Id;
        seaTestEvent.summit__Donation_Allocation_3__c = testFeeAllocations[3].Id;
        seaTestEvent.summit__Donation_Allocation_4__c = testFeeAllocations[4].Id;
        seaTestEvent.summit__Donation_Allocation_5__c = testFeeAllocations[5].Id;

        upsert seaTestEvent;
    }

    private static User buildUser(String username, String alias, String profileName) {
        // Profile p = [SELECT Id, Name FROM Profile WHERE Name = :profileName];
        Profile p;

        p = [SELECT Id,Name FROM Profile WHERE Name = :profileName];

        return new User(
                Alias = alias,
                Username = username,
                LastName = 'LM',
                Email = 'example@example-213213.com',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago',
                ProfileId = p.Id
        );
    }

    public static User userToRunWith(String profileName, String PermissionSetToAdd) {

        User u2 = buildUser('example1@sfdx-test.com', 'lm', 'System Administrator');
        insert u2;

        System.runAs(u2) {
            User u3 = buildUser('example2@sfdx-test.com', 'ceo', profileName);
            insert u3;
            if (String.isNotBlank(PermissionSetToAdd)) {
                List<PermissionSet> seaGuestPermissions = [SELECT Id, Name FROM PermissionSet WHERE Name = :PermissionSetToAdd];
                Id permId = seaGuestPermissions[0].Id;
                PermissionSetAssignment permissionSetChange = new PermissionSetAssignment();
                permissionSetChange.AssigneeId = u3.Id;
                permissionSetChange.PermissionSetId = permId;
                insert permissionSetChange;
            }
            return u3;
        }
        return null;
    }

}