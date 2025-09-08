/**
 * Copyright 2021 University of St. Thomas - Minnesota. All rights reserved.
 * Use of this source code is governed by a BSD Revised
 * license that can be found in the LICENSE file.
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 10/15/2021.
 */


public without sharing class TouchNetPaymentProcessController {
    private Map<String, String> params;
    public String uPayURL { get; set; }
    public String uPayId { get; set; }
    /*Below are all private attribute*/
    private String touchNetService;
    private String gatewayOrigin;
    private final Map<String, String> mapResponse = new Map<String, String>();

    public TouchNetPaymentProcessController() {

    }

    public PageReference checkReturnedHeader() {
        PageReference pageRedirect = null;
        TouchNet_Payment_Gateway__c touchNetSettings = TouchNet_Payment_Gateway__c.getOrgDefaults();
        touchNetService = touchNetSettings.TLink_URL__c;
        uPayURL = touchNetSettings.UPay_URL__c;
        uPayId = touchNetSettings.UPay_Id__c;
        gatewayOrigin = touchNetSettings.Gateway_Origin__c;

        /** Check for postback of payment gateway **/
        params = ApexPages.currentPage().getParameters();
        Map<String, String> returnHeaders = ApexPages.currentPage().getHeaders();
        if (!returnHeaders.isEmpty()) {
            if (returnHeaders.get('Referer') != null) {
                String returnedReferrer = returnHeaders.get('Referer').toLowerCase();
                if (String.isNotBlank(returnedReferrer)) {
                    if (String.isBlank(gatewayOrigin)) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Set your orgs gateway settings or fees will not be collected.'));
                    } else {
                        if (returnedReferrer.trim().contains(gatewayOrigin)) {
                            /** Check for session identifier to see if a payment was successful **/
                            if (params.get('session_identifier') != null) {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Your payment is processing. Please do not refresh the page.'));
                                pageRedirect = addPaymentInformation();
                            } else {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Your payment is processing was unsuccessful. Please try again.'));
                            }
                        }
                    }
                }
            }
        }
        return pageRedirect;
    }

    public PageReference addPaymentInformation() {
        PageReference pageRedirect = null;
        Savepoint sp = null;
        doCRUD CRUDtoDo = new doCRUD();
        TouchNetHelper.SummitEventsInfo eventInfo = new TouchNetHelper.SummitEventsInfo();
        if (String.isNotBlank(ApexPages.currentPage().getParameters().get('eventInfo'))) {
            eventInfo = TouchNetHelper.getSummitEventsInfo(ApexPages.currentPage().getParameters().get('eventInfo'));
        }

        String encryptedEventInfo = EncodingUtil.urlEncode(TouchNetHelper.getSeaCookie(false), 'UTF-8');

        try {
            String envelop = '';
            envelop += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://types.secureLink.touchnet.com">';
            envelop += '    <soapenv:Header/>';
            envelop += '    <soapenv:Body>';
            envelop += '        <typ:authorizeAccountRequest>';
            envelop += '            <typ:session>' + params.get('session_identifier') + '</typ:session>';
            envelop += '            <typ:invoiceNumber>' + eventInfo.registrationId + '</typ:invoiceNumber>';
            envelop += '            </typ:authorizeAccountRequest>';
            envelop += '    </soapenv:Body>';
            envelop += '</soapenv:Envelope>';

            requestTicket(envelop);

            if (mapResponse.containsKey('receiptNumber') && mapResponse.get('receiptNumber') != '') {

                //Check if receipt already exists on payment and don't double record
                List<summit__Summit_Events_Payment__c> registrationPaymentCheck = [
                        SELECT Id, summit__TouchnetReceiptNumber__c, summit__Event_Registration__c
                        FROM summit__Summit_Events_Payment__c
                        WHERE summit__Event_Registration__c = :eventInfo.registrationId
                        AND summit__TouchnetReceiptNumber__c = :mapResponse.get('receiptNumber')
                ];

                if (registrationPaymentCheck.size() < 1) {

                    summit__Summit_Events_Payment__c paymentInformation = new summit__Summit_Events_Payment__c();
                    //feeTypeInfo = getTransactionFeeName();
                    sp = Database.setSavepoint();

                    //URL parameters
                    paymentInformation.summit__Gateway_Session_Identifier__c = params.get('session_identifier');
                    paymentInformation.summit__Phone__c = params.get('acct_phone_mobile');
                    paymentInformation.summit__Payment_Method__c = params.get('pmt_method');
                    paymentInformation.summit__Payment_Method_Expiration_Date__c = params.get('pmt_method_exp_date');

                    if (mapResponse.containsKey('BILL_NAME')) {
                        paymentInformation.summit__Name_On_Account__c = mapResponse.get('BILL_NAME');
                    }
                    if (mapResponse.containsKey('BILL_STREET1')) {
                        paymentInformation.summit__Address_1__c = mapResponse.get('BILL_STREET1');
                    }
                    if (mapResponse.containsKey('BILL_STREET2')) {
                        paymentInformation.summit__Address_2__c = mapResponse.get('BILL_STREET2');
                    }
                    if (mapResponse.containsKey('BILL_CITY')) {
                        paymentInformation.summit__City__c = mapResponse.get('BILL_CITY');
                    }
                    if (mapResponse.containsKey('BILL_COUNTRY')) {
                        paymentInformation.summit__Country__c = mapResponse.get('BILL_COUNTRY');
                    }
                    if (mapResponse.containsKey('BILL_EMAIL_ADDRESS')) {
                        paymentInformation.summit__Email_Address__c = mapResponse.get('BILL_EMAIL_ADDRESS');
                    }
                    if (mapResponse.containsKey('BILL_STATE')) {
                        paymentInformation.summit__State__c = mapResponse.get('BILL_STATE');
                    }
                    if (mapResponse.containsKey('BILL_POSTAL_CODE')) {
                        paymentInformation.summit__Zip__c = mapResponse.get('BILL_POSTAL_CODE');
                    }
                    if (mapResponse.containsKey('creditCardType')) {
                        paymentInformation.summit__Card_Type__c = mapResponse.get('creditCardType');
                    }
                    if (mapResponse.containsKey('maskedAccountNumber')) {
                        paymentInformation.summit__Account_Number__c = mapResponse.get('maskedAccountNumber');
                    }
                    if (mapResponse.containsKey('AMT')) {
                        paymentInformation.summit__Payment_Amount__c = Decimal.valueOf(mapResponse.get('AMT'));
                    }
                    if (mapResponse.containsKey('receiptNumber')) {
                        paymentInformation.summit__TouchnetReceiptNumber__c = mapResponse.get('receiptNumber');
                    }
                    if (mapResponse.containsKey('approvalCode')) {
                        paymentInformation.summit__GatewayApprovalCode__c = mapResponse.get('approvalCode');
                    }

                    paymentInformation.summit__Event_Registration__c = eventInfo.registrationId;
                    paymentInformation.summit__Method_of_Payment__c = 'Credit Card';
                    paymentInformation.summit__Payment_Status__c = 'Received';
                    paymentInformation.summit__Payment_Received_Date__c = System.now();
                    CRUDtoDo.createPaymentRecord(paymentInformation);

                    List<summit__Summit_Events_Fee__c> eventFees = [
                            SELECT Name, summit__Event_Fee__c, summit__Event_Fee_Allocation__c, summit__Description__c, summit__Event_Fee_Type__c, summit__Summit_Events__c, summit__Event_Appointment_Type__c,
                                    summit__Event_Appointment_Type__r.summit__Title__c, summit__Event_Fee_Allocation__r.Name
                            FROM summit__Summit_Events_Fee__c
                            WHERE summit__Event_Registration__c = :eventInfo.registrationId
                    ];

                    //Update fees to connect the payment record to them.
                    for (Integer fi = 0; fi < eventFees.size(); fi++) {
                        eventFees[fi].summit__Summit_Events_Payment__c = paymentInformation.Id;
                        eventFees[fi].summit__Summit_Events__c = eventInfo.eventId;
                    }
                    CRUDtoDo.updateFees(eventFees);
                }
                pageRedirect = new PageReference(TouchNetHelper.getSeaCommunityURL() + 'summit__SummitEventsConfirmation?eventInfo=' + encryptedEventInfo);
            } else {
                pageRedirect = new PageReference(TouchNetHelper.getSeaCommunityURL() + 'summit__SummitEventsSubmit?eventInfo=' + encryptedEventInfo + '&amp;error=' + EncodingUtil.urlEncode('Transaction was not successful, please try again.', 'UTF-8'));
            }
        } catch (Exception ex) {
            pageRedirect = new PageReference(TouchNetHelper.getSeaCommunityURL() + 'summit__SummitEventsSubmit?eventInfo=' + encryptedEventInfo + '&amp;error=' + EncodingUtil.urlEncode('Payment can not be processed, please try again. ' + ex.getMessage(), 'UTF-8'));
            if (sp != null) {
                Database.rollback(sp);
            }
        }
        if (pageRedirect != null) {
            pageRedirect.setRedirect(true);
        }
        return pageRedirect;
    }

    private void iterateThroughXML(Dom.XmlNode root) {
        for (Dom.XmlNode childElement : root.getChildElements()) {
            for (Dom.XmlNode detailElement : childElement.getChildElements()) {
                if (detailElement.getName() == 'authorizeAccountResponse') {
                    for (Dom.XmlNode detailElement2 : detailElement.getChildElements()) {
                        Integer pairCount = 1;
                        if (detailElement2.getName() == 'nameValuePairs') {
                            String mapName = '';
                            for (Dom.XmlNode detailElement3 : detailElement2.getChildElements()) {
                                if (pairCount == 1) {
                                    mapName = detailElement3.getText();
                                }
                                if (pairCount == 2) {
                                    mapResponse.put(mapName, detailElement3.getText());
                                    pairCount = 0;
                                }
                                pairCount++;
                            }
                        } else if (detailElement2.getName() == 'creditResponse') {
                            for (Dom.XmlNode detailElement3 : detailElement2.getChildElements()) {
                                if (detailElement3.getName() == 'creditCardInfo') {
                                    for (Dom.XmlNode detailElement4 : detailElement3.getChildElements()) {
                                        mapResponse.put(detailElement4.getName(), detailElement4.getText());
                                    }
                                } else {
                                    mapResponse.put(detailElement3.getName(), detailElement3.getText());
                                }
                            }
                        } else {
                            mapResponse.put(detailElement2.getName(), detailElement2.getText());
                        }
                    }
                }
            }
        }
        System.debug(mapResponse);
    }

    public void requestTicket(String envelop) {
        try {
            Http h = new Http();
            HttpRequest r = new HttpRequest();
            r.setEndpoint('callout:Summit_Events_TouchNet');
/*            r.setEndpoint(touchNetService);
            r.setHeader('Authorization', TouchNetHelper.getAuthorizationHeader());
            r.setHeader('SOAPAction', touchNetService);*/
            r.setMethod('GET');
            r.setBody(envelop);
            HttpResponse resp = h.send(r);
            Dom.Document doc = resp.getBodyDocument();
            //System.debug(resp.getBodyAsBlob().toString());
            Dom.XmlNode root = doc.getRootElement();
            System.debug( root.getText());
            iterateThroughXML(root);
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Error connecting payment gateway, please try later. ' + ex.getMessage()));
        }
    }

    private without sharing class doCRUD {

        public void updateFees(List<summit__Summit_Events_Fee__c> fees) {
            try {
                upsert fees;
            } catch (Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ex.getMessage()));
            }
        }

        public void createPaymentRecord(summit__Summit_Events_Payment__c payment) {
            try {
                insert payment;
            } catch (Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ex.getMessage()));
            }
        }
    }
}