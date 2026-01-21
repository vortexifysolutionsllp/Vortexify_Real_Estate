public with sharing class PolicyController {

    @AuraEnabled
    public static Map<String,Object> fetchPolicyData(Id projectId){
        System.debug('projectId ____'+projectId);

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
                SELECT Id FROM Tower__c WHERE Project__c = :projectId
            )
        ];

        List<Policy__c> policies = [
            SELECT Id, Name, Abbreviation__c, Cost_Sqft__c, Term__c, Construction_Linked__c
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

    List<Object> policyList = (List<Object>)JSON.deserializeUntyped(policiesJson);

    // ⭐ ADD THIS
    Map<Id, Policy__c> uniqueMap = new Map<Id, Policy__c>();
    List<Policy__c> records = new List<Policy__c>();

    Set<Id> incomingIds = new Set<Id>();

    for(Object obj : policyList){
        Map<String,Object> p = (Map<String,Object>)obj;

        Policy__c rec = new Policy__c();
        Id finalId;

        if (p.containsKey('id') && p.get('id') != null) {
            String incomingId = String.valueOf(p.get('id'));
            if (incomingId.length() == 15 || incomingId.length() == 18) {
                finalId = (Id)incomingId;
                rec.Id = finalId;
                incomingIds.add(finalId);
            }
        }

        rec.Name = (String)p.get('name');
        rec.Abbreviation__c = (String)p.get('abbr');

        if (p.get('cost') != null) {
            rec.Cost_Sqft__c = Decimal.valueOf(String.valueOf(p.get('cost')));
        }

        rec.Term__c = JSON.serialize(p.get('terms'));

        if(p.containsKey('isConstructionLinked')){
            rec.Construction_Linked__c = (Boolean)p.get('isConstructionLinked');
        }

        rec.Applicable_Project__c = projectId;
        rec.Type__c = 'Payment';

        // ⭐ PREVENT DUPLICATE
        if(finalId != null){
            uniqueMap.put(finalId, rec);
        } else {
            records.add(rec); // new record
        }
    }

    // ⭐ ADD MAP VALUES
    records.addAll(uniqueMap.values());

    List<Policy__c> existing = [
        SELECT Id 
        FROM Policy__c 
        WHERE Applicable_Project__c = :projectId
    ];

    List<Policy__c> toDelete = new List<Policy__c>();

    for(Policy__c oldRec : existing){
        if(!incomingIds.contains(oldRec.Id)){
            toDelete.add(oldRec);
        }
    }

    if(!toDelete.isEmpty()){
        delete toDelete;
    }

    upsert records;
}
}
