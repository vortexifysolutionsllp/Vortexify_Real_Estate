public with sharing class BookingCommissionPolicyController {

    // ============================
    // Fetch Commission Policies
    // ============================
    @AuraEnabled
    public static List<Policy__c> getCommissionPolicies(Id opportunityId) {

        system.debug('opportunityId'+opportunityId);

        if (opportunityId == null) {
            return new List<Policy__c>();
        }

        // Get Project Id from UNIT product on Opportunity
        List<OpportunityLineItem> oliList = [
            SELECT Product2.Tower__r.Project__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
            AND Product2.Family = 'Unit'
            AND Product2.Tower__r.Project__c != null
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        system.debug('oliList'+oliList);
        if (oliList.isEmpty()) {
            // No valid Unit → Project mapping found
            return new List<Policy__c>();
        }

        Id projectId = oliList[0].Product2.Tower__r.Project__c;
        system.debug('projectId'+projectId);
        // Fetch ACTIVE Commission Policies for that Project
        return [
            SELECT Id, Name
            FROM Policy__c
            WHERE Applicable_Project__c = :projectId
            AND Type__c = 'Commission Policy'
            AND Active__c = true
            ORDER BY Name
        ];
    }

    // ============================
    // Save Selected Commission Policy
    // ============================
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