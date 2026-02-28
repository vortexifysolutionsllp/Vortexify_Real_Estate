public with sharing class OpportunityUnitSummaryController {

    public class LineItemDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal amount;
    }

    public class TeamMemberDTO {
        @AuraEnabled public String recordId;
        @AuraEnabled public String userId;
        @AuraEnabled public String memberName;
        @AuraEnabled public Decimal commissionPercent;
    }

    public class UnitSummaryDTO {
        @AuraEnabled public String unitName;
        @AuraEnabled public Decimal area;
        @AuraEnabled public String unitType;
        @AuraEnabled public Decimal basePrice;
        @AuraEnabled public List<LineItemDTO> plcList;
        @AuraEnabled public List<LineItemDTO> parkingList;
        @AuraEnabled public List<LineItemDTO> miscList;
        @AuraEnabled public List<TeamMemberDTO> teamMembers;
    }

    @AuraEnabled(cacheable=true)
    public static UnitSummaryDTO getUnitSummary(Id opportunityId) {

        UnitSummaryDTO dto = new UnitSummaryDTO();
        dto.plcList = new List<LineItemDTO>();
        dto.parkingList = new List<LineItemDTO>();
        dto.miscList = new List<LineItemDTO>();
        dto.teamMembers = new List<TeamMemberDTO>();

        for(OpportunityLineItem oli : [
            SELECT Id,
                UnitPrice,
                Product2.Name,
                Product2.RecordType.Name,
                Product2.CarpetArea__c,
                Product2.UnitType__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ]){

            String rtName = oli.Product2.RecordType.Name;

            if(rtName == 'Unit'){
                dto.unitName = oli.Product2.Name;
                dto.basePrice = oli.UnitPrice;
                dto.area = oli.Product2.CarpetArea__c;
                dto.unitType = oli.Product2.UnitType__c;
            }
            else if(rtName == 'PLC'){
                dto.plcList.add(createDTO(oli));
            }
            else if(rtName == 'Parking'){
                dto.parkingList.add(createDTO(oli));
            }
            else if(rtName == 'Misc'){
                dto.miscList.add(createDTO(oli));
            }
        }

        for(Booking_Sales_Team_Allocation__c rec : [
            SELECT Id, User__c, User__r.Name, Commission_Allocation__c
            FROM Booking_Sales_Team_Allocation__c
            WHERE Booking__c = :opportunityId
        ]){
            TeamMemberDTO t = new TeamMemberDTO();
            t.recordId = rec.Id;
            t.userId = rec.User__c;
            t.memberName = rec.User__r.Name;
            t.commissionPercent = rec.Commission_Allocation__c;
            dto.teamMembers.add(t);
        }

        return dto;
    }

    private static LineItemDTO createDTO(OpportunityLineItem oli){
        LineItemDTO dto = new LineItemDTO();
        dto.id = oli.Id;
        dto.productName = oli.Product2.Name;
        dto.amount = oli.UnitPrice;
        return dto;
    }

    @AuraEnabled
    public static String saveUnitSummary(Id opportunityId, UnitSummaryDTO dto){

        List<OpportunityLineItem> updateList = new List<OpportunityLineItem>();

        for(LineItemDTO p : dto.plcList)
            updateList.add(new OpportunityLineItem(Id = p.id, UnitPrice = p.amount));

        for(LineItemDTO p : dto.parkingList)
            updateList.add(new OpportunityLineItem(Id = p.id, UnitPrice = p.amount));

        for(LineItemDTO p : dto.miscList)
            updateList.add(new OpportunityLineItem(Id = p.id, UnitPrice = p.amount));

        if(!updateList.isEmpty())
            update updateList;

        List<Booking_Sales_Team_Allocation__c> teamUpdate = new List<Booking_Sales_Team_Allocation__c>();

        for(TeamMemberDTO t : dto.teamMembers){
            teamUpdate.add(new Booking_Sales_Team_Allocation__c(
                Id = t.recordId,
                Commission_Allocation__c = t.commissionPercent
            ));
        }

        if(!teamUpdate.isEmpty())
            update teamUpdate;

        return 'SUCCESS';
    }
}