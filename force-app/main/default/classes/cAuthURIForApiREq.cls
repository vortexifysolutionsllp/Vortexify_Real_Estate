global class cAuthURIForApiREq 
{
    global String AuthenticationURI='';
    public cAuthURIForApiREq(String Clientkey,String redirect_uri)
    {
        String key = EncodingUtil.urlEncode(Clientkey,'UTF-8');
        String uri = EncodingUtil.urlEncode(redirect_uri,'UTF-8');
        
        //Authentication URL to authenticate the app created by Application Designer to connect to google
        //when ever any rest api connection is made 
        //1. get the AuthenticationToken for an App (to be identified that this is the app being used for the connection)
         String  authuri = 'https://accounts.google.com/o/oauth2/auth?'+
            'client_id='+key+
            '&response_type=code'+
            '&scope=https://www.googleapis.com/auth/drive'+
            '&redirect_uri='+uri+
            '&state=security_token%3D138r5719ru3e1%26url%3Dhttps://oa2cb.example.com/myHome&'+
            '&login_hint=bangkim527@gmail.com&'+
            'access_type=offline';
        AuthenticationURI=authuri;
    }
}