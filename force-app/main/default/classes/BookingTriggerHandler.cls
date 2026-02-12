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

    public static void createBookingCommissionAndUserCommissionAllocations(List<Opportunity> newBookingList,Map<Id, Opportunity> oldMap){
        Set<Id> bookedOppIds = new Set<Id>();
        Set<Id> commissionPolicyIds = new Set<Id>();
        Map<Id, Id> oppToBCMap = new Map<Id, Id>();
        
        for(Opportunity opp : newBookingList){
            if((oldMap == null && opp.StageName == 'Booked') || 
            (oldMap != null && opp.StageName == 'Booked' && oldMap.get(opp.Id).StageName != 'Booked')){
                
                bookedOppIds.add(opp.Id);
                if(opp.Commission_Policy__c != null){
                    commissionPolicyIds.add(opp.Commission_Policy__c);
                }
            }
        }

        if(commissionPolicyIds.isEmpty()){
            return;
        }
        
        Map<Id, Policy__c> policyMap = new Map<Id, Policy__c>(
            [SELECT Id, Term__c FROM Policy__c WHERE Id IN :commissionPolicyIds]
        );

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, Name, Amount, Commission_Policy__c 
            FROM Opportunity 
            WHERE Id IN :bookedOppIds]
        );

        List<Booking_Commission__c> existingBookingCommissions = [
            SELECT Id, Booking__c 
            FROM Booking_Commission__c 
            WHERE Booking__c IN :bookedOppIds
        ];

        for(Booking_Commission__c existing: existingBookingCommissions){
            oppToBCMap.put(existing.Booking__c, existing.Id);
        }

        List<Booking_Commission__c> bookingCommissionList = new List<Booking_Commission__c>();

        for(Id oppId : bookedOppIds){
            if(oppToBCMap.containsKey(oppId)){
                continue;
            }

            Opportunity opp = oppMap.get(oppId);

            Booking_Commission__c bc = new Booking_Commission__c();
            bc.Name = 'Booking Commission for ' + opp.Name;
            bc.Booking__c = opp.Id;

            bookingCommissionList.add(bc);
        }

        if(!bookingCommissionList.isEmpty()){
            insert bookingCommissionList;
        }

        for(Booking_Commission__c bc : bookingCommissionList){
            oppToBCMap.put(bc.Booking__c, bc.Id);
        }

        // Fetch Booking Sales Team Allocations
        List<Booking_Sales_Team_Allocation__c> allocList = [
            SELECT Id, Booking__c, User__c, User__r.Name, Commission_Allocation__c 
            FROM Booking_Sales_Team_Allocation__c 
            WHERE Booking__c IN :bookedOppIds
        ];

        if(allocList.isEmpty()){
            return;
        }

        // Check existing User Commission Allocations
        Set<Id> bcIds = new Set<Id>(oppToBCMap.values());

        Map<String, User_Commission_Allocation__c> existingUcaMap = new Map<String, User_Commission_Allocation__c>();

        for(User_Commission_Allocation__c uca : [
            SELECT Id, Booking_Commission__c, User__c
            FROM User_Commission_Allocation__c
            WHERE Booking_Commission__c IN :bcIds
        ]){
            existingUcaMap.put(uca.Booking_Commission__c + '-' + uca.User__c, uca);
        }

        List<User_Commission_Allocation__c> userAllocList = new List<User_Commission_Allocation__c>();

        for(Booking_Sales_Team_Allocation__c alloc : allocList){

            Opportunity opp = oppMap.get(alloc.Booking__c);
            Policy__c pol = policyMap.get(opp.Commission_Policy__c);
            if(pol == null || String.isBlank(pol.Term__c)) continue;

            Decimal totalCommission = 0;

            PolicyTermWrapper term = (PolicyTermWrapper) JSON.deserialize(
                pol.Term__c, 
                PolicyTermWrapper.class
            );

            // Fixed
            if(term.policyType == 'fixed' && term.active == true){
                totalCommission = Decimal.valueOf(term.amount);
            }
            // Percentage
            else if(term.policyType == 'percentage' && term.active == true){
                Decimal percentVal = Decimal.valueOf(term.percent);
                totalCommission = (opp.Amount * percentVal)/100;

                if(term.upperCap != null && totalCommission > term.upperCap){
                    totalCommission = term.upperCap;
                }
            }
            // Range
            else if(term.policyType == 'range' && term.active == true && term.ranges != null){
                for(PolicyRangeWrapper r : term.ranges){

                    Decimal minAmt = Decimal.valueOf(r.minAmount);
                    Decimal maxAmt = Decimal.valueOf(r.maxAmount);

                    if(opp.Amount >= minAmt && opp.Amount <= maxAmt){

                        if(r.commissionType == 'fixed'){
                            totalCommission = Decimal.valueOf(r.amount);
                        }
                        else if(r.commissionType == 'percentage'){
                            Decimal pct = Decimal.valueOf(r.percent);
                            totalCommission = (opp.Amount * pct) / 100;

                            if(r.upperCap != null && totalCommission > r.upperCap){
                                totalCommission = r.upperCap;
                            }
                        }
                    }
                }
            }

            Decimal allocationPercent = alloc.Commission_Allocation__c;
            Decimal allocatedAmount = (allocationPercent / 100) * totalCommission;

            Id bcId = oppToBCMap.get(alloc.Booking__c);
            String key = bcId + '-' + alloc.User__c;

            if(!existingUcaMap.containsKey(key)){
                User_Commission_Allocation__c uca = new User_Commission_Allocation__c();
                uca.Booking_Commission__c = bcId;
                uca.User__c = alloc.User__c;
                uca.Allocation__c = allocationPercent;
                uca.Allocated_Commission_Amount__c = allocatedAmount;
                uca.Name = 'User Commission Allocation for ' + alloc.User__r.Name;

                userAllocList.add(uca);
            }
        }

        if(!userAllocList.isEmpty()){
            insert userAllocList;
        }
    }

}