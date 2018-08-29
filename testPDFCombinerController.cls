@isTest
public class testPDFCombinerController {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req)
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Test" : "Blah"}');
            res.setStatus('Success');
            res.setStatusCode(200);
            return res;
        }
    }

	@isTest static void testPDFMerge() {
 		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		Account myAcc = new Account();
		myAcc.Name = 'Clays Test Account';
		insert myAcc;

        Opportunity opp = new Opportunity(
        	AccountId = myAcc.Id,
            StageName = 'Boss on Demand',
            CloseDate = Date.newInstance(2019, 01, 01),
            Name = 'Test Opportunity'
        );
        insert opp;

        PDFCombinerController pdfcc = new PDFCombinerController();
        pdfcc.fetchAndCombinePDFs();

	}
	
}