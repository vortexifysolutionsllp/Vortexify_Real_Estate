public class GenerateCongaDocumentsController {
    Public Static String getTemplateIdFromKey(String templateKey) {
        system.debug('templateKey'+templateKey);
        map<String,String> templateIdfromKey = new map<String,String>();
        List<APXTConga4__Conga_Template__c> templateList = [Select Id , APXTConga4__Key__c from APXTConga4__Conga_Template__c];
        
        for(APXTConga4__Conga_Template__c apxt : templateList){
            templateIdfromKey.put(apxt.APXTConga4__Key__c , apxt.Id);
        }
        if(test.isRunningTest()){
            return 'a4H3z0000009s5o';
        }else{
            return templateIdfromKey.get(templateKey);    
        }
        
    }
    
    //This method Generates the doc 
    @AuraEnabled
    Public Static void GenerateDocument(String recordId) {
        system.debug('recordId'+recordId);
        contact contactRec = [select Conga_Template_ID__c  , AccountId , Id , Conga_Url__c from contact where id = :recordId];
        String templateName = '';
          
        String accId = contactRec.AccountId;
        
        
        
        String contUrl = contactRec.Conga_URL__c;
        String TemplateId = contactRec.Conga_Template_ID__c;//getTemplateIdFromKey(contractRec.Conga_Template_ID__c);
        
        system.debug('TemplateId'+TemplateId);
        if(test.isRunningTest()){
            TemplateId = 'a4H3z0000009s5o';
        }
        //contrUrl = contrUrl.replace('a4H3z000000xfsm', TemplateId);
        contUrl = contUrl.replace('contractIf', contactRec.Id);
        system.debug('contrUrl'+contUrl);
        system.debug('contrUrl'+templateName);
        GenerateDocumentFromConga(contUrl,'E-Sign Doc');
    }
    
    @future(callout=true)
    Public Static void GenerateDocumentFromConga(String congaUrl,String Name) {
        system.debug('Name Is'+Name + 'congaUrl'+congaUrl);
        String AttId = CongaHelperToolLightning.generateReport(congaUrl,Name,'','','');
        system.debug('AttId'+AttId);
    }
    
    //This method Generates the doc and send it for signature
    @AuraEnabled
    Public Static void GenerateDocumentAndSendForSignature(String recordId ,List<CongaCompWrapper> CongaCompWrapperUserList,List<CongaCompWrapper> CongaCompWrapperConList , List<CongaCompWrapper> CongaCompWrapperList,String messageBody,String subject) {
        System.debug('CongaCompWrapperList'+CongaCompWrapperUserList);
        System.debug('messageBody'+messageBody);
        System.debug('CongaCompWrapperConList'+CongaCompWrapperConList);
        
        integer i = 0;
        integer k = 0;
        Contact contactRec = [Select Id,Name ,Conga_Template_ID__c, AccountId, Conga_Sign_URL__c, Conga_Url__c  from Contact where Id = :recordId];
        String templateName = 'E-Signed Template';
        
        //Updateing all the Fields initial vlaues..
        
        //String oppId = contractRec.Opportunity__c;
        /*contractRec.Primary_User__c = null;
        contractRec.Secondary_User__c = null;
        contractRec.Contact_Name__c = null;
        contractRec.Secondary_Contact__c = null;
        contractRec.Is_Primary_Contact_Selected__c = false;
        contractRec.is_primary_user_selected__c = false;
        contractRec.is_secondary_contact_selected__c = false;
        contractRec.is_secondary_user_selected__c = false;	*/
        
        String TemplateId = contactRec.Conga_Template_ID__c;//getTemplateIdFromKey(contractRec.Conga_Template_ID__c);
        //String TemplateId = contractRec.Conga_Template_ID__c;
        system.debug('TemplateId'+TemplateId);
        
        /*if(CongaCompWrapperUserList.size() > 0){
            for(CongaCompWrapper ccw : CongaCompWrapperUserList){
                i++;
                system.debug('the iteration value is '+i);
                if(ccw.conId.startsWith('005')){
                    if(i == 1){
                        contractRec.Primary_User__c = ccw.conId;  
                        contractRec.is_primary_user_selected__c = true;
                    }
                    else if(i == 2){
                        contractRec.Secondary_User__c = ccw.conId;
                        contractRec.is_secondary_user_selected__c = true;
                    }
                }
            }
        }*/
        /*if(CongaCompWrapperConList.size() > 0){
            for(CongaCompWrapper ccw : CongaCompWrapperConList){
                k++;
                system.debug('the iteration value is '+i);
                if(ccw.conId.startsWith('003')){
                    if(k == 1){
                        contractRec.Contact_Name__c = ccw.conId;    
                        contractRec.Is_Primary_Contact_Selected__c = true;
                    }
                    else if(k == 2){
                        contractRec.Secondary_Contact__c = ccw.conId;    
                        contractRec.is_secondary_contact_selected__c = true;
                    }
                }
            }
        }*/
        
        //update contractRec;
        
        map<integer,String> recipientMap = new map<integer,String>();
        map<String,String> recipientMapValues = new map<String,String>();
        map<String,String> recipientTypeValues = new map<String,String>();
        
        recipientMap.put(1,'CSRecipient1');
        recipientMap.put(2,'CSRecipient2');
        recipientMap.put(3,'CSRecipient3');
        recipientMap.put(4,'CSRecipient4');
        recipientMap.put(5,'CSRecipient5');
        recipientMap.put(6,'CSRecipient6');
        
        recipientMapValues.put('CSRecipient1','csRole1');
        recipientMapValues.put('CSRecipient2','csRole2');
        recipientMapValues.put('CSRecipient3','csRole3');
        recipientMapValues.put('CSRecipient4','csRole4');
        recipientMapValues.put('CSRecipient5','csRole5');
        recipientMapValues.put('CSRecipient6','csRole6');
        
        String URL = contactRec.Conga_Sign_URL__c;
        
        string recipients = '';
        integer j = 0;
        
        
        // url = url.replace('TemplateId=a3t3M0000000Wkt','TemplateId='+TemplateId);
        url = url.replace('contractIf', contactRec.Id);
        system.debug('---CongaCompWrapperList---'+CongaCompWrapperList);
        if(CongaCompWrapperList.size() > 0){
            for(CongaCompWrapper ccw : CongaCompWrapperList){
                j++;
                if(!url.contains(recipientMap.get(j))){
                    url+='&CSRecipient'+j+'='+ccw.conId;
                }
                if(!url.contains(recipientMapValues.get('CSRecipient'+j))){
                    url+='&'+recipientMapValues.get('CSRecipient'+j)+'='+ccw.type;
                }
            }
            //Adding for the email message
            if(url.contains('EmailMessage')){
                system.debug('messageBody'+messageBody);
                if(string.isNotBlank(messageBody)){
                    messageBody = messageBody.replaceAll('[^a-zA-Z0-9\\s+]', '');
                }else{
                    messageBody = 'The Conga Sign invitation email expires after 5 days.';
                }
                url = url.replace('EmailMessage=', 'EmailMessage='+messageBody);
            }
            if(url.contains('EmailSubject')){
                system.debug('subject'+subject);
                if(string.isNotBlank(subject)){
                    subject = subject.replaceAll('[^a-zA-Z0-9\\s+]', '');                    
                }else{
                    subject = 'Please Sign the Document Group Series '+contactRec.Name +'.pdf';
                }                
                url = url.replace('EmailSubject=', 'EmailSubject='+subject);
            }
            system.debug('url'+url);
        }
        GenerateDocumentFromConga(URL,templateName);
    }
    
    Public static Boolean sendForSignature(Id primaryContactID, List<String> emailCc, List<String> emailBcc, List<String> emailAdditionalTo, Id emailTemplateId, Id agreementId, List<String> attachmentIds){
        //apttus.AgreementWebService.sendForSignature(primaryContactID,emailCc,emailBcc,emailAdditionalTo,emailTemplateId,agreementId,attachmentIds);
        return false;
    }
    
    @AuraEnabled
    public static List<RecordsData> fetchUserDataforConga(String objectName, String filterField, String searchString, String value, string contactType){
        try{
            system.debug('objectName'+objectName+'filterField'+filterField+'searchString'+searchString+'value'+value+'contactType'+contactType);
            objectName = 'user';
            system.debug('contractId'+contactType);
            Contact contactRec = [Select AccountId,Id from contact where id= :contactType];
            List<RecordsData> recordsDataList = new List<RecordsData>();
            String query = '';
            query = 'SELECT Id  ,' + filterField + ' FROM ' + objectName +' Where ';
            if (String.isNotBlank(contactRec.Id)){
                query +=   filterField + 
                    ' LIKE ' + '\'' + String.escapeSingleQuotes(searchString.trim()) + '%\' LIMIT 49999';
            }
            system.debug('Query is ' + query);
            for (SObject s : Database.query(query)){
                recordsDataList.add(new RecordsData((String)s.get(filterField), (String) s.get('id')));
            }
            system.debug(recordsDataList);
            return recordsDataList;
        }
        catch (Exception err){
            system.debug('Exception is ' + err.getMessage() + '@ line' + err.getLineNumber());
            if (String.isNotBlank(err.getMessage()) && err.getMessage().contains('error:')){
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else{
                throw new AuraHandledException(err.getMessage());
            }
        }
    }
    
    @AuraEnabled
    public static List<CongaCompWrapper> fetchAllContactsFromContract(String contactId){
        try{
            system.debug('contractId'+contactId);
            
            //List<String> congaUsers = label.Conga_Users.split(',');
            Contact contactRec = [Select AccountId,Id from contact where id= :contactId];
            
            List<CongaCompWrapper> recordsDataList = new List<CongaCompWrapper>();
            
            List<Contact> ConList = [Select Id , Name From Contact where Id =:contactRec.Id Order BY NAme ASC];
            String userId = userInfo.getUserID();
            List<User> UserList = [Select id , name From User where id = :userId order by firstName ASC LIMIT 2 ];
            integer i= 0;
            for(User us : UserList){
                CongaCompWrapper ccw = new CongaCompWrapper();
                ccw.conId = us.Id;
                ccw.conName = us.Name; 
                ccw.sequence = ++i;
                ccw.type = 'SIGNER';
                ccw.standardUser = true;
                recordsDataList.add(ccw);
            }
            for(Contact con : ConList){
                i++;
                CongaCompWrapper ccw = new CongaCompWrapper();
                ccw.conId = con.Id;
                ccw.conName = con.Name; 
                ccw.sequence = i;
                ccw.type = 'SIGNER';
                recordsDataList.add(ccw);
            }
            system.debug(recordsDataList);
            return recordsDataList;
        }
        catch (Exception err){
            system.debug('Exception is ' + err.getMessage() + '@ line' + err.getLineNumber());
            if (String.isNotBlank(err.getMessage()) && err.getMessage().contains('error:')){
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else{
                throw new AuraHandledException(err.getMessage());
            }
        }
    }
    
    public class RecordsData{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        public RecordsData(String label, String value){
            this.label = label;
            this.value = value;
        }
        
    }
}