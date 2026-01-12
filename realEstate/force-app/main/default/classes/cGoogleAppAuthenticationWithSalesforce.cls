public class cGoogleAppAuthenticationWithSalesforce 
{
    private string key = '949796238340-svudkunaajder19ho41efuk65ipq137c.apps.googleusercontent.com' ;
    private string secret = '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';
    private string redirect_uri = URL.getOrgDomainUrl().toExternalForm() +'/apex/GoogleDriveIntegration';
    private static final String NAMED_CREDENTIAL = 'Google_Drive';
    private String codemeniaIdentificationToken ; 
    private String access_token; 
    private List<String> FileLst;
    public Map<String,String> FileIdAndNameMapFortheAccount{get;set;}
    //Constructor
    public cGoogleAppAuthenticationWithSalesforce()
    {
        //Once Authentication is done again constructor is called and will have to receive the vale for code parameter
        codemeniaIdentificationToken = ApexPages.currentPage().getParameters().get('code') ;
        
        FileLst=new List<String>();
        FileIdAndNameMapFortheAccount=new Map<String,String>();
        if(codemeniaIdentificationToken != '' && codemeniaIdentificationToken != null)
        {
            AccessToken();
        } 
    }
    
    public PageReference DriveAuth()
    {
    	PageReference pg = new PageReference(new cAuthURIForApiREq(key , redirect_uri).AuthenticationURI) ;
        return pg;
    }
    
     public static HttpResponse uploadFileToGoogleDrive(String fileId, Blob fileData) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + NAMED_CREDENTIAL + '/upload/drive/v3/files/' + fileId + '?uploadType=media');
        request.setMethod('PATCH');
        request.setHeader('Content-Type', 'application/vnd.ms-excel');
        request.setBodyAsBlob(fileData);
        
        Http http = new Http();
        return http.send(request);
    }
    
    public void AccessToken()
    {
        //Getting access token from google
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        //End point for authentication
        req.setEndpoint('https://accounts.google.com/o/oauth2/token');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        //Message body for Authentication
        String messageBody = 'code='+codemeniaIdentificationToken+'&client_id='+key+'&client_secret='+secret+'&redirect_uri='+redirect_uri+'&grant_type=authorization_code';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60*1000);
        
        Http h = new Http();
        HttpResponse res = h.send(req);
        //Salesforce defined JSON Parser
        JSONParser parser = JSON.createParser(res.getBody());
        while (parser.nextToken() != null) 
        {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token'))
            {
                parser.nextToken();
                access_token=parser.getText();
                break;
            }
        }
        if (access_token!='' && access_token != null)
        {
            ListFiles();
        }
    }
    
    public PageReference ListFiles()
    {  
        //Google_Drive_Info__c g=new Google_Drive_Info__c();
        //g=[SELECT Folder_Id__c FROM Google_Drive_Info__c WHERE Name=:'main'];
        String FolderId= '1VyBAWKRjMIhFNQr_BiBKS1zyuOr_ZeI1';//g.Folder_Id__c;
        HttpRequest req1 = new HttpRequest();
        req1.setMethod('GET');
        //End point for List of Files in Folder
        req1.setEndpoint('https://www.googleapis.com/drive/v2/files/'+FolderId+'/children');
        req1.setHeader('content-type', 'application/x-www-form-urlencoded');
        req1.setHeader('Content-length', '0');
        //Specific Authorization Syntax
        req1.setHeader('Authorization' , 'Bearer'+' '+ access_token);
        req1.setTimeout(60*1000);
        Http h2 = new Http();
        HttpResponse resl = h2.send(req1);
        System.debug('^^^^^'+resl.getBody());
        JSONParser parserD = JSON.createParser(resl.getBody());
        while (parserD.nextToken() != null) 
        {
            if ((parserD.getCurrentToken() == JSONToken.FIELD_NAME) && (parserD.getText() == 'id'))
            {
                parserD.nextToken();
                FileLst.add(parserD.getText());
            }
        }
       Map<String,String> FileIdAndNameMap=FileProperties();
        for(String s:FileLst)
        {
            FileIdAndNameMapFortheAccount.put(s, FileIdAndNameMap.get(s));
        }
        return null;
    }
    public  Map<String,String> FileProperties()
    {
        Map<String,String> FilePropertiesDetails=new Map<String,String>();
        HttpRequest req2 = new HttpRequest();
        req2.setMethod('GET');
        //End point URL for All the files in the drive and its ID,Name value in JSON Response
        req2.setEndpoint('https://www.googleapis.com/drive/v3/files');
        req2.setHeader('content-type', 'application/x-www-form-urlencoded');
        req2.setHeader('Content-length', '0');
        req2.setHeader('Authorization' , 'Bearer'+' '+ access_token);
        req2.setTimeout(60*1000);
        Http h3 = new Http();
        HttpResponse resls = h3.send(req2);
        System.debug('^^^^^'+resls.getBody());
        JSONParser parserDr = JSON.createParser(resls.getBody());
        while (parserDr.nextToken() != null) 
        {   
            String FileName='';
            String FileId='';
            if ((parserDr.getCurrentToken() == JSONToken.FIELD_NAME))
            {
                //First TOKEN is Id
                if((parserDr.getText() == 'id'))
                {
                    parserDr.nextToken();               
                    Fileid=parserDr.getText();
                }
                //Moving to Next Parser
                parserDr.nextToken();
                //Next Token is Name
                if((parserDr.getText() == 'name'))
                {
                    parserDr.nextToken();
                    Filename=parserDr.getText();
                }
                FilePropertiesDetails.put(Fileid, Filename);
            }
        }
        return FilePropertiesDetails;
    }
}