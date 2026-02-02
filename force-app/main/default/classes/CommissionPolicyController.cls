public with sharing class CommissionPolicyController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProjectAndPolicies(Id projectId) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            Project__c proj = [
                SELECT Name, Location__c, RERA_Number__c
                FROM Project__c
                WHERE Id = :projectId
                LIMIT 1
            ];
            
            AggregateResult towerStats = [
                SELECT COUNT(Id) towerCount, SUM(Total_Units__c) totalUnits
                FROM Tower__c
                WHERE Project__c = :projectId
            ];

            List<Policy__c> policies = [
                SELECT Id, Name, Abbreviation__c, Cost_Sqft__c, Term__c
                FROM Policy__c
                WHERE Applicable_Project__c = :projectId
                    AND Type__c = 'Commission Policy'
            ];

            res.put('project', proj);
            res.put(
                'towerCount',
                towerStats.get('towerCount') != null
                    ? towerStats.get('towerCount')
                    : 0
            );
            res.put(
                'totalUnits',
                towerStats.get('totalUnits') != null
                    ? towerStats.get('totalUnits')
                    : 0
            );
            res.put('policies', policies);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static void deleteCommissionPolicies(List<Id> policyIds) {
        if (policyIds == null || policyIds.isEmpty()) return;

        delete [
            SELECT Id
            FROM Policy__c
            WHERE Id IN :policyIds
        ];
    }

    // @AuraEnabled
    // public static Id saveCommissionPolicy(
    //     String policyJson,
    //     Id projectId,
    //     Id policyId
    // ) {
    //     if (String.isBlank(policyJson) || projectId == null) {
    //         throw new AuraHandledException(
    //             'Project ID or Policy Data is missing.'
    //         );
    //     }

    //     try {
    //         // Deserialize JSON
    //         Map<String, Object> policyMap =
    //             (Map<String, Object>) JSON.deserializeUntyped(policyJson);

    //         // Project Name
    //         Project__c proj = [
    //             SELECT Name
    //             FROM Project__c
    //             WHERE Id = :projectId
    //             LIMIT 1
    //         ];

    //         // Commission Type
    //         String rawType = String.valueOf(policyMap.get('policyType'));
    //         String commissionType =
    //             rawType == 'fixed' ? 'Fixed' :
    //             rawType == 'percentage' ? 'Percentage' :
    //             rawType == 'range' ? 'Range' :
    //             'Commission';

    //         Policy__c policy;
    //         Integer policyNumber;

    //         if (policyId != null) {
    //             // ---------- EDIT ----------
    //             policy = [
    //                 SELECT Id, Name
    //                 FROM Policy__c
    //                 WHERE Id = :policyId
    //                 LIMIT 1
    //             ];

    //             // Preserve policy number
    //             policyNumber = extractPolicyNumber(policy.Name);

    //         } else {
    //             // ---------- CREATE ----------
    //             policyNumber = [
    //                 SELECT COUNT()
    //                 FROM Policy__c
    //                 WHERE Applicable_Project__c = :projectId
    //             ] + 1;

    //             policy = new Policy__c();
    //             policy.Applicable_Project__c = projectId;
    //             policy.Abbreviation__c = 'COMM';
    //             policy.Type__c = 'Commission Policy';
    //         }

    //         // ALWAYS update name
    //         policy.Name =
    //             proj.Name + ' - ' + commissionType + ' - Policy ' + policyNumber;

    //         // Fixed-only field
    //         if (rawType == 'fixed' && policyMap.get('amount') != null) {
    //             policy.Cost_Sqft__c =
    //                 Decimal.valueOf(String.valueOf(policyMap.get('amount')));
    //         } else {
    //             policy.Cost_Sqft__c = null;
    //         }

    //         // Store JSON
    //         policy.Term__c = policyJson;

    //         upsert policy;
    //         return policy.Id;

    //     } catch (Exception e) {
    //         throw new AuraHandledException(
    //             'Server Error: ' + e.getMessage()
    //         );
    //     }
    // }

    @AuraEnabled
    public static String saveCommissionPolicy(
        String policiesJson, String projectId
    ) {
        if (String.isBlank(policiesJson) || projectId == null) {
            throw new AuraHandledException(
                'Project ID or Policy Data is missing.'
            );
        }
        String policyId = '';
        System.debug('policiesJson-> ' + policiesJson);
        try {
            Map<Id, Integer> policyIdToNumber = new Map<Id, Integer>();
            Map<String, Integer> maxNumberByType = new Map<String, Integer>();
            List<Policy__c> existingPolicies = [
                SELECT Id, Name
                FROM Policy__c
                WHERE Applicable_Project__c = :projectId
            ];
            for (Policy__c pol : existingPolicies) {
                if (String.isBlank(pol.Name)) continue;

                // Expected: "ProjectName - Fixed Policy - 1"
                List<String> parts = pol.Name.split('\\s-\\s');
                if (parts.size() < 2) continue;

                Integer numbers;
                try {
                    numbers = Integer.valueOf(parts[2]);
                } catch (Exception e) {
                    continue; // skip malformed names safely
                }

                String type = parts[1].substringBefore(' Policy');

                policyIdToNumber.put(pol.Id, numbers);

                Integer currentMax = maxNumberByType.get(type);
                if (currentMax == null || numbers > currentMax) {
                    maxNumberByType.put(type, numbers);
                }
            }
            // Deserialize JSON
            List<PolicyWrapper> policies = (List<PolicyWrapper>) JSON.deserialize(policiesJson,List<PolicyWrapper>.class);
            List<Policy__c> policyListToBeUpserted = new List<Policy__c>();
            // Project Name
            Project__c proj = [
                SELECT Name
                FROM Project__c
                WHERE Id = :projectId
                LIMIT 1
            ];
            Map<String, Integer> runningCounterByType = new Map<String, Integer>();
            runningCounterByType.putAll(maxNumberByType);
            for(PolicyWrapper policyWrapper : policies){
                String commissionType =
                policyWrapper.payload.policyType == 'fixed' ? 'Fixed' :
                policyWrapper.payload.policyType == 'percentage' ? 'Percentage' :
                policyWrapper.payload.policyType == 'range' ? 'Range' :
                'Commission';
                Policy__c polRec = new Policy__c();
                polRec.Type__c = 'Commission Policy';
                polRec.Active__c = policyWrapper.payload.active;
                polRec.Applicable_Project__c = projectId;
                polRec.Term__c = JSON.serialize(policyWrapper.payload);
                Boolean isUpdate =
                    policyWrapper.policyId != null &&
                    policyWrapper.policyId != '' &&
                    policyWrapper.policyId != 'null';
                Integer policyNumber;
                if (isUpdate && policyIdToNumber.containsKey(policyWrapper.policyId)) {
                    // 🔹 Existing record → reuse number
                    polRec.Id = policyWrapper.policyId;
                    policyNumber = policyIdToNumber.get(policyWrapper.policyId);

                } else {
                    // 🔹 New record → assign next number for type
                    Integer nextNumber =
                        runningCounterByType.containsKey(commissionType)
                        ? runningCounterByType.get(commissionType) + 1
                        : 1;

                    runningCounterByType.put(commissionType, nextNumber);
                    policyNumber = nextNumber;
                }
                polRec.Name = proj.Name + ' - ' + commissionType + ' Policy - ' + policyNumber;
                if(policyWrapper.payload.ranges != null && policyWrapper.payload.ranges.size() > 0){
                    polRec.Term__c = JSON.serialize(policyWrapper.payload.ranges);
                }
                if(isUpdate){
                    polRec.Id = policyWrapper.policyId;
                }
                policyListToBeUpserted.add(polRec);
                //policyId = policyWrapper.policyId;
            }

            upsert policyListToBeUpserted;
            return 'Success';

        } catch (Exception e) {
            throw new AuraHandledException(
                'Server Error: ' + e.getMessage()
            );
        }
    }

    private static Integer extractPolicyNumber(String name) {
        if (String.isBlank(name)) return 1;

        Matcher m =
            Pattern.compile('Policy (\\d+)$').matcher(name);

        if (m.find()) {
            return Integer.valueOf(m.group(1));
        }
        return 1;
    }

    public class PolicyWrapper {
        public String policyId;
        public PolicyPayload payload;
    }

    public class PolicyPayload {
        public String policyType;
        public Boolean active;

        // Fixed
        public String amount;

        // Percentage
        public String percent;
        public String upperCap;

        // Range
        public List<RangePayload> ranges;
    }

    public class RangePayload {
        public Decimal minAmount;
        public Decimal maxAmount;
        public String commissionType;
        public Decimal amount;
        public Decimal percent;
        public Decimal upperCap;
    }
}