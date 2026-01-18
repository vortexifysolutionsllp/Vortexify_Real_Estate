public with sharing class PolicyController {

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> fetchPolicyData(Id projectId){

        system.debug('projectId ____'+projectId);

        Map<String,Object> res = new Map<String,Object>();

        Project__c proj = [
            SELECT Name, Location__c, RERA_Number__c
            FROM Project__c
            WHERE Id =: projectId
   
        ];

        Integer towerCount = [
            SELECT COUNT()
            FROM Tower__c
            WHERE Project__c =: projectId
        ];
        Integer unitCount = [
            SELECT COUNT()
            FROM Product2
            WHERE Tower__c IN (
        SELECT Id
        FROM Tower__c
         WHERE Project__c = :projectId)
         ];


      
        List<Policy__c> policies = [
            SELECT Id, Name, Abbreviation__c, Cost_Sqft__c, Term__c
            FROM Policy__c
            WHERE Applicable_Project__c =: projectId
        ];

        res.put('project', proj);
        res.put('towerCount', towerCount);
        res.put('policies', policies);
        res.put('unitCount', unitCount);


        return res;
    }
    @AuraEnabled
public static void savePolicies(String policiesJson, Id projectId){

    List<Object> policyList =
        (List<Object>)JSON.deserializeUntyped(policiesJson);

    List<Policy__c> records = new List<Policy__c>();

    for(Object obj : policyList){

        Map<String,Object> p = (Map<String,Object>)obj;

        Policy__c rec = new Policy__c();

        // ✅ FIX: only assign real Salesforce Ids
        if (p.containsKey('id') && p.get('id') != null) {
            String incomingId = String.valueOf(p.get('id'));
            if (incomingId.length() == 15 || incomingId.length() == 18) {
                rec.Id = incomingId;
            }
        }

        rec.Name = (String)p.get('name');
        rec.Abbreviation__c = (String)p.get('abbr');

        if (p.get('cost') != null) {
            rec.Cost_Sqft__c = Decimal.valueOf(String.valueOf(p.get('cost')));
        }

        rec.Term__c = JSON.serialize(p.get('terms'));
        rec.Applicable_Project__c = projectId;

        records.add(rec);
    }

    upsert records;
}
}
