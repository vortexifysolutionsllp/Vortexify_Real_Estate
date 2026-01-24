public class CongaCompWrapper {

    @AuraEnabled
    public String conId{get;set;}
    
    @AuraEnabled
    public String conName{get;set;}
     
    @AuraEnabled
    public String type{get;set;}
    
    @AuraEnabled
    public integer sequence{get;set;}
    
    @AuraEnabled
    public boolean standardUser{get;set;}
}