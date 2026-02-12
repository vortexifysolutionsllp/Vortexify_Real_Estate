public with sharing class unitAllocationController {
 
    @AuraEnabled(cacheable=true)

    public static List<Tower__c> getTowersByProject(Id projectId) {

        return [

            SELECT Id, Name, Total_Floors__c

            FROM Tower__c

            WHERE Project__c = :projectId

            ORDER BY Name

        ];

    }
 
    @AuraEnabled

    public static List<Product2> getUnitsByTowerAndFloor(

        Id towerId,

        Integer floorNumber

    ) {

        return [

            SELECT Id,

                   Name,

                   UnitNumber__c,

                   UnitStatus__c,

                   Booked__c,

                   Blocked__c

            FROM Product2

            WHERE Tower__c = :towerId

            AND FloorNumber__c = :floorNumber

            ORDER BY UnitNumber__c

        ]; 

    }

    @AuraEnabled

public static void createOppsForUnits(List<Id> unitIds, Id leadId,Id opportunityId) {
 
    List<Pricebook2> stdPbList = [

    SELECT Id

    FROM Pricebook2

    WHERE IsStandard = true

    LIMIT 1

];
 
if (stdPbList.isEmpty()) {

    throw new AuraHandledException('Standard Pricebook not found or inactive.');

}
 
Id standardPricebookId = stdPbList[0].Id;
 
 
    // -------------------- VALIDATION --------------------

    if (unitIds == null || unitIds.isEmpty()) {

        throw new AuraHandledException('No units selected.');

    }
 
    if (leadId != null && !String.valueOf(leadId).startsWith('00Q')) {

        System.debug('Lead ID is not a valid Lead. Resetting leadId.');

        leadId = null;

    }
 
    Id accountId;

    Id contactId;

    Boolean isLeadContext = leadId != null && String.valueOf(leadId).startsWith('00Q');

    Boolean isOpportunityContext = opportunityId != null && String.valueOf(opportunityId).startsWith('006');

    if (!isLeadContext && !isOpportunityContext) {

        throw new AuraHandledException('Invalid context.');

    }
 
    // ==================== OPPORTUNITY CONTEXT ====================

if (isOpportunityContext) {
 
    // Safety: only one unit allowed

    if (unitIds.size() != 1) {

        throw new AuraHandledException('Only one unit can be allocated to an Opportunity.');

    }
 
    // Fetch Opportunity

    Opportunity opp = [

        SELECT Id, Pricebook2Id

        FROM Opportunity

        WHERE Id = :opportunityId

        LIMIT 1

    ];

List<OpportunityLineItem> existingOlis = [
    SELECT Id, Product2Id
    FROM OpportunityLineItem
    WHERE OpportunityId = :opp.Id
    LIMIT 1
];

 
    if (opp.Pricebook2Id == null) {

    opp.Pricebook2Id = standardPricebookId;

    update opp;

}
 
if (!existingOlis.isEmpty() && existingOlis[0].Product2Id == unitIds[0]) {
    return;
}

if (!existingOlis.isEmpty()) {
    update new Product2(
        Id = existingOlis[0].Product2Id,
        UnitStatus__c = 'Available'
    );

    delete existingOlis;
}

 
    List<PricebookEntry> pbeList = [

    SELECT Id

    FROM PricebookEntry

    WHERE Product2Id = :unitIds[0]

    AND Pricebook2Id = :opp.Pricebook2Id

    AND IsActive = true

    LIMIT 1

];
 
if (pbeList.isEmpty()) {

    throw new AuraHandledException(

        'Selected unit does not have an active Pricebook Entry in this Pricebook.'

    );

}
 
PricebookEntry pbe = pbeList[0];
 
 
    // Create OLI

    OpportunityLineItem oli = new OpportunityLineItem(

        OpportunityId = opp.Id,

        PricebookEntryId = pbe.Id,

        Quantity = 1,

        UnitPrice = 0

    );
 
    insert oli;
 
    // Update Unit status

    update new Product2(

        Id = unitIds[0],

        UnitStatus__c = 'Booked'

    );
 
    return; 

}
 
    // -------------------- LEAD CONVERSION --------------------

    if (leadId != null) {
 
        Lead lead = [

            SELECT Id, IsConverted, Status

            FROM Lead

            WHERE Id = :leadId

            LIMIT 1

        ];
 
        System.debug('Lead fetched: ' + lead);

        System.debug('Is Lead Converted? ' + lead.IsConverted);
 
        if (!lead.IsConverted) {
 
             List<LeadStatus> lsList = [

    SELECT MasterLabel

    FROM LeadStatus

    WHERE IsConverted = true

    LIMIT 1

];
 
if (lsList.isEmpty()) {

    throw new AuraHandledException('No converted Lead Status configured.');

}
 
LeadStatus ls = lsList[0];
 
 
            System.debug('Converted Lead Status Found: ' + ls.MasterLabel);
 
            Database.LeadConvert lc = new Database.LeadConvert();

            lc.setLeadId(lead.Id);

            lc.setConvertedStatus(ls.MasterLabel);

            lc.setDoNotCreateOpportunity(false);
 
            System.debug('LeadConvert Request: ' + lc);
 
            Database.LeadConvertResult lcr = Database.convertLead(lc);
 
            System.debug('LeadConvert Result Success? ' + lcr.isSuccess());

            System.debug('LeadConvert Errors: ' + lcr.getErrors());

            System.debug('Converted AccountId: ' + lcr.getAccountId());

            System.debug('Converted ContactId: ' + lcr.getContactId());

            System.debug('Converted OpportunityId: ' + lcr.getOpportunityId());
 
            if (!lcr.isSuccess()) {

                throw new AuraHandledException(

                    'Lead conversion failed: ' +

                    (lcr.getErrors().isEmpty() ? 'Unknown error' : lcr.getErrors()[0].getMessage())

                );

            }
 
            accountId = lcr.getAccountId();

            contactId = lcr.getContactId();

        } else {

            System.debug('Lead is already converted. Skipping conversion.');

        }

    } else {

        System.debug('No Lead ID provided. Skipping Lead conversion.');

    }
 
    // -------------------- FALLBACK ACCOUNT --------------------

    if (accountId == null) {

List<Account> accList = [SELECT Id FROM Account LIMIT 1];
 
if (accList.isEmpty()) {

    throw new AuraHandledException('No Account found to associate Opportunity.');

}
 
accountId = accList[0].Id;

        System.debug('Using fallback AccountId: ' + accountId);

    }
 
    // -------------------- PRICEBOOK ENTRIES --------------------

    List<PricebookEntry> pbes = [

        SELECT Id, Product2Id, Pricebook2Id

        FROM PricebookEntry

        WHERE Product2Id IN :unitIds

        AND IsActive = true

    ];
 
    System.debug('PricebookEntries found: ' + pbes.size());
 
    Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>();

    for (PricebookEntry pbe : pbes) {

        if (!pbeMap.containsKey(pbe.Product2Id)) {

            pbeMap.put(pbe.Product2Id, pbe);

        }

    }
 
    for (Id unitId : unitIds) {

        if (!pbeMap.containsKey(unitId)) {

            throw new AuraHandledException('Unit does not have an active Pricebook Entry.');

        }

    }
 
    Id pricebookId = pbes[0].Pricebook2Id;

    System.debug('Using PricebookId: ' + pricebookId);
 
    // -------------------- UNIT DATA --------------------

    Map<Id, Product2> unitMap = new Map<Id, Product2>([

        SELECT Id, Name, UnitNumber__c, Tower__r.Project__r.Name

        FROM Product2

        WHERE Id IN :unitIds

    ]);
 
    String leadName = '';

    if (leadId != null) {

        Lead l = [SELECT Name FROM Lead WHERE Id = :leadId LIMIT 1];

        leadName = l.Name;

    }
     // -------------------- CREATE OPPORTUNITIES --------------------

    List<Opportunity> oppsToInsert = new List<Opportunity>();
 
    for (Id unitId : unitIds) {

        Product2 unit = unitMap.get(unitId);
 
        oppsToInsert.add(new Opportunity(

            Name = leadName + ' / ' + unit.Tower__r.Project__r.Name,

            StageName = 'Unit Blocked',

            Project__c = unit.Tower__r.Project__c,

            CloseDate = Date.today().addDays(30),

            AccountId = accountId,

            Lead_Id__c = leadId != null ? String.valueOf(leadId) : null,

            Pricebook2Id = pricebookId

        ));

    }
 
    insert oppsToInsert;

    System.debug('Opportunity created: ' + oppsToInsert);
 
      // -------------------- CONTACT ROLES --------------------

    if (contactId != null) {

        List<OpportunityContactRole> roles = new List<OpportunityContactRole>();

        for (Opportunity opp : oppsToInsert) {

            roles.add(new OpportunityContactRole(

                OpportunityId = opp.Id,

                ContactId = contactId,

                Role = 'Decision Maker',

                IsPrimary = true

            ));

        }

        insert roles;

    }
 
    // -------------------- OPPORTUNITY LINE ITEMS --------------------

    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
 
    for (Integer i = 0; i < unitIds.size(); i++) {

        olis.add(new OpportunityLineItem(

            OpportunityId = oppsToInsert[i].Id,

            PricebookEntryId = pbeMap.get(unitIds[i]).Id,

            Quantity = 1,

            UnitPrice = 0

        ));

    }
 
    insert olis;

    System.debug('OpportunityLineItems inserted: ' + olis.size());
 
    // -------------------- UPDATE UNIT STATUS --------------------

    List<Product2> unitsToUpdate = new List<Product2>();

    for (Id unitId : unitIds) {

        unitsToUpdate.add(new Product2(

            Id = unitId,

            UnitStatus__c = 'Booked'

        ));

    }
 
    update unitsToUpdate;

    System.debug('Units updated to Booked.');
 
    System.debug('==== END createOppsForUnits ====');

}
 
@AuraEnabled(cacheable=true)
public static Product2 getAllocatedUnit(Id opportunityId) {
    List<OpportunityLineItem> oliList = [
        SELECT Product2Id,
               Product2.FloorNumber__c,
               Product2.Tower__c
        FROM OpportunityLineItem
        WHERE OpportunityId = :opportunityId
        LIMIT 1
    ];

    if (oliList.isEmpty()) return null;

    return [
        SELECT Id, UnitStatus__c, FloorNumber__c, Tower__c
        FROM Product2
        WHERE Id = :oliList[0].Product2Id
        LIMIT 1
    ];
}

 
}