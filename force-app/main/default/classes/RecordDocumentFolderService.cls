public class RecordDocumentFolderService {

    /**
     * Creates document folders for newly created records
     *
     * @param newMap         Trigger.newMap
     * @param objectApiName  API name of the object (Lead, Account, Opportunity, etc.)
     */
    public static void createFolders(
        Map<Id, SObject> newMap,
        String objectApiName
    ) {
        if (newMap == null || newMap.isEmpty()) {
            return;
        }

        /* ---------------------------------------------------
           1️⃣ Fetch metadata config for this object
        --------------------------------------------------- */
        Product_Configuration__mdt config = [
            SELECT Json_Configuration__c
            FROM Product_Configuration__mdt
            WHERE Label = 'Document categorization'
            LIMIT 1
        ];

        if (config == null || String.isBlank(config.Json_Configuration__c)) {
            return; // No config → nothing to do
        }

        /* ---------------------------------------------------
           2️⃣ Parse JSON (supports mixed formats)
        --------------------------------------------------- */
        Map<String, List<DocumentFolderConfigUtil.FolderConfig>> parsedConfig =
            DocumentFolderConfigUtil.parseConfig(
                config.Json_Configuration__c
            );

        if (!parsedConfig.containsKey(objectApiName)) {
            return;
        }

        List<DocumentFolderConfigUtil.FolderConfig> folderDefs =
            parsedConfig.get(objectApiName);

        if (folderDefs.isEmpty()) {
            return;
        }

        /* ---------------------------------------------------
           3️⃣ Query existing folders (prevent duplicates)
        --------------------------------------------------- */
        Map<Id, Set<String>> existingFolderNamesByRecord =
            new Map<Id, Set<String>>();

        for (Record_Document_Folder__c f : [
            SELECT Parent_Record_Id__c, Name
            FROM Record_Document_Folder__c
            WHERE Parent_Record_Id__c IN :newMap.keySet()
        ]) {
            if (!existingFolderNamesByRecord.containsKey(f.Parent_Record_Id__c)) {
                existingFolderNamesByRecord.put(
                    f.Parent_Record_Id__c,
                    new Set<String>()
                );
            }
            existingFolderNamesByRecord
                .get(f.Parent_Record_Id__c)
                .add(f.Name);
        }

        /* ---------------------------------------------------
           4️⃣ Create missing folders
        --------------------------------------------------- */
        List<Record_Document_Folder__c> foldersToInsert =
            new List<Record_Document_Folder__c>();

        for (Id recordId : newMap.keySet()) {

            Set<String> existingNames =
                existingFolderNamesByRecord.containsKey(recordId)
                ? existingFolderNamesByRecord.get(recordId)
                : new Set<String>();

            for (DocumentFolderConfigUtil.FolderConfig def : folderDefs) {

                if (String.isBlank(def.name)) continue;
                if (existingNames.contains(def.name)) continue;

                foldersToInsert.add(
                    new Record_Document_Folder__c(
                        Name = def.name,
                        Parent_Record_Id__c = recordId,
                        Parent_Object_API_Name__c = objectApiName,
                        Folder_Sequence__c = def.sequence
                    )
                );
            }
        }

        /* ---------------------------------------------------
           5️⃣ Insert
        --------------------------------------------------- */
        if (!foldersToInsert.isEmpty()) {
            insert foldersToInsert;
        }
    }
}