public with sharing class BookingCommissionPolicyController {
    
    public class CommissionPolicyResponse {
        @AuraEnabled public List<Policy__c> policies;
        @AuraEnabled public Id selectedPolicyId;
    }

    @AuraEnabled(cacheable=true)
public static CommissionPolicyResponse getCommissionPolicies(Id opportunityId) {
 
    CommissionPolicyResponse response = new CommissionPolicyResponse();
    response.policies = new List<Policy__c>();

    if (opportunityId == null) {
        return response;
    }

    Opportunity opp = [
        SELECT Commission_Policy__c
        FROM Opportunity
        WHERE Id = :opportunityId
        LIMIT 1
    ];
    response.selectedPolicyId = opp.Commission_Policy__c;

    List<OpportunityLineItem> oliList = [
        SELECT Product2.Tower__r.Project__c
        FROM OpportunityLineItem
        WHERE OpportunityId = :opportunityId
        AND Product2.Family = 'Unit'
        AND Product2.Tower__r.Project__c != null
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];

    if (oliList.isEmpty()) {
        return response;
    }

    Id projectId = oliList[0].Product2.Tower__r.Project__c;

    response.policies = [
        SELECT Id, Name
        FROM Policy__c
        WHERE Applicable_Project__c = :projectId
        AND Type__c = 'Commission Policy'
        ORDER BY Name
    ];

    return response;
}

    @AuraEnabled
    public static void saveCommissionPolicy(Id opportunityId, Id policyId) {

        if (opportunityId == null || policyId == null) {
            return;
        }

        update new Opportunity(
            Id = opportunityId,
            Commission_Policy__c = policyId
        );
    }
}