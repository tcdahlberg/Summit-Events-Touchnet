/**
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

    public static String getSeaCommunityURL() {
        summit__Summit_Events_Settings__c myUserSetting = summit__Summit_Events_Settings__c.getInstance(UserInfo.getUserId());
        String communityBaseURL  = myUserSetting.summit__Community_Base_URL__c;
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


    public static TouchNetHelper.SummitEventsInfo getSummitEventsInfo() {
        //{"audience":"High School Senior","instanceId":"a320m000000A5fOAAS","registrationId":"a350m0000008q63AAA,"eventId":"a330m0000001SOrAAM"}
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

    public static TouchNetHelper.SummitEventsInfo getSummitEventsInfo(String eventInfo) {
        TouchNetHelper.SummitEventsInfo eventInformation = new TouchNetHelper.SummitEventsInfo();
        String jsonInput = decryptString(eventInfo,false);
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
            if(decrypt) {
                return decryptString(encodedCipherText.getValue(), true);
            } else {
                return encodedCipherText.getValue();
            }
        }
        return '';
    }

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
                return '';
            }
        }
        return '';
    }


}