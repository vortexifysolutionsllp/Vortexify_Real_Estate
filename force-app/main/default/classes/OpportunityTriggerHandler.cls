public class OpportunityTriggerHandler {

    public static void handleStageChange(
        List<Opportunity> newList,
        Map<Id, Opportunity> oldMap
    ) {

        Set<Id> oppIds = new Set<Id>();

        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (oldOpp != null && opp.StageName != oldOpp.StageName) {
                oppIds.add(opp.Id);
            }
        }

        if (!oppIds.isEmpty()) {
            applyStateToUnits(oppIds);
        }
    }

    // =====================================================
    // CORE LOGIC
    // =====================================================
    private static void applyStateToUnits(Set<Id> oppIds) {

        List<OpportunityLineItem> oliList = [
            SELECT Id,
                   Opportunity.StageName,
                   Product2Id,
                   Product2.Family,
                   Blocked__c,
                   BlockedDate__c,
                   Booked__c,
                   BookingDate__c,
                   ReleaseDate__c,
                   CancelledDate__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
            AND Product2.Family = 'Unit'
        ];

        if (oliList.isEmpty()) return;

        Map<Id, Boolean> wasBlockedMap = new Map<Id, Boolean>();
        Map<Id, Boolean> wasBookedMap  = new Map<Id, Boolean>();

        for (OpportunityLineItem oli : oliList) {
            wasBlockedMap.put(oli.Id, oli.Blocked__c);
            wasBookedMap.put(oli.Id, oli.Booked__c);
        }

        Set<Id> productIds = new Set<Id>();

        // =========================
        // OLI UPDATE
        // =========================
        for (OpportunityLineItem oli : oliList) {

            String stage = oli.Opportunity.StageName;
            productIds.add(oli.Product2Id);

            Boolean wasBlocked = wasBlockedMap.get(oli.Id);
            Boolean wasBooked  = wasBookedMap.get(oli.Id);

            // Reset active states
            oli.Blocked__c = false;
            oli.BlockedDate__c = null;
            oli.Booked__c = false;
            oli.BookingDate__c = null;

            // 🔥 NEW: Clear history when NOT cancelled
            if (stage != 'Cancelled') {
                oli.ReleaseDate__c = null;
                oli.CancelledDate__c = null;
            }

            if (stage == 'Blocked') {
                oli.Blocked__c = true;
                oli.BlockedDate__c = Date.today();
            }
            else if (stage == 'Booked') {
                oli.Booked__c = true;
                oli.BookingDate__c = Date.today();
            }
            else if (stage == 'Cancelled' || stage == 'Closed Lost') {

                if (wasBooked) {
                    oli.CancelledDate__c = Date.today();
                }
                else if (wasBlocked) {
                    oli.ReleaseDate__c = Date.today();
                }
            }
        }

        update oliList;

        // =========================
        // PRODUCT UPDATE
        // =========================
        List<Product2> products = [
            SELECT Id,
                   Blocked__c,
                   BlockedDtae__c,
                   Booked__c,
                   BookingDate__c,
                   ReleaseDate__c,
                   CancelledDate__c
            FROM Product2
            WHERE Id IN :productIds
        ];

        for (Product2 prod : products) {

            for (OpportunityLineItem oli : oliList) {
                if (oli.Product2Id == prod.Id) {

                    String stage = oli.Opportunity.StageName;
                    Boolean wasBlocked = wasBlockedMap.get(oli.Id);
                    Boolean wasBooked  = wasBookedMap.get(oli.Id);

                    prod.Blocked__c = false;
                    prod.BlockedDtae__c = null;
                    prod.Booked__c = false;
                    prod.BookingDate__c = null;

                    // 🔥 NEW: Clear history when NOT cancelled
                    if (stage != 'Cancelled') {
                        prod.ReleaseDate__c = null;
                        prod.CancelledDate__c = null;
                    }

                    if (stage == 'Blocked') {
                        prod.Blocked__c = true;
                        prod.BlockedDtae__c = Date.today();
                    }
                    else if (stage == 'Booked') {
                        prod.Booked__c = true;
                        prod.BookingDate__c = Date.today();
                    }
                    else if (stage == 'Cancelled' || stage == 'Closed Lost') {

                        if (wasBooked) {
                            prod.CancelledDate__c = Date.today();
                        }
                        else if (wasBlocked) {
                            prod.ReleaseDate__c = Date.today();
                        }
                    }
                    break;
                }
            }
        }

        update products;
    }
}
