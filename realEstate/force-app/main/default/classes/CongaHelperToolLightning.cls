public class CongaHelperToolLightning {
	 public static boolean STOP_MOST_RECENT_NOTE = false;
    
    public static String HttpReq(String url){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(url);
        req.setTimeout(120000);
        system.debug('request is'+req);
        HttpResponse res = h.send(req);
        system.debug('body is '+ res.getBody());
        return res.getBody();
    }
    
    public static String getSessionId(String username, String password){
        String loginDomain;
        
        final String sessionId;
        System.debug(':: username/password ::::::::: '+username+'/'+password);
        try {
            sessionId = userinfo.getSessionId();
            System.debug('sessionId:' + sessionId); 
        }catch (Exception e) {
            System.debug('Exception:' + e.getMessage() +'@'+e.getLineNumber());    
        }
        return userinfo.getSessionId();
    }
    
    public static string generateReport(String reportLink,string fileName, string dv0, string dv1, string dv2){
        String attachId = '';
        System.debug('reportLink =>'+reportLink);
        if(reportLink != null && string.isNotEmpty(reportLink)){
            try {
                string url = reportLink;           
                System.debug(url);
                
                CongaSession__c cs = [select id , Username__c,Password__c , name from CongaSession__c];
                String username = cs.Username__c;
                String password = cs.Password__c; 
                String sessiondId = CongaHelperToolLightning.getSessionId(username, password);
                
                url = url.replace('SESSION_ID', sessiondId);
                url = CongaHelperToolLightning.fixBatchURL(url,fileName,dv0,dv1,dv2);
                System.debug(':: [CongaHelperTool] EndPoint :: ' + url);
                attachId = CongaHelperToolLightning.HttpReq(url);
                System.debug(':: [CongaHelperToolLightning] attachId :: ' + attachId);
                
                if (attachId.indexOf('</body>/') != -1) {
                    attachId = attachId.substring(attachId.indexOf('</body>/')+8);
                }else if (attachId.indexOf('/') != -1){
                    attachId = attachId.substring(attachId.indexOf('/')+1);
                }
            }catch (Exception e) {
                attachId = 'Result: There is an error when the attachament id was generated';
                System.debug('::CongaHelperToolLightning - attachId ::attachId' + e +e.getMessage()+' AT '+e.getLineNumber());
            }
        }
        return attachId;
    }
    
    public static string fixBatchURL(string url, string fileName, string dv0, string dv1, string dv2){
        if(!url.contains('DefaultPDF'))
            url+='&DefaultPDF=1';
        if(!url.contains('APIMode'))
            url+=+'&APIMode=1';
        if(url.contains('&DS7=1'))
            url = url.replace('&DS7=1', '');
        if(!url.contains('&OFN=') && fileName!=null)
            url+='&OFN='+EncodingUtil.urlEncode(fileName, 'UTF-8');
        if(!url.contains('&DV0=') && dv0!=null && dv0!='')
            url+='&DV0='+EncodingUtil.urlEncode(dv0, 'UTF-8');
        if(!url.contains('&DV1=') && dv1!=null && dv1!='')
            url+='&DV1='+EncodingUtil.urlEncode(dv1, 'UTF-8');
        if(!url.contains('&DV2=') && dv2!=null && dv2!='')
            url+='&DV2='+EncodingUtil.urlEncode(dv2, 'UTF-8');
        system.debug('url'+url);
        return url;
    }
    
    public static string getReportName(string baseName, string recordName,string language){
        string result = baseName;
        if(language!=null && language!=''){  
            result += ' '+language.subString(0,2).toUppercase();
        } 
        result += ' - '+recordName;
        return result;
    }
}