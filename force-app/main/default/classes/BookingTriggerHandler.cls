public with sharing class BookingTriggerHandler {
    public static void UpdateBookingStage(List<Opportunity> newList, Map<Id, Opportunity> oldMap){
        for(Opportunity opp : newList){
            if(oldMap == null){
                if(opp.Payment_Policy__c != null){
                    opp.StageName = 'Booked';
                }
            }
            else{
                Opportunity oldOpp = oldMap.get(opp.Id);
                if(opp.Payment_Policy__c != oldOpp.Payment_Policy__c){
                    opp.StageName = 'Booked';
                }
            }
        }
    }

    public static void createPaymentSchedule(List<Opportunity> newList, Map<Id, Opportunity> oldMap){
        Set<Id> policyIds = new Set<Id>();
        List<Opportunity> eligibleOpps = new List<Opportunity>();

        for(Opportunity opp : newList){
            Boolean policyChanged;

            if(oldMap == null){
                policyChanged = opp.Payment_Policy__c != null;
            }else{
                policyChanged = opp.Payment_Policy__c != oldMap.get(opp.Id).Payment_Policy__c;
            }

            if(policyChanged && opp.Payment_Policy__c != null ){
                eligibleOpps.add(opp);
                policyIds.add(opp.Payment_Policy__c);
            }
        }
        if(eligibleOpps.isEmpty()) return;

        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp: eligibleOpps){
            oppIds.add(opp.Id);
        }

        Map<Id, Policy__c> policyMap = new Map<Id, Policy__c>([SELECT Id, Term__c, Construction_Linked__c FROM Policy__c WHERE Id IN :policyIds]);
        List<Payment_Schedule__c> oldPaymentSchedule = [SELECT Id, Is_Active__c FROM Payment_Schedule__c WHERE Opportunity__c IN :oppIds AND Is_Active__c = true];

        List<Payment_Schedule__c> schedulesToInsert = new List<Payment_Schedule__c>();

        for(Opportunity opp : eligibleOpps){
            Policy__c pol = policyMap.get(opp.Payment_Policy__c);
            if(pol == null) continue;
            // Do nothing if policy is Construction Linked or if Policy term is null.
            if(pol.Construction_Linked__c) continue;
            if(String.isBlank(pol.Term__c)) continue;

            List<PolicyTermWrapper> terms = (List<PolicyTermWrapper>) JSON.deserialize(pol.Term__c, List<PolicyTermWrapper>.class);
            for (PolicyTermWrapper term : terms) {
                Decimal pct;
                Integer days;
                try {
                    pct = Decimal.valueOf(term.percent);
                } catch (Exception e) {
                    continue;
                }
                
                try {
                    days = String.isNotBlank(term.paymentWithin) ? Integer.valueOf(term.paymentWithin) : 0;
                } catch (Exception e) {
                    days = 0;
                }
                
                Decimal amount = opp.Amount != null ? (opp.Amount * pct) / 100 : 0;
                if(pct>0){
                    schedulesToInsert.add(new Payment_Schedule__c(Name = term.termName + ' - ' + Date.today(),Opportunity__c = opp.Id, MilestoneName__c = term.termName,DuePercentage__c = pct,DueAmount__c = amount,Due_Date__c = Date.today().addDays(days),PaymentStatus__c = 'Pending',Is_Active__c = true,Is_Construction_Linked__c = false));
                }
            }

        }


        for(Payment_Schedule__c oldPaySc: oldPaymentSchedule){
            oldPaySc.Is_Active__c = false;
        }

        if(schedulesToInsert.size()>0){
            insert schedulesToInsert;
        }

        if(oldPaymentSchedule.size()>0){
            update oldPaymentSchedule;
        }
    }
}