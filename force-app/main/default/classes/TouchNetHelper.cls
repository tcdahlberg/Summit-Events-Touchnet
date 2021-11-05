/**
 * Copyright 2021 University of St. Thomas - Minnesota. All rights reserved.
 * Use of this source code is governed by a BSD Revised
 * license that can be found in the LICENSE file.
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 10/15/2021.
 */

public with sharing class TouchNetHelper {

    public class SummitEventsInfo {
        public String audience { get; set; }
        public String instanceId { get; set; }
        public String eventId { get; set; }
        public String registrationId { get; set; }
        public String dt { get; set; }
    }

    // Get the site url where Summit Events App lives
    public static String getSeaCommunityURL() {
        summit__Summit_Events_Settings__c myUserSetting = summit__Summit_Events_Settings__c.getInstance(UserInfo.getUserId());
        String communityBaseURL = myUserSetting.summit__Community_Base_URL__c;
        if (!communityBaseURL.endsWith('/')) {
            communityBaseURL += '/';
        }
        return communityBaseURL;
    }

    public static String getAuthorizationHeader() {
        Touchnet_Payment_Gateway__c touchnetSettings = Touchnet_Payment_Gateway__c.getOrgDefaults();
        Blob headerValue = Blob.valueOf(touchnetSettings.Validation_Key__c);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        return authorizationHeader;
    }

    // Retrieves from an encrypted cookie the event information for the current registration
    // {"audience":"High School Senior","instanceId":"a320m000000A5fOAAS","registrationId":"a350m0000008q63AAA,"eventId":"a330m0000001SOrAAM"}
    public static TouchNetHelper.SummitEventsInfo getSummitEventsInfo() {

        TouchNetHelper.SummitEventsInfo eventInformation = new TouchNetHelper.SummitEventsInfo();
        String jsonInput = getSeaCookie(true);
        //See if a cookie exists
        if (String.isNotBlank(jsonInput)) {
            try {
                eventInformation = (TouchNetHelper.SummitEventsInfo) JSON.deserialize(jsonInput, TouchNetHelper.SummitEventsInfo.class);
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }
        return eventInformation;
    }

    public String createEncryptedCookie(String audience, String instanceId, String eventId, String registrationId) {

        //Check everything to not let nulls through to JSON string
        audience = (String.isNotBlank(audience) && !audience.equalsIgnoreCase('null')) ? audience : '';
        instanceId = (String.isNotBlank(instanceId) && !instanceId.equalsIgnoreCase('null')) ? instanceId : '';
        eventId = (String.isNotBlank(eventId) && !eventId.equalsIgnoreCase('null')) ? eventId : '';
        registrationId = (String.isNotBlank(registrationId) && !registrationId.equalsIgnoreCase('null')) ? registrationId : '';
        String CookieValue = '{"audience":"' + audience + '","instanceId":"' + instanceId + '","eventId":"' + eventId + '","registrationId":"' + registrationId + '","dt":"' + String.valueOf(Datetime.now()) + '"}';
        System.debug(CookieValue);
        String encodedCipherText = '';
        summit__Summit_Events_Settings__c SummitEventsSettings = summit__Summit_Events_Settings__c.getOrgDefaults();
        String key = '';
        if (String.isNotBlank(SummitEventsSettings.summit__Cookie_Encryption_Key__c)) {
            key = SummitEventsSettings.summit__Cookie_Encryption_Key__c;
        }
        if (String.isNotBlank(String.valueOf(key))) {
            Blob data = Blob.valueOf(CookieValue);
            Blob encrypted = Crypto.encryptWithManagedIV('AES256', Blob.valueOf(key), data);
            encodedCipherText = EncodingUtil.base64Encode(encrypted);
            encodedCipherText = EncodingUtil.urlEncode(encodedCipherText, 'UTF-8');
            Cookie SummitEventsCookie = new Cookie('SummitEvents', encodedCipherText, null, -1, false);
            ApexPages.currentPage().setCookies(new Cookie[]{
                    SummitEventsCookie
            });
        }
        return encodedCipherText;
    }

    // Retrieves event information from an encrypted string passed to method
    // {"audience":"High School Senior","instanceId":"a320m000000A5fOAAS","registrationId":"a350m0000008q63AAA,"eventId":"a330m0000001SOrAAM"}
    public static TouchNetHelper.SummitEventsInfo getSummitEventsInfo(String eventInfo) {
        TouchNetHelper.SummitEventsInfo eventInformation = new TouchNetHelper.SummitEventsInfo();
        String jsonInput = decryptString(eventInfo, false);
        if (String.isNotBlank(jsonInput)) {
            try {
                eventInformation = (TouchNetHelper.SummitEventsInfo) JSON.deserialize(jsonInput, TouchNetHelper.SummitEventsInfo.class);
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }
        return eventInformation;
    }

    public static String getSeaCookie(Boolean decrypt) {
        Cookie encodedCipherText = ApexPages.currentPage().getCookies().get('SummitEvents');
        if (encodedCipherText != null) {
            if (decrypt) {
                return decryptString(encodedCipherText.getValue(), true);
            } else {
                return encodedCipherText.getValue();
            }
        }
        return '';
    }

    // Decrypts using Summit Events custom setting encryption key (unique to each org)
    public static String decryptString(String encryptedString, Boolean urlDecodeString) {
        String key = '';
        summit__Summit_Events_Settings__c SummitEventsSettings = summit__Summit_Events_Settings__c.getOrgDefaults();
        if (String.isNotBlank(SummitEventsSettings.summit__Cookie_Encryption_Key__c)) {
            key = SummitEventsSettings.summit__Cookie_Encryption_Key__c;
        }
        if (String.isNotBlank(encryptedString) && String.isNotBlank(String.valueOf(key))) {
            if (urlDecodeString) {
                encryptedString = EncodingUtil.urlDecode(encryptedString, 'UTF-8');
            }
            try {
                Blob decrypted = Crypto.decryptWithManagedIV(
                        'AES256',
                        Blob.valueOf(key),
                        EncodingUtil.base64Decode(encryptedString)
                );
                return decrypted.toString();
            } catch (Exception e) {
            }
        }
        return '';
    }
}