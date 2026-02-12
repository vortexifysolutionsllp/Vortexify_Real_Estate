public class PostConstructionUpdateController {

    /* =========================
       Fetch Towers
       ========================= */
    @AuraEnabled(cacheable=true)
    public static List<Tower__c> getTowers(Id projectId) {
        return [
            SELECT Id, Name
            FROM Tower__c
            WHERE Project__c = :projectId
            ORDER BY Name
        ];
    }

    /* =========================
       Fetch Construction Policy
       ========================= */
    @AuraEnabled(cacheable=true)
    public static Policy__c getConstructionPolicy(Id projectId) {
        return [
            SELECT Id, Name, Term__c
            FROM Policy__c
            WHERE Applicable_Project__c = :projectId
            AND Construction_Linked__c = true
            LIMIT 1
        ];
    }

    /* =========================
       Fetch Used Milestones (NEW)
       ========================= */
    @AuraEnabled(cacheable=true)
public static List<String> getUsedMilestoneTermIds(Id projectId) {

    Set<String> usedTermIds = new Set<String>();

    for (Construction_update__c cu : [
        SELECT Term_Id__c
        FROM Construction_update__c
        WHERE Project__c = :projectId
        AND Term_Id__c != null
    ]) {
        usedTermIds.add(cu.Term_Id__c);
    }

    // 🔥 Convert Set → List before returning
    return new List<String>(usedTermIds);
}


    /* =========================
       Create Construction Update
       ========================= */
    @AuraEnabled
    public static Id createConstructionUpdate(
        Id projectId,
        Id policyId,
        String milestoneName,
        String termId,
        String constructionStage,     // ✅ NEW
        List<Id> towerIds,
        List<Id> fileIds
    ) {

        /* =========================
           DUPLICATE MILESTONE CHECK
           ========================= */
        Integer existingCount = [
            SELECT COUNT()
            FROM Construction_update__c
            WHERE Project__c = :projectId
            AND Term_Id__c = :termId
        ];

        if (existingCount > 0) {
            throw new AuraHandledException(
                'This milestone has already been updated for this project.'
            );
        }

        /* =========================
           1. Create Parent Record
           ========================= */
        Construction_update__c cu = new Construction_update__c(
            Name = milestoneName,
            Project__c = projectId,
            Policy__c = policyId,
            Term_Id__c = termId,
            ConstructionStage__c = constructionStage,   // ✅ SAVED
            Update_Date__c = Date.today()
        );
        insert cu;

        /* =========================
           2. Get Project Name
           ========================= */
        String projectName = [
            SELECT Name
            FROM Project__c
            WHERE Id = :projectId
        ].Name;

        /* =========================
           3. Fetch Tower Names
           ========================= */
        Map<Id, Tower__c> towerMap = new Map<Id, Tower__c>(
            [
                SELECT Id, Name
                FROM Tower__c
                WHERE Id IN :towerIds
            ]
        );

        /* =========================
           4. Create Junction Records
           ========================= */
        List<Construction_Update_Tower_Association__c> associations =
            new List<Construction_Update_Tower_Association__c>();

        for (Id towerId : towerIds) {

            String towerName = towerMap.containsKey(towerId)
                ? towerMap.get(towerId).Name
                : '';

            associations.add(
                new Construction_Update_Tower_Association__c(
                    Name = milestoneName + ' - ' + projectName + ' - ' + towerName,
                    Tower__c = towerId,
                    Construction_update__c = cu.Id
                )
            );
        }

        if (!associations.isEmpty()) {
            insert associations;
        }

        /* =========================
           5. Link Files
           ========================= */
        if (fileIds != null && !fileIds.isEmpty()) {

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();

            for (Id docId : fileIds) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = docId,
                    LinkedEntityId = cu.Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }

            insert links;
        }

        return cu.Id;
    }
}