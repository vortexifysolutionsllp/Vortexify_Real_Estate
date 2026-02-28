public class ProductTriggerHandler {

    public static void createPBE(List<Product2> productList) {

        Id standardPBId = Test.isRunningTest()
            ? Test.getStandardPricebookId()
            : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

        List<PricebookEntry> pbeList = new List<PricebookEntry>();

        for (Product2 prod : productList) {
            //if (prod.Family == 'Unit'||) {

                PricebookEntry pbe = new PricebookEntry();
                pbe.Pricebook2Id     = standardPBId;
                pbe.Product2Id       = prod.Id;
                pbe.UnitPrice        = 0;          
                pbe.IsActive         = true;
                pbe.UseStandardPrice = false;
                //pbe.ProductCode      = prod.ProductCode;

                pbeList.add(pbe);
          //  }
        }

        if (!pbeList.isEmpty()) {
            insert pbeList;
        }
    }

    public static void handleBeforeInsert(List<Product2> productList){
        try{
            Schema.DescribeSObjectResult d = Schema.SObjectType.Product2; 
            Map<Id,Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();
            Set<Id> projectIds = new Set<Id>();
            Set<String> existingPLCnames = new Set<String>();
            Set<String> existingMiscNames = new Set<String>();
            for(Product2 prod : productList){
                String familyName = rtMapById.containsKey(prod.RecordTypeId) ? rtMapById.get(prod.RecordTypeId).getName():'';
                if(familyName != 'Misc'){
                    prod.Family = familyName;
                }else if(familyName == 'Misc' || familyName == 'PLC'){
                    projectIds.add(prod.Project__c);
                }
            }
            Set<String> existingFloorPLCs = new Set<String>();
            List<Product2> existingPLC = [SELECT Id,FloorNumber__c,Name, Project__c, RecordType.Name FROM Product2 WHERE Project__c IN :projectIds AND (RecordType.Name = 'PLC' OR RecordType.Name = 'Misc')];
            for(Product2 plc : existingPLC){
                if(plc.RecordType.Name == 'PLC' && plc.Name.containsIgnoreCase('Floor')){
                    existingFloorPLCs.add(plc.FloorNumber__c+'-'+plc.Project__c);
                }else if(plc.RecordType.Name == 'PLC'){
                    existingPLCnames.add(plc.Name+'-'+plc.Project__c);
                }else if(plc.RecordType.Name == 'Misc'){
                    existingMiscNames.add(plc.Name+'-'+plc.Project__c);
                }
            }
            for(Product2 prod : productList){
                if(existingFloorPLCs.contains(prod.FloorNumber__c+'-'+prod.Project__c)){
                    prod.addError('Floor PLC already exists for this project and floor combination.');
                }else if(existingPLCnames.contains(prod.Name+'-'+prod.Project__c)){
                    prod.addError('PLC already exists for this project and name combination.');
                }else if(existingMiscNames.contains(prod.Name+'-'+prod.Project__c)){
                    prod.addError('Misc charge already exists for this project and name combination.');
                }
            }
        }catch(exception e){
            System.debug('Error Message--> '+e.getMessage());
            System.debug('Error Line Number--> '+e.getLineNumber());
        }
    }
}
