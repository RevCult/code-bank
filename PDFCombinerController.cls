public with sharing class PDFCombinerController {

   // clay.boss@revcult.com 

   // call a PDF Merging Service with results of PDF endpoint responses to merge PDFs together.

   // usage;  call from VF page with the URL parameter ref as the ParentId for the attachment

  public String attachmentId {get;set;}   // passed back to the page for ultimate redirection to the combined PDF
  public Boolean shouldRender {get;set;}  // Boolean to tell the VF page to render the PDF

  public void fetchAndCombinePDFs() {
      String theParentId = ApexPages.currentPage().getParameters().get('ref');
      
      // the way this is setup this needs to be the complete endpoint (customize to your needs)
      List<String> myEndPoints = new List<String>();

      myEndPoints.add('endpointa');
      myEndPoints.add('endpointb');

      fetchPDFs(myEndPoints, theParentId);
  }

  public void fetchPDFs(List<String> endPoints, String parentId){
  	// loops over endpoints to collect PDF responses for merging

	shouldRender = false; // lets not tell it to render until it works
	String pdfEndpoint = '';
   
	List<Blob> listOfPDFBlobs = new List<Blob>();  // takes a list of policies and pulls Loss Runs for them into a combined PDF

  	for (String s : endPoints) {

  		pdfEndpoint = s;

		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setTimeout(60000);
		req.setEndpoint(pdfEndpoint);
		req.setMethod('GET');

		HttpResponse res = h.send(req);
		System.debug(res);
		Blob retBlob;
		if(res.getStatusCode() == 200){        
			shouldRender = true;
			retBlob = res.getBodyAsBlob();
			listOfPDFBlobs.add(retBlob);
		} else {
			// we need to investigate response not coming back
		}
	}
	
	mergePDFs(listOfPDFBlobs, parentId, 'https://v2.convertapi.com/convert/pdf/to/merge?Secret=Ce8AoXhmTj7py9uz');	 

	}

  	public void mergePDFs(List<Blob> theBlobs, String theParentId, String mergeServiceEndpoint) {

  		// this method is very specific to the ConvertAPI specs (Free Trial available)
  		// if using a different service the mergeServiceEndpoint, and Header and Method values might be different

		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setTimeout(120000);
		req.setEndpoint('https://v2.convertapi.com/convert/pdf/to/merge?Secret=Ce8AoXhmTj7py9uz');
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('Content-Disposition', 'attachment; filename="my_file.pdf"');
		String mergeJSON = createJSONForMerge(theBlobs);  // build our ConvertAPI specific JSON string with our PDF Blobs
		req.setBody(mergeJSON);
		HttpResponse res = h.send(req);
		Blob retBlob;
     	String theBody = res.getBody();

     	// take the response of the ConvertAPI service and deserialize into Object for use
     	pdfMergeResponseWrapper rw = (pdfMergeResponseWrapper)JSON.deserialize(theBody,pdfMergeResponseWrapper.class);

		//if (res.getStatusCode() == 200) {
			//retBlob3 = res3.getBodyAsBlob();
			//system.debug(retBlob3);
		Blob mergeBlob;
		for(pdfMergeResponseWrapper.Files f : rw.Files) {
			mergeBlob = EncodingUtil.base64Decode(f.FileData);

		}

		Attachment att = new Attachment(Name = 'temp_'+DateTime.now()+'.pdf', ParentId = theParentId, Body = mergeBlob, IsPrivate = false);
        system.debug ('att ::: ' + att);		
		attachmentId = att.Id;
	    shouldRender=true;

        insert att;
	}

	public String createJSONForMerge(List<Blob> blobList) {

        JSONGenerator gen = JSON.createGenerator(true);
        
        // Write data to the JSON string.
        gen.writeStartObject();
        	gen.writeFieldName('Parameters');
        	gen.writeStartArray();
        		gen.writeStartObject();
        			gen.writeStringField('Name', 'Files');
        			gen.writeFieldName('FileValues');
        			gen.writeStartArray();
        				for(Blob b : blobList) {   // loop over the blobs to create an object for each PDF to me merged
		    				gen.writeStartObject();
		    					gen.writeStringField('Name', 'file.pdf');
		    					gen.writeBlobField('Data', b);
		     				gen.writeEndObject();        					
						}
        			gen.writeEndArray();
        		gen.writeEndObject();
        	gen.writeEndArray();
        gen.writeEndObject();

       	String ourJSON = gen.getAsString();

       	return ourJSON;
	}
}