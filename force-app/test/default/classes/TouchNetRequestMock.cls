/**
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 11/3/2021.
 */


@IsTest
global class TouchNetRequestMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        String XMLString = '';
        XMLString += '<?xml version="1.0" encoding="UTF-8"?>';
        XMLString += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
        XMLString += '  <soapenv:Body>';
        XMLString += '      <generateSecureLinkTicketResponse xmlns="http://types.secureLink.touchnet.com">';
        XMLString += '      <ticket>TEST_TICKET</ticket>';
        XMLString += '      <ticketExpire>2021-11-04T22:41:54.858Z</ticketExpire>';
        XMLString += '      </generateSecureLinkTicketResponse>';
        XMLString += '  </soapenv:Body>';
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