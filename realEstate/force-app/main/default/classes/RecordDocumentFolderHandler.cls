public with sharing class RecordDocumentFolderHandler {
    
    /* -------------------- CREATE SINGLE FOLDER (MANUAL) -------------------- */
    @AuraEnabled
    public static Boolean createFolder(String folderName, Id parentRecordId) {
        
        if (String.isBlank(folderName) || parentRecordId == null) {
            return false;
        }
        
        insert new Record_Document_Folder__c(
            Name = folderName,
            Parent_Record_Id__c = parentRecordId,
            Parent_Object_API_Name__c =
            parentRecordId.getSObjectType().getDescribe().getName()
        );
        return true;
    }
    
    /* -------------------- UPLOAD FILE -------------------- */
    @AuraEnabled
    public static Boolean uploadFileUnderFolder(
        Id folderId,
        String fileName,
        String base64Data
    ) {
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
        
        ContentVersion cv = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = fileBlob
        );
        insert cv;
        
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        insert new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = folderId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        return true;
    }
    
    /* -------------------- GET FOLDERS -------------------- */
    @AuraEnabled
    public static List<Record_Document_Folder__c> getFolders(Id parentRecordId) {
        
        return [
            SELECT Id, Name, Folder_Sequence__c,
            (SELECT ContentDocumentId, ContentDocument.Title
             FROM ContentDocumentLinks)
            FROM Record_Document_Folder__c
            WHERE Parent_Record_Id__c = :parentRecordId
            ORDER BY Folder_Sequence__c
        ];
    }
    
    /* -------------------- DELETE FILE -------------------- */
    @AuraEnabled
    public static void deleteFile(Id contentDocumentId) {
        delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
    }
}