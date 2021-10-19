/**
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 10/15/2021.
 */


public with sharing class TouchNetPaymentProcessController {
    private Map<String, String> params;
    public String upayURL { get; set; }
    public String upayId { get; set; }
    /*Below are all private attribute*/
    private String touchNetService;
    private String gatewayOrigin;
    private Map<String, String> mapResponse = new Map<String, String>();

    public TouchNetPaymentProcessController() {

    }

    public PageReference checkReturnedHeader() {
        PageReference pageRedirect = null;
        Touchnet_Payment_Gateway__c touchnetSettings = Touchnet_Payment_Gateway__c.getOrgDefaults();
        touchNetService = touchnetSettings.Tlink_URL__c;
        upayURL = touchnetSettings.Upay_URL__c;
        upayId = touchnetSettings.Upay_Id__c;
        gatewayOrigin = touchnetSettings.Gateway_Origin__c;

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
        System.debug(ApexPages.currentPage().getParameters().get('eventInfo'));
        if (String.isNotBlank(ApexPages.currentPage().getParameters().get('eventInfo'))) {
            eventInfo = TouchNetHelper.getSummitEventsInfo(ApexPages.currentPage().getParameters().get('eventInfo'));
        }
        System.debug(JSON.serializePretty(eventInfo));
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
            Http h = new Http();
            HttpRequest r = new HttpRequest();
            r.setTimeout(120000); // timeout in milliseconds
            r.setEndpoint(touchNetService);
            r.setHeader('Authorization', TouchNetHelper.getAuthorizationHeader());
            r.setHeader('SOAPAction', touchNetService);
            r.setMethod('GET');
            r.setBody(envelop);
            HttpResponse resp = h.send(r);
            Dom.Document doc = resp.getBodyDocument();
            Dom.XmlNode root = doc.getRootElement();
            iterateThroughXML(root);
            if (mapResponse.containsKey('receiptNumber') && mapResponse.get('receiptNumber') != '') {
                //Check if receipt already exists on payment
                summit__Summit_Events_Payment__c registrationPaymentCheck = [
                        SELECT Id, summit__TouchnetReceiptNumber__c, summit__Event_Registration__c
                        FROM summit__Summit_Events_Payment__c
                        WHERE summit__Event_Registration__c = :eventInfo.registrationId
                        AND summit__TouchnetReceiptNumber__c = :mapResponse.get('receiptNumber')
                ];

                if (registrationPaymentCheck != null) {


                    summit__Summit_Events_Payment__c paymentInformation = new summit__Summit_Events_Payment__c();
                    //feeTypeInfo = getTransactionFeeName();
                    sp = Database.setSavepoint();

                    paymentInformation.summit__Event_Registration__c = eventInfo.registrationId;
                    paymentInformation.summit__Address_1__c = params.get('acct_addr');
                    paymentInformation.summit__Address_2__c = params.get('acct_addr2');
                    paymentInformation.summit__City__c = params.get('acct_city');
                    paymentInformation.summit__Country__c = params.get('acct_country');
                    paymentInformation.summit__Email_Address__c = params.get('acct_email_address');
                    paymentInformation.summit__Account_Number__c = params.get('acct_number');
                    paymentInformation.summit__Phone__c = params.get('acct_phone_mobile');
                    paymentInformation.summit__State__c = params.get('acct_state');
                    paymentInformation.summit__Zip__c = params.get('acct_zip');
                    paymentInformation.summit__Card_Type__c = params.get('card_type');
                    paymentInformation.summit__Name_On_Account__c = params.get('name_on_acct');
                    paymentInformation.summit__Payment_Amount__c = Decimal.valueOf(params.get('pmt_amt'));
                    paymentInformation.summit__Payment_Method__c = params.get('pmt_method');
                    paymentInformation.summit__Payment_Method_Expiration_Date__c = params.get('pmt_method_exp_date');
                    paymentInformation.summit__Gateway_Session_Identifier__c = params.get('session_identifier');
                    paymentInformation.summit__TouchnetReceiptNumber__c = mapResponse.get('receiptNumber');
                    paymentInformation.summit__GatewayApprovalCode__c = mapResponse.get('approvalCode');
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
                pageRedirect = new PageReference(TouchNetHelper.getSeaCommunityURL() + 'summit__SummitEventsConfirmation');
                pageRedirect.setRedirect(true);

            } else {
                pageRedirect = new PageReference(TouchNetHelper.getSeaCommunityURL() + 'summit__SummitEventsSubmit&error=' + EncodingUtil.urlEncode('Transaction was not successful, please try again.', 'UTF-8'));
                pageRedirect.setRedirect(true);
            }
        } catch (Exception ex) {
            pageRedirect = new PageReference(TouchNetHelper.getSeaCommunityURL() + 'summit__SummitEventsSubmit&error=' + EncodingUtil.urlEncode('Tayment can not be processed, please again. ' + ex.getMessage(), 'UTF-8'));
            pageRedirect.setRedirect(true);
            if (sp != null) {
                Database.rollback(sp);
            }
        }
        return pageRedirect;
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

    private without sharing class doCRUD {

        public void updateFees(List<summit__Summit_Events_Fee__c> upsertableFees) {
            try {
                upsert upsertableFees;
            } catch (Exception ex) {
                System.debug(JSON.serializePretty(ex.getMessage()));
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, ex.getMessage());
                ApexPages.addMessage(myMsg);
            }
        }

        public void createPaymentRecord(summit__Summit_Events_Payment__c payment) {
            try {
                System.debug(JSON.serializePretty(payment));
                insert payment;
            } catch (Exception ex) {
                System.debug(JSON.serializePretty(ex.getMessage()));
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, ex.getMessage());
                ApexPages.addMessage(myMsg);
            }
        }
    }
}