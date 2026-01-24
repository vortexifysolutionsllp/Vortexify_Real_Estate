public class GoogleApiController {
    private static final String NAMED_CREDENTIAL = 'Google_Drive'; // Replace with your Named Credential alias
    
    public static HttpResponse getAccessToken(String code) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/token');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        String messageBody = 'code=' + code
            + '&grant_type=authorization_code';
        
        req.setHeader('Content-Length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60000);
        
        Http http = new Http();
        return http.send(req);
    }
    
    public static HttpResponse refreshAccessToken(String refreshToken) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/token');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        String bodyRequest = 'refresh_token=' + refreshToken
            + '&grant_type=refresh_token';
        
        req.setBody(bodyRequest);
        Http http = new Http();
        return http.send(req);
    }
    
    public static Blob generateReportFile(String reportDeveloperName) {
        Report report = [SELECT Id FROM Report WHERE DeveloperName = :reportDeveloperName LIMIT 1];
        ApexPages.PageReference reportPage = new ApexPages.PageReference('/' + report.Id + '?excel=1&isdtp=p1');
        return reportPage.getContent();
    }
    
    public static HttpResponse createGoogleDriveFile(String fileName, String parentFolderId) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + NAMED_CREDENTIAL + '/drive/v3/files');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('name', fileName);
        requestBody.put('mimeType', 'application/vnd.ms-excel');
        requestBody.put('parents', new List<String>{parentFolderId});
        
        request.setBody(JSON.serialize(requestBody));
        
        Http http = new Http();
        return http.send(request);
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
}