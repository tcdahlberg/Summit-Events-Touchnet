/**
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 11/3/2021.
 */


@IsTest
global class TouchNetSuccessRequestMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        String XMLString = '';
        XMLString += '<?xml version="1.0" encoding="UTF-8"?>';
        XMLString += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
        XMLString += '    <soapenv:Body>';
        XMLString += '        <authorizeAccountResponse xmlns="http://types.secureLink.touchnet.com">';
        XMLString += '            <ticketName>ThomasTicket</ticketName>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>AMT</name>';
        XMLString += '                <value>100.0</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>CREDIT_ACCT_CODE</name>';
        XMLString += '                <value>100.00</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>CREDIT_ACCT_AMT</name>';
        XMLString += '                <value>a031F000006lGbzQAE</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>BILL_NAME</name>';
        XMLString += '                <value>Living Colour</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>BILL_EMAIL_ADDRESS</name>';
        XMLString += '                <value>thad+livingcolour@valleyhill.net</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>BILL_STREET1</name>';
        XMLString += '                <value>123 Electric Ave</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>BILL_CITY</name>';
        XMLString += '                <value>Minneapolis</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>BILL_STATE</name>';
        XMLString += '                <value>MN</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>BILL_POSTAL_CODE</name>';
        XMLString += '                <value>55412</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>BILL_COUNTRY</name>';
        XMLString += '                <value>US</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>SUCCESS_LINK</name>';
        XMLString += '                <value>';
        XMLString += '                    https://sandbox-drive-page-1320-dev-ed-17cdd088047.cs90.force.com/c__TouchNetPaymentProcess?eventInfo=TDFHa%252BpHQG2fepzk0Yke%252B4I3n9PgNr5PAmzbq%252FfxjUXstNn6j4al7qp%252B7l%252FMmkeTw21bSFZZ5rAYiUXlAawpC7fM4fpG8w%252BkpnTmb6V0HD5LBhZuZYPqbtPKc6N6c7F42bIAcywSZgcCXpHhvykQ%252FF8oQilpdXSxUE0iDDfGeR0MA7eINPYCK0eEKf7XCTTff5REtrWtfPcNE43IC6UthoL8BTWFC9p9FBJP6UEEHVg%253D';
        XMLString += '                </value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>CANCEL_LINK</name>';
        XMLString += '                <value>';
        XMLString += '                    https://sandbox-drive-page-1320-dev-ed-17cdd088047.cs90.force.com/summit__SummitEventsSubmit?eventInfo=TDFHa%252BpHQG2fepzk0Yke%252B4I3n9PgNr5PAmzbq%252FfxjUXstNn6j4al7qp%252B7l%252FMmkeTw21bSFZZ5rAYiUXlAawpC7fM4fpG8w%252BkpnTmb6V0HD5LBhZuZYPqbtPKc6N6c7F42bIAcywSZgcCXpHhvykQ%252FF8oQilpdXSxUE0iDDfGeR0MA7eINPYCK0eEKf7XCTTff5REtrWtfPcNE43IC6UthoL8BTWFC9p9FBJP6UEEHVg%253D&amp;error=Payment+Cancelled.';
        XMLString += '                </value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>ERROR_LINK</name>';
        XMLString += '                <value>';
        XMLString += '                    https://sandbox-drive-page-1320-dev-ed-17cdd088047.cs90.force.com/c__TouchNetPaymentProcess?eventInfo=TDFHa%252BpHQG2fepzk0Yke%252B4I3n9PgNr5PAmzbq%252FfxjUXstNn6j4al7qp%252B7l%252FMmkeTw21bSFZZ5rAYiUXlAawpC7fM4fpG8w%252BkpnTmb6V0HD5LBhZuZYPqbtPKc6N6c7F42bIAcywSZgcCXpHhvykQ%252FF8oQilpdXSxUE0iDDfGeR0MA7eINPYCK0eEKf7XCTTff5REtrWtfPcNE43IC6UthoL8BTWFC9p9FBJP6UEEHVg%253D';
        XMLString += '                </value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>EXT_TRANS_ID</name>';
        XMLString += '                <value>a081F000006KGhaQAG</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>EXT_TRANS_ID_LABEL</name>';
        XMLString += '                <value>Test Event - Secondary Title - Monday, November 08, 2021, 8:00 AM - 3:30 PM CDT</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <nameValuePairs>';
        XMLString += '                <name>POSTING_KEY</name>';
        XMLString += '                <value>a081F000006KGhaQAG</value>';
        XMLString += '            </nameValuePairs>';
        XMLString += '            <achResponse xsi:nil="true"/>';
        XMLString += '            <creditResponse>';
        XMLString += '                <approvalCode>144457</approvalCode>';
        XMLString += '                <receiptNumber>20211105000000</receiptNumber>';
        XMLString += '                <cvv2Available>true</cvv2Available>';
        XMLString += '                <cvv2Succeeded>false</cvv2Succeeded>';
        XMLString += '                <avsAvailable>true</avsAvailable>';
        XMLString += '                <avsSucceeded>true</avsSucceeded>';
        XMLString += '                <avsZipStatus>true</avsZipStatus>';
        XMLString += '                <avsAddrStatus>true</avsAddrStatus>';
        XMLString += '                <creditCardInfo>';
        XMLString += '                    <creditCardType>Visa</creditCardType>';
        XMLString += '                    <maskedAccountNumber>XXXXXXXXXXXX1111</maskedAccountNumber>';
        XMLString += '                </creditCardInfo>';
        XMLString += '            </creditResponse>';
        XMLString += '        </authorizeAccountResponse>';
        XMLString += '    </soapenv:Body>';
        XMLString += '</soapenv:Envelope>';
        XMLString = XMLString.normalizeSpace();
        // DOM.Document doc=new DOM.Document();
        // doc.load(XMLString);
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'text/html');
        response.setBody(XMLString);
        response.setStatusCode(200);
        return response;
    }
}
