/**
 * Copyright 2021 University of St. Thomas - Minnesota. All rights reserved.
 * Use of this source code is governed by a BSD Revised
 * license that can be found in the LICENSE file.
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 10/12/2021.
 */

public without sharing class TouchNetController {

    public TouchNetHelper.SummitEventsInfo eventInfo { get; set; }
    public summit__Summit_Events__c eventPage { get; set; }
    public summit__Summit_Events_Registration__c eventRegistration { get; set; }
    public summit__Summit_Events_Instance__c evtInstance { get; set; }
    public String templateSelected { get; set; }
    public Map <String, String> feesByIndex { get; set; }

    /*Below are all private attribute*/
    private String touchNetService;
    private String gatewayOrigin;
    private Map<String, String> mapResponse = new Map<String, String>();
    private List<summit__Summit_Events_Fee__c> eventFees { get; set; }

    /*Below are all public get;set; attribute*/
    public String uPayURL { get; set; }
    public String uPayId { get; set; }
    public String ticket { get; set; }
    public String ticketName { get; set; }
    public Double totalPaymentAmount { get; set; }
    public Double existingPaymentAmount { get; set; }
    public Double eventOnlyPaymentAmount { get; set; }
    public Boolean showPaymentButton { get; set; }
    public String goBackLink { get; set; }

    public TouchNetController() {
        getDefaultEventInfo();
        if (totalPaymentAmount > 0) {
            showPaymentButton = true;
            String envelop = generateEnvelop();
            ticket = requestTicket(envelop);
            System.debug('TICKET : ' + ticket);
        }
    }

    public PageReference checkDefaultEventInfo() {
        PageReference pageRedirect = null;
        getDefaultEventInfo();
        if (String.isBlank(touchNetService) || String.isBlank(uPayURL) || String.isBlank(uPayId) || String.isBlank(gatewayOrigin)) {
            pageRedirect = new PageReference(TouchNetHelper.getSeaCommunityURL() + 'summit__SummitEventsSubmit?error=' + EncodingUtil.urlEncode('Error: Payment gateway setup information is incomplete.', 'UTF-8'));
            pageRedirect.setRedirect(true);
        } else if (String.isBlank(eventInfo.eventId)) {
            pageRedirect = new PageReference(TouchNetHelper.getSeaCommunityURL() + 'summit__SummitEventsSubmit?error=' + EncodingUtil.urlEncode('Error: Could not detect a registration.', 'UTF-8'));
            pageRedirect.setRedirect(true);
        }
        return pageRedirect;
    }

    public void getDefaultEventInfo() {
        /** Collect Fees **/
        eventInfo = TouchNetHelper.getSummitEventsInfo();
        totalPaymentAmount = 0;
        /** Get custom settings for Summit Events **/
        TouchNet_Payment_Gateway__c touchNetSettings = TouchNet_Payment_Gateway__c.getOrgDefaults();
        touchNetService = touchNetSettings.TLink_URL__c;
        uPayURL = touchNetSettings.UPay_URL__c;
        uPayId = touchNetSettings.UPay_Id__c;
        gatewayOrigin = touchNetSettings.Gateway_Origin__c;
        if (String.isBlank(touchNetService) || String.isBlank(uPayURL) || String.isBlank(uPayId) || String.isBlank(gatewayOrigin)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Error: Payment gateway setup information is incomplete.'));
        } else if (String.isBlank(eventInfo.eventId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Error: Could not detect a registration.'));
        } else {
            eventPage = [
                    SELECT summit__Event_Name__c, summit__Event_Submit_Title__c, summit__Event_Submit_Description__c, summit__Event_Footer__c, summit__Template__c,
                            summit__Event_Home_Link_Title__c, summit__Event_Home_Link_URL__c, summit__Tracking_Submit_Registration__c,
                            summit__Donation_Description__c, summit__Display_Optional_Donation__c
                    FROM summit__Summit_Events__c
                    WHERE Id = :eventInfo.eventId
            ];

            templateSelected = eventPage.summit__Template__c;

            evtInstance = [
                    SELECT summit__Instance_Title__c, summit__Event__r.summit__Event_Name__c,
                            summit__Instance_Time_Zone__c, summit__Instance_Start_Time__c, summit__Instance_End_Time__c, summit__Instance_Start_Date__c,
                            summit__Instance_End_Date__c
                    FROM summit__Summit_Events_Instance__c
                    WHERE Id = :eventInfo.instanceId
            ];

            eventFees = [
                    SELECT Name, summit__Event_Fee__c, summit__Event_Fee_Allocation__c, summit__Description__c, summit__Event_Fee_Type__c, summit__Summit_Events__c, summit__Event_Appointment_Type__c,
                            summit__Event_Appointment_Type__r.summit__Title__c, summit__Event_Fee_Allocation__r.Name
                    FROM summit__Summit_Events_Fee__c
                    WHERE summit__Event_Registration__c = :eventInfo.registrationId
            ];

            /** Get Event registrant information if possible **/
            eventRegistration = [
                    SELECT summit__Registrant_First_Name__c, summit__Registrant_Last_Name__c, summit__Registrant_City__c, summit__Registrant_State_Province__c, summit__Registrant_State__c,
                            summit__Registrant_Postal_Code__c, summit__Registrant_Zip__c, summit__Registrant_Street_1__c, summit__Registrant_Street_2__c, summit__Registrant_Email__c, summit__Registrant_Country__c,
                            summit__Event_Name__c, summit__Event_Instance_Title__c, summit__Event_Instance_Date_Time_Formatted__c
                    FROM summit__Summit_Events_Registration__c
                    WHERE Id = :eventInfo.registrationId
            ];

            goBackLink = TouchNetHelper.getSeaCommunityURL() + 'summit__SummitEventsSubmit';

            /** Check for preexisting payment **/
            List<summit__Summit_Events_Payment__c> existingPayment = [
                    SELECT Id, summit__Payment_Amount__c, summit__TouchnetReceiptNumber__c
                    FROM summit__Summit_Events_Payment__c
                    WHERE summit__Event_Registration__c = :eventInfo.registrationId
            ];

            if (existingPayment.size() > 0) {
                existingPaymentAmount = existingPayment[0].summit__Payment_Amount__c;
            }

            feesByIndex = new Map<String, String>();
            eventOnlyPaymentAmount = 0;
            for (summit__Summit_Events_Fee__c fee : eventFees) {
                if (fee.summit__Event_Fee__c != null && fee.summit__Event_Fee__c > 0) {
                    totalPaymentAmount += fee.summit__Event_Fee__c;
                    if (feesByIndex.size() > 0 && feesByIndex.containsKey(fee.summit__Event_Fee_Allocation__c)) {
                        Decimal newFee = Decimal.valueOf(feesByIndex.get(fee.summit__Event_Fee_Allocation__c));
                        newFee = newFee + fee.summit__Event_Fee__c;
                        newFee = newFee.setScale(2);
                        feesByIndex.put(fee.summit__Event_Fee_Allocation__c, String.valueOf(newFee));
                    } else {
                        feesByIndex.put(fee.summit__Event_Fee_Allocation__c, String.valueOf(fee.summit__Event_Fee__c));
                    }

                }
            }

            if (existingPaymentAmount > 0) {
                totalPaymentAmount = totalPaymentAmount - existingPaymentAmount;
            }
        }
    }

    /* Below is used to generating ticket for TouchNetController */
    public String generateEnvelop() {

        ticketName = 'ThomasTicket';

        String envelop = '';
        envelop = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://types.secureLink.touchnet.com">';
        envelop += '<soapenv:Header/>';
        envelop += '<soapenv:Body>';
        envelop += '    <typ:generateSecureLinkTicketRequest>';
        envelop += '        <typ:ticketName>' + ticketName + '</typ:ticketName>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>AMT</typ:name>';
        envelop += '            <typ:value>' + totalPaymentAmount + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';

        /** Add fees by index code **/
        Integer ff = 0;
        String accountSuffix = '';
        for (String key : feesByIndex.keySet()) {
            if (ff > 0) {
                accountSuffix = '_' + String.valueOf(ff + 1);
            } else {
                accountSuffix = '';
            }
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>CREDIT_ACCT_CODE' + accountSuffix + '</typ:name>';
            envelop += '            <typ:value>' + feesByIndex.get(key) + '</typ:value>';
            envelop += '        </typ:nameValuePairs>';
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>CREDIT_ACCT_AMT' + accountSuffix + '</typ:name>';
            envelop += '            <typ:value>' + key + '</typ:value>';
            envelop += '        </typ:nameValuePairs>';
            ff++;
        }

        /** Pass along customer NAME to pre-fill form. Concat first and last name if they exist with a space between. **/
        if (String.isNotBlank(eventRegistration.summit__Registrant_First_Name__c) || String.isNotBlank(eventRegistration.summit__Registrant_Last_Name__c)) {
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>BILL_NAME</typ:name>';
            envelop += '            <typ:value>';
            if (String.isNotBlank(eventRegistration.summit__Registrant_First_Name__c)) {
                envelop += eventRegistration.summit__Registrant_First_Name__c;

            }
            if (String.isNotBlank(eventRegistration.summit__Registrant_First_Name__c) && String.isNotBlank(eventRegistration.summit__Registrant_Last_Name__c)) {
                envelop += ' ';
            }
            if (String.isNotBlank(eventRegistration.summit__Registrant_Last_Name__c)) {
                envelop += eventRegistration.summit__Registrant_Last_Name__c;
            }
            envelop += '            </typ:value>';
            envelop += '        </typ:nameValuePairs>';
        }


        /** Pass along customer EMAIL to pre-fill form **/
        if (String.isNotBlank(eventRegistration.summit__Registrant_Email__c)) {
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>BILL_EMAIL_ADDRESS</typ:name>';
            envelop += '            <typ:value>' + eventRegistration.summit__Registrant_Email__c + '</typ:value>';
            envelop += '        </typ:nameValuePairs>';
        }

        /** Pass along customer ADDRESS 1 to pre-fill form **/
        if (String.isNotBlank(eventRegistration.summit__Registrant_Street_1__c)) {
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>BILL_STREET1</typ:name>';
            envelop += '            <typ:value>' + eventRegistration.summit__Registrant_Street_1__c + '</typ:value>';
            envelop += '        </typ:nameValuePairs>';
        }

        /** Pass along customer ADDRESS 2 to pre-fill form **/
        if (String.isNotBlank(eventRegistration.summit__Registrant_Street_2__c)) {
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>BILL_STREET2</typ:name>';
            envelop += '            <typ:value>' + eventRegistration.summit__Registrant_Street_2__c + '</typ:value>';
            envelop += '        </typ:nameValuePairs>';
        }

        /** Pass along customer CITY to pre-fill form **/
        if (String.isNotBlank(eventRegistration.summit__Registrant_City__c)) {
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>BILL_CITY</typ:name>';
            envelop += '            <typ:value>' + eventRegistration.summit__Registrant_City__c + '</typ:value>';
            envelop += '        </typ:nameValuePairs>';
        }

        /** Pass along customer STATE to pre-fill form **/
        if (String.isNotBlank(eventRegistration.summit__Registrant_State__c)) {
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>BILL_STATE</typ:name>';
            envelop += '            <typ:value>' + eventRegistration.summit__Registrant_State__c.toUpperCase() + '</typ:value>';
            envelop += '        </typ:nameValuePairs>';
        }

        /** Pass along customer ZIP or POSTAL CODE to pre-fill form **/
        if (String.isNotBlank(eventRegistration.summit__Registrant_Zip__c)) {
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>BILL_POSTAL_CODE</typ:name>';
            envelop += '            <typ:value>' + eventRegistration.summit__Registrant_Zip__c + '</typ:value>';
            envelop += '        </typ:nameValuePairs>';
        } else if (String.isNotBlank(eventRegistration.summit__Registrant_Postal_Code__c)) {
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>BILL_STATE</typ:name>';
            envelop += '            <typ:value>' + eventRegistration.summit__Registrant_Postal_Code__c + '</typ:value>';
            envelop += '        </typ:nameValuePairs>';
        }

        /** Pass along customer COUNTRY to pre-fill form **/
        if (String.isNotBlank(eventRegistration.summit__Registrant_Country__c)) {
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>BILL_COUNTRY</typ:name>';
            if (eventRegistration.summit__Registrant_Country__c.equalsIgnoreCase('united states')) {
                envelop += '            <typ:value>US</typ:value>';
            } else {
                envelop += '            <typ:value>' + eventRegistration.summit__Registrant_Country__c.toLowerCase() + '</typ:value>';
            }
            envelop += '        </typ:nameValuePairs>';
        }

        String encryptedEventInfo = EncodingUtil.urlEncode(TouchNetHelper.getSeaCookie(false), 'UTF-8');
        /** Links where to send on different return status -- All the same? **/
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>SUCCESS_LINK</typ:name>';
        envelop += '            <typ:value>' + TouchNetHelper.getSeaCommunityURL() + 'c__TouchNetPaymentProcess?eventInfo=' + encryptedEventInfo + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>CANCEL_LINK</typ:name>';
        envelop += '            <typ:value>' + TouchNetHelper.getSeaCommunityURL() + 'summit__SummitEventsSubmit?eventInfo=' + encryptedEventInfo + '&amp;error=' + EncodingUtil.urlEncode('Payment Cancelled.', 'UTF-8') + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>ERROR_LINK</typ:name>';
        envelop += '            <typ:value>' + TouchNetHelper.getSeaCommunityURL() + 'c__TouchNetPaymentProcess?eventInfo=' + encryptedEventInfo + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';

        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>EXT_TRANS_ID</typ:name>';
        envelop += '            <typ:value>' + eventInfo.registrationId + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';

        /** Event Label **/
        if (String.isNotBlank(eventRegistration.summit__Event_Name__c) || String.isNotBlank(eventRegistration.summit__Event_Instance_Title__c)) {
            List<String> eventLabel = new List<String>();
            if (String.isNotBlank(eventRegistration.summit__Event_Name__c)) {
                eventLabel.add(eventRegistration.summit__Event_Name__c);
            }
            if (String.isNotBlank(eventRegistration.summit__Event_Instance_Title__c)) {
                eventLabel.add(eventRegistration.summit__Event_Instance_Title__c);
            }
            if (String.isNotBlank(eventRegistration.summit__Event_Instance_Date_Time_Formatted__c)) {
                eventLabel.add(eventRegistration.summit__Event_Instance_Date_Time_Formatted__c);
            }
            envelop += '        <typ:nameValuePairs>';
            envelop += '            <typ:name>EXT_TRANS_ID_LABEL</typ:name>';
            envelop += '            <typ:value>' + String.join(eventLabel, ' - ') + '</typ:value>';
            envelop += '        </typ:nameValuePairs>';
        }

        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>POSTING_KEY</typ:name>';
        envelop += '            <typ:value>' + eventInfo.registrationId + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '    </typ:generateSecureLinkTicketRequest>';
        envelop += '</soapenv:Body>';
        envelop += '</soapenv:Envelope>';

        //System.debug(envelop);
        // Get ride of multiples spaces maintained for readability above
        envelop = envelop.normalizeSpace();
        return envelop;
    }

    public String requestTicket(String envelop) {
        String requestedTicket = '';
        try {
            Http h = new Http();
            HttpRequest r = new HttpRequest();
            r.setEndpoint(touchNetService);
            r.setHeader('Authorization', TouchNetHelper.getAuthorizationHeader());
            r.setHeader('SOAPAction', touchNetService);
            r.setMethod('GET');
            r.setBody(envelop);
            HttpResponse resp = h.send(r);
            Dom.Document doc = resp.getBodyDocument();
            //System.debug(resp.getBodyAsBlob().toString());
            Dom.XmlNode root = doc.getRootElement();
            //System.debug( root.getText());
            iterateThroughXML(root);
            requestedTicket =  mapResponse.get('ticket');
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Error connecting payment gateway, please try later. ' + ex.getMessage()));
        }
        return requestedTicket;
    }

    private void iterateThroughXML(Dom.XmlNode node) {
        if (node.getNodeType() == Dom.XmlNodeType.ELEMENT) {
            if (node.getText().trim() != '') {
                if (!mapResponse.containsKey(node.getName())) {
                    mapResponse.put(node.getName(), node.getText().trim());
                }
            }
            for (Dom.XmlNode child : node.getChildElements()) {
                iterateThroughXML(child);
            }
        }
    }
}