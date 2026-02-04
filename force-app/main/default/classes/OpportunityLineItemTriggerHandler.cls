public class OpportunityLineItemTriggerHandler {

    //flag to bypass validation- update only this line in sameer trigger
    public static boolean skipValidation = false;
    
    public static void validateOliCount(List<OpportunityLineItem> newOLIs){
         //skip when plc are inserted by system
        if(skipValidation) return;
        // untouched logic of sameer
        Set<Id> oppIds = new Set<Id>();
        
        for (OpportunityLineItem oli : newOLIs) {
            if (oli.OpportunityId != null) {
                oppIds.add(oli.OpportunityId);
            }
        }
        
        if (oppIds.isEmpty()) return;
        
        Map<Id, Integer> oliCountMap = new Map<Id, Integer>();
        
        for (AggregateResult ar : [
            SELECT OpportunityId oppId, COUNT(Id) cnt
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
            GROUP BY OpportunityId
        ]) {
            oliCountMap.put(
                (Id) ar.get('oppId'),
                (Integer) ar.get('cnt')
            );
        }
        
        for (OpportunityLineItem oli : newOLIs) {
            
            Integer existingCount =
                oliCountMap.containsKey(oli.OpportunityId)
                ? oliCountMap.get(oli.OpportunityId)
                : 0;
            
            if (existingCount >= 1) {
                oli.addError(
                    'Only one Opportunity Line Item can be added to an Opportunity.'
                );
            }
            
            oliCountMap.put(
                oli.OpportunityId,
                existingCount + 1
            );
        }
    }

    //plc creation logic
    
    //public static void createPLC(List<OpportunityLineItem> newList){
    //     Set<Id> productIds = new Set<Id>();
    //     Set<Id> oppIds = new Set<Id>();
    //     for(OpportunityLineItem oli: newList){
    //         if(oli.Product2Id != null) productIds.add(oli.Product2Id);
    //         if(oli.OpportunityId != null) oppIds.add(oli.OpportunityId);
    //     }
    //     Map<Id, Product2> products = new Map<Id, Product2>([
    //         Select Id, Name, Family, RecordType.Name,
    //         Applicable_PLC__c, Cost_Sqft__c, SaleableArea__c
    //         From Product2 Where Id IN :productIds
    //     ]);
    //     System.Debug('---MAP---- ');
    //     Map<String, Product2> plcProducts = new Map<String, Product2>();
    //     for(Product2 p: [
    //         Select Id, Name From Product2 Where RecordType.Name ='PLC'
    //     ]){
    //         plcProducts.put(p.Name, p);
    //     }
    //     System.Debug('----MAPplcProducts-----' + plcProducts);
    //     Map<Id, Id> pbeMap = new Map<Id, Id>();
    //     for(PricebookEntry pbe :[
    //         Select Id, Product2Id from PricebookEntry Where IsActive = true
    //     ]){
    //         pbeMap.put(pbe.Product2Id, pbe.Id);
    //         System.debug('---Map----' + pbeMap);
    //     }
    //     List<OpportunityLineItem> toInsert = new List<OpportunityLineItem>();
    //     for(OpportunityLineItem oli: newList){
    //         Product2 unit = products.get(oli.Product2Id);
    //         if(unit == null) continue;
    //         Boolean isUnit = unit.Family == 'Unit' || unit.RecordType.Name == 'Unit';
    //         System.debug('----enterd---'+ isUnit);
    //         if(!isUnit) continue;
    //         if(String.isBlank(unit.Applicable_PLC__c)) continue;
    //         for(String plcName: unit.Applicable_PLC__c.split(';')){
    //             plcName = plcName.trim();
    //             if(!plcProducts.containsKey(plcName)) continue;
    //             Product2 plcProd = plcProducts.get(plcName);
    //             Decimal plcPrice =  (unit.Cost_Sqft__c != null && unit.SaleableArea__c != null)
    //                 ? unit.Cost_Sqft__c * unit.SaleableArea__c
    //                 : 0;
    //             if(pbeMap.containsKey(plcProd.Id)){
    //                 toInsert.add(new OpportunityLineItem(
    //                     OpportunityId = oli.OpportunityId,
    //                     PricebookEntryId = pbeMap.get(plcProd.Id),
    //                     Quantity =1,
    //                     UnitPrice = plcPrice
    //                 ));
    //             }
    //         }
    //     }
        
    //     if(!toInsert.isEmpty()){
    //       //  skipValidation = true;
    //         insert toInsert;
    //         //skipValidation = false;
    //     }
    // }

    //plc creation logic
    public static void createPLC(List<OpportunityLineItem> newList){
        Set<Id> productIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();

        for(OpportunityLineItem oli : newList){
            if(oli.Product2Id != null) productIds.add(oli.Product2Id);
            if(oli.OpportunityId != null) oppIds.add(oli.OpportunityId);
        }

        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Id, Name, Family, RecordType.Name,
                   Applicable_PLC__c, Cost_Sqft__c, SaleableArea__c,
                   Tower__r.Project__c
            FROM Product2
            WHERE Id IN :productIds
        ]);

        Set<Id> projectIds = new Set<Id>();
        for(Product2 p : products.values()){
            if(p.Tower__r != null && p.Tower__r.Project__c != null){
                projectIds.add(p.Tower__r.Project__c);
            }
        }

        Map<String, Product2> plcProducts = new Map<String, Product2>();
        for(Product2 p : [
            SELECT Id, Name, Tower__r.Project__c
            FROM Product2
            WHERE (RecordType.Name = 'PLC' OR Family = 'PLC')
            AND Tower__r.Project__c IN :projectIds
        ]){
            String keyName = p.Name.toLowerCase().replace(' plc','').trim();
            plcProducts.put(keyName, p);
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Pricebook2Id FROM Opportunity WHERE Id IN :oppIds
        ]);

        Map<Id, Set<Id>> oppToExistingProducts = new Map<Id, Set<Id>>();
        for(OpportunityLineItem oli : [
            SELECT OpportunityId, PricebookEntry.Product2Id
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ]){
            if(!oppToExistingProducts.containsKey(oli.OpportunityId)){
                oppToExistingProducts.put(oli.OpportunityId, new Set<Id>());
            }
            oppToExistingProducts.get(oli.OpportunityId).add(oli.PricebookEntry.Product2Id);
        }

        Map<String, PricebookEntry> pbeMap = new Map<String, PricebookEntry>();
        for(PricebookEntry pbe : [
            SELECT Id, Product2Id, Pricebook2Id
            FROM PricebookEntry
            WHERE IsActive = true
        ]){
            pbeMap.put(pbe.Product2Id + '-' + pbe.Pricebook2Id, pbe);
        }

        List<OpportunityLineItem> toInsert = new List<OpportunityLineItem>();

        for(OpportunityLineItem oli : newList){

            Product2 unit = products.get(oli.Product2Id);
            if(unit == null) continue;

            Boolean isUnit = unit.Family == 'Unit' || unit.RecordType.Name == 'Unit';
            if(!isUnit) continue;

            if(String.isBlank(unit.Applicable_PLC__c)) continue;
            if(unit.Tower__r == null || unit.Tower__r.Project__c == null) continue;

            Opportunity opp = oppMap.get(oli.OpportunityId);
            if(opp == null || opp.Pricebook2Id == null) continue;

            Set<Id> existingProducts = oppToExistingProducts.get(oli.OpportunityId);
            if(existingProducts == null) existingProducts = new Set<Id>();

            for(String plcName : unit.Applicable_PLC__c.split(';')){
                plcName = plcName.toLowerCase().trim();  
                if(!plcProducts.containsKey(plcName)) continue;

                Product2 plcProd = plcProducts.get(plcName);
                if(existingProducts.contains(plcProd.Id)) continue;

                Decimal plcPrice = (unit.Cost_Sqft__c != null && unit.SaleableArea__c != null)
                    ? unit.Cost_Sqft__c * unit.SaleableArea__c
                    : 0;

                String key = plcProd.Id + '-' + opp.Pricebook2Id;

                if(pbeMap.containsKey(key)){
                    toInsert.add(new OpportunityLineItem(
                        OpportunityId = oli.OpportunityId,
                        PricebookEntryId = pbeMap.get(key).Id,
                        Quantity = 1,
                        UnitPrice = plcPrice
                    ));
                }
            }
        }

        if(!toInsert.isEmpty()){
            skipValidation = true;
            insert toInsert;
            skipValidation = false;
        }
    }
}
