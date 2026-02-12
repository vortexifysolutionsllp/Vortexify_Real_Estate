public with sharing class BookingCancellationController {

    @AuraEnabled
    public static void cancelBooking(Id opportunityId) {

        try {

            if (opportunityId == null) {
                throw new AuraHandledException('Invalid booking reference.');
            }

            Opportunity opp = [
                SELECT Id, Booking_Status__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            if (opp.Booking_Status__c == 'Cancelled') {
                throw new AuraHandledException('This booking is already cancelled.');
            }

            List<OpportunityLineItem> olis = [
                SELECT Product2Id
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunityId
                AND (Product2.RecordType.DeveloperName = 'Unit' OR Product2.Family = 'Unit')
            ];

            Set<Id> unitProductIds = new Set<Id>();

            for (OpportunityLineItem oli : olis) {
                if (oli.Product2Id != null) {
                    unitProductIds.add(oli.Product2Id);
                }
            }

            // Correct check
            if (unitProductIds.isEmpty()) {
                throw new AuraHandledException('No unit is allocated to this booking.');
            }

            List<Product2> unitsToUpdate = [
                SELECT Id, UnitStatus__c
                FROM Product2
                WHERE Id IN :unitProductIds
            ];

            for (Product2 unit : unitsToUpdate) {
                unit.UnitStatus__c = 'Available';
            }

            opp.Booking_Status__c = 'Cancelled';

            // Update together
            update opp;
            update unitsToUpdate;

        } catch (DmlException dmle) {
            throw new AuraHandledException(dmle.getDmlMessage(0));

        } catch (AuraHandledException ahe) {
            throw ahe;

        } catch (Exception e) {
            throw new AuraHandledException(
                'Something went wrong while cancelling the booking. Please try again.'
            );
        }
    }
}
