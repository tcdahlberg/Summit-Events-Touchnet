/**
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 10/12/2021.
 */

public with sharing class Touchnet {

    public class SummitEventsInfo {
        public String audience { get; set; }
        public String instanceId { get; set; }
        public String eventId { get; set; }
        public String registrationId { get; set; }
        public String dt { get; set; }
    }
    // public summit__SummitEventsShared SEShared = new summit__SummitEventsShared();
    public String test { get; set; }
    public SummitEventsInfo eventInfo { get; set; }
    public summit__Summit_Events__c eventPage { get; set; }
    public summit__Summit_Events_Registration__c eventRegistration { get; set; }
    public summit__Summit_Events_Instance__c evtInstance { get; set; }
    public List<summit__Summit_Events_Appointments__c> chosenAppts { get; set; }
    public String chosenFormatted { get; set; }
    public String templateSelected { get; set; }
    public String eventStartDateTimeCrumb { get; set; }
    public String communityBaseURL { get; set; }
    public Map <String, String> feesByIndex { get; set; }
    public Boolean eventHasOptions { get; set; }
    public String previousPageURL { get; set; }

    /*Below are all private attribute*/
    private String touchNetService;
    private String gatewayOrigin;
    private Map<String, String> mapResponse = new Map<String, String>();
    private Map<String, String> params;
    private List<summit__Summit_Events_Fee__c> eventFees { get; set; }

    /*Below are all public get;set; attribute*/
    public String upayURL { get; set; }
    public String upayId { get; set; }
    public Boolean successReturnFromGateway { get; set; }
    public String ticket { get; set; }
    public String ticketName { get; set; }
    public Double totalPaymentAmount { get; set; }
    public Double existingPaymentAmount { get; set; }
    public Double eventOnlyPaymentAmount { get; set; }
    public String paymentItemized { get; set; }
    public Boolean showPaymentButton { get; set; }
    public string headers { get; set; }
    public Map <String, String> feesByIndex { get; set; }

    public Touchnet() {
        /** Collect Fees **/
        eventInfo = getSummitEventsInfo();

        /** Get custom settings for Summit Events **/
/*        Summit_Events_Settings__c custSetting = Summit_Events_Settings__c.getOrgDefaults();
        touchNetService = custSetting.Tlink_URL__c;
        upayURL = custSetting.Upay_URL__c;
        upayId = custSetting.UpayId__c;
        gatewayOrigin = custSetting.Gateway_Origin__c;*/

        if (!String.isEmpty(eventInfo.eventId)) {
            eventPage = [
                    SELECT summit__Event_Name__c, summit__Event_Submit_Title__c, summit__Event_Submit_Description__c, summit__Event_Footer__c, summit__Template__c,
                            summit__Event_Home_Link_Title__c, summit__Event_Home_Link_URL__c, summit__Tracking_Submit_Registration__c,
                            summit__Donation_Description__c, summit__Display_Optional_Donation__c
                    FROM summit__Summit_Events__c
                    WHERE Id = :eventInfo.eventId
            ][0];
            templateSelected = eventPage.summit__Template__c;

            evtInstance = [
                    SELECT summit__Instance_Title__c, summit__Event__r.Event_Name__c,
                            summit__Instance_Time_Zone__c, summit__Instance_Start_Time__c, summit__Instance_End_Time__c, summit__Instance_Start_Date__c,
                            summit__Instance_End_Date__c
                    FROM summit__Summit_Events_Instance__c
                    WHERE Id = :eventInfo.instanceId
                    LIMIT 1
            ];

//            if (evtInstance.Start_Date_Time__c != null && evtInstance.End_Date_Time__c != null) {
//                eventStartDateTimeCrumb = evtInstance.Start_Date_Time__c.format('MMMM d, YYYY, h:mm a') + ' - ' + evtInstance.End_Date_Time__c.format('h:mm a');
//            }

            List<summit__Summit_Events_Appointment_Type__c> apptTypes = [
                    SELECT Id
                    FROM summit__Summit_Events_Appointment_Type__c
                    WHERE summit__Summit_Events__c = :eventInfo.eventId
                    AND (summit__Restrict_To_Instance_Title__r.Instance_Title__c = :evtInstance.summit__Instance_Title__c OR summit__Restrict_To_Instance_Title__r.Instance_Title__c = NULL)
            ];

            if (apptTypes.size() > 0) {
                eventHasOptions = true;
            }
        }

        eventFees = [
                SELECT Name, summit__Event_Fee__c, summit__Event_Fee_Allocation__c, summit__Description__c, summit__Event_Fee_Type__c, summit__Summit_Events__c, summit__Event_Appointment_Type__c,
                        summit__Event_Appointment_Type__r.Title__c, summit__Event_Fee_Allocation__r.Name
                FROM summit__Summit_Events_Fee__c
                WHERE summit__Event_Registration__c = :eventInfo.registrationId
        ];
        feesByIndex = new Map<String, String>();
        paymentItemized = '<table class="slds-table slds-table_cell-buffer slds-table_bordered">';
        paymentItemized += '<thead>';
        paymentItemized += '<tr class="slds-line-height_reset">';
        paymentItemized += '<th class="" scope="col">';
        paymentItemized += '<div class="slds-truncate" title="Item">Item</div>';
        paymentItemized += '</th>';
        paymentItemized += '<th class="" scope="col">';
        paymentItemized += '<div class="slds-truncate" title="Fee">Fee</div>';
        paymentItemized += '</th>';
        paymentItemized += '</thead><tbody>';
        eventOnlyPaymentAmount = 0;
        for (summit__Summit_Events_Fee__c fee : eventFees) {
            if (fee.summit__Event_Fee__c != null && fee.summit__Event_Fee__c > 0) {
                totalPaymentAmount += fee.summit__Event_Fee__c;
                if (!fee.summit__Event_Fee_Type__c.equalsIgnoreCase('Event') || !fee.summit__Event_Fee_Type__c.equalsIgnoreCase('Event Additional')) {
                    if (fee.summit__Event_Fee_Type__c.equalsIgnoreCase('Appointment')) {
                        paymentItemized += '<tr class="eventAppointmentCost">';
                        paymentItemized += '<td>' + fee.summit__Event_Appointment_Type__r.summit__Title__c + '</td>';
                        paymentItemized += '<td>' + prettyCurrencyString(fee.summit__Event_Fee__c) + '</td>';
                        paymentItemized += '</tr>';
                    } else if (fee.summit__Event_Fee_Type__c.equalsIgnoreCase('Optional Donation')) {
                        paymentItemized += '<tr class="eventDonation">';
                        paymentItemized += '<td>' + fee.summit__Event_Fee_Type__c;
                        if (String.isNotBlank(fee.summit__Event_Fee_Allocation__r.Name)) {
                            paymentItemized += ' - ' + fee.summit__Event_Fee_Allocation__r.Name;
                        }
                        paymentItemized += '</td>';
                        paymentItemized += '<td>' + prettyCurrencyString(fee.summit__Event_Fee__c) + '</td>';
                        paymentItemized += '</tr>';
                    } else {
                        eventOnlyPaymentAmount += fee.summit__Event_Fee__c;
                    }
                }
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
        getSummitEventsInfo();
    }

    public SummitEventsInfo getSummitEventsInfo() {
        //{"audience":"High School Senior","instanceId":"a320m000000A5fOAAS","registrationId":"a350m0000008q63AAA,"eventId":"a330m0000001SOrAAM"}
        SummitEventsInfo eventInformation = new SummitEventsInfo();
        String jsonInput = getDecryptCookie();
        //See if a cookie exists
        if (String.isNotBlank(jsonInput)) {
            try {
                eventInformation = (SummitEventsInfo) JSON.deserialize(jsonInput, SummitEventsInfo.class);
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }
        return eventInformation;
    }

    public String prettyCurrencyString(Decimal numberIn) {
        String numberOut = '';
        List<String> args = new String[]{
                '0', 'number', '###,###,##0.00'
        };
        numberOut = '$' + String.format(numberIn.format(), args);
        return numberOut;
    }

    public String getDecryptCookie() {
        String CookieName = 'SummitEvents';
        Cookie encodedCipherText = ApexPages.currentPage().getCookies().get(CookieName);
        if (encodedCipherText != null) {
            return decryptString(encodedCipherText.getValue(), true);
        }
        return '';
    }

    public String decryptString(String encryptedString, Boolean urlDecodeString) {
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

    /******* Below is used to generating ticket for Touchnet ********/
    public void generateTicket() {

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

        /** Links where to send on different return status -- All the same? **/
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>SUCCESS_LINK</typ:name>';
        envelop += '            <typ:value>' + communityBaseURL + 'SummitEventsSubmit</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>CANCEL_LINK</typ:name>';
        envelop += '            <typ:value>' + communityBaseURL + 'SummitEventsSubmit</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>ERROR_LINK</typ:name>';
        envelop += '            <typ:value>' + communityBaseURL + 'SummitEventsSubmit</typ:value>';
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

        // Get ride of multiples spaces maintained for readability above
        envelop = envelop.normalizeSpace();

        try {
            Http h = new Http();
            HttpRequest r = new HttpRequest();
            r.setEndpoint(touchNetService);
            r.setHeader('Authorization', getAuthorizationHeader());
            r.setHeader('SOAPAction', touchNetService);
            r.setMethod('GET');
            r.setBody(envelop);
            HttpResponse resp = h.send(r);
            Dom.Document doc = resp.getBodyDocument();
            Dom.XmlNode root = doc.getRootElement();
            walkThrough(root);
            ticket = mapResponse.get('ticket');
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Error connecting payment gateway, please try later!!' + ex.getMessage()));
        }
    }

    private String getAuthorizationHeader() {
        summit__Summit_Events_Settings__c SummitEventsSettings = summit__Summit_Events_Settings__c.getOrgDefaults();

        Blob headerValue = Blob.valueOf('Enrollment:m49g3TEXu');
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);

        /*
        Blob headerValue = Blob.valueOf('Enrollment:' + SummitEventsSettings.Encryption_Key__c.substring(0,9));
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        System.Debug ('AUTH HEADER:  ' + authorizationHeader);
        */

        return authorizationHeader;

    }

    @TestVisible private String walkThrough(Dom.XmlNode node) {
        String result = '\n';
        if (node.getNodeType() == Dom.XmlNodeType.COMMENT) {
            return 'Comment (' + node.getText() + ')';
        }
        if (node.getNodeType() == Dom.XmlNodeType.TEXT) {
            return 'Text (' + node.getText() + ')';
        }
        if (node.getNodeType() == Dom.XmlNodeType.ELEMENT) {
            result += 'Element: ' + node.getName();
            if (node.getText().trim() != '') {
                result += ', text=' + node.getText().trim();
                if (!mapResponse.containsKey(node.getName())) {
                    mapResponse.put(node.getName(), node.getText().trim());
                }
            }
            if (node.getAttributeCount() > 0) {
                for (Integer i = 0; i < node.getAttributeCount(); i++) {
                    result += ', attribute #' + i + ':' + node.getAttributeKeyAt(i) + '=' + node.getAttributeValue(node.getAttributeKeyAt(i), node.getAttributeKeyNsAt(i));
                }
            }
            for (Dom.XmlNode child : node.getChildElements()) {
                result += walkThrough(child);
            }
            return result;
        }
        return '';  //should never reach here
    }

    public PageReference addPaymentInformation() {
        PageReference pageRedirect = null;
        Savepoint sp = null;
        doCRUD CRUDtoDo = new doCRUD();
        try {
            if (successReturnFromGateway) {
                String envelop = '';
                envelop += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://types.secureLink.touchnet.com">';
                envelop += '    <soapenv:Header/>';
                envelop += '    <soapenv:Body>';
                envelop += '        <typ:authorizeAccountRequest>';
                envelop += '            <typ:session>' + params.get('session_identifier') + '</typ:session>';
                envelop += '            <typ:invoiceNumber>' + eventInfo.registrationId + '</typ:invoiceNumber>';
//                envelop += '            <typ:ancillaryData>EnrollmentRx Berkeley</typ:ancillaryData>';
//                envelop += '            <typ:application>EnrollmentRx</typ:application>';
                envelop += '            </typ:authorizeAccountRequest>';
                envelop += '    </soapenv:Body>';
                envelop += '</soapenv:Envelope>';
                Http h = new Http();
                HttpRequest r = new HttpRequest();
                r.setTimeout(120000); // timeout in milliseconds
                r.setEndpoint(touchNetService);
                r.setHeader('Authorization', getAuthorizationHeader());
                r.setHeader('SOAPAction', touchNetService);
                r.setMethod('GET');
                r.setBody(envelop);
                HttpResponse resp = h.send(r);
                Dom.Document doc = resp.getBodyDocument();
                Dom.XmlNode root = doc.getRootElement();
                walkThrough(root);

                if (mapResponse.containsKey('receiptNumber') && mapResponse.get('receiptNumber') != '') {
                    //feeTypeInfo = getTransactionFeeName();
                    sp = Database.setSavepoint();
                    summit__Summit_Events_Payment__c paymentInformation = new summit__Summit_Events_Payment__c();
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

                    //Update fees to connect the payment record to them.
                    for (Integer fi = 0; fi < eventFees.size(); fi++) {
                        eventFees[fi].summit__Summit_Events_Payment__c = paymentInformation.Id;
                        eventFees[fi].summit__Summit_Events__c = eventInfo.eventId;
                    }
                    CRUDtoDo.updateFees(eventFees);

                    successReturnFromGateway = false;

                    summit__Summit_Events_Settings__c myUserSetting = summit__Summit_Events_Settings__c.getInstance(UserInfo.getUserId());
                    String communityBaseURL = myUserSetting.summit__Community_Base_URL__c;
                    if (!communityBaseURL.endsWith('/')) {
                        communityBaseURL += '/';
                    }
                    pageRedirect = new PageReference(communityBaseURL + 'summit__SummitEventsConfirmation');
                    pageRedirect.setRedirect(true);
                    return pageRedirect;
                } else {
                    successReturnFromGateway = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Transaction was not successful, please try again'));
                }
            } else {
                return pageRedirect;
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Payment can not be processed, please try later!!' + ex));
            successReturnFromGateway = false;
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>();
            toAddresses.add('dahl3702@stthomas.edu');

            // Sets the paramaters of the email
            email.setSubject('UST Events Transaction Error');
            email.setToAddresses(toAddresses);
            email.setPlainTextBody(ex.getStackTraceString() + '***' + ex.getMessage());

            // Sends the email
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    email
            });
            if (sp != null) {
                Database.rollback(sp);
            }
        }
        return pageRedirect;
    }

    private without sharing class doCRUD {

        public void updateFees(List<summit__Summit_Events_Fee__c> upsertableFees) {
            try {
                upsert upsertableFees;
            } catch (Exception ex) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, ex.getMessage());
                ApexPages.addMessage(myMsg);
            }
        }

        public void createPaymentRecord(summit__Summit_Events_Payment__c payment) {
            try {
                insert payment;
            } catch (Exception ex) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, ex.getMessage());
                ApexPages.addMessage(myMsg);
            }
        }
    }
}