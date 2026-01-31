public class ConstructionUpdateBatch implements Database.Batchable<Construction_Update__c> {

    private List<Construction_Update__c> cuList;

    public ConstructionUpdateBatch(List<Construction_Update__c> cuList) {
        this.cuList = cuList;
    }

    // must return Iterable since data is already available
    public Iterable<Construction_Update__c> start(Database.BatchableContext bc) {
        return cuList;
    }

    public void execute( Database.BatchableContext bc, List<Construction_Update__c> scope ) {
        List<Construction_Update__c> updatesToMarkTriggered = new List<Construction_Update__c>();
        List<Payment_Schedule__c> paymentScheduleToInsert = new List<Payment_Schedule__c>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> policyIds  = new Set<Id>();

        for (Construction_Update__c cu : scope) {
            if (cu.Project__c != null) projectIds.add(cu.Project__c);
            if (cu.Policy__c  != null) policyIds.add(cu.Policy__c);
        }

        System.debug('Project Ids: ' + projectIds);
        System.debug('Policy Ids: ' + policyIds);

        Map<Id, Policy__c> policyMap = new Map<Id, Policy__c>(
            [SELECT Id, Term__c, Construction_Linked__c FROM Policy__c WHERE Id IN :policyIds]
        );

        System.debug('Policy Map:'+ policyMap);

        List<Opportunity> bookings = [SELECT Id, Owner.Email, Owner.Name, Project__c, Payment_Policy__c, Commission_Policy__c, Amount FROM Opportunity WHERE Project__c IN :projectIds AND (Payment_Policy__c IN :policyIds OR Commission_Policy__c IN :policyIds) ];
        System.debug('Bookings: ' + bookings);

        for (Construction_Update__c cu : scope) {

            Policy__c pol = policyMap.get(cu.Policy__c);
            if (pol == null) continue;
            ConstructionPolicyUtil.TermCheckResult termResult = ConstructionPolicyUtil.checkAnyPercent(pol.Term__c, cu);
            // Decide payment trigger ONCE per Construction Update
            Boolean shouldTriggerPayment = !cu.Is_Payment_Triggered__c && termResult.hasPercent && termResult.percent > 0;
            if (shouldTriggerPayment) {
                updatesToMarkTriggered.add(new Construction_Update__c( Id = cu.Id, Is_Payment_Triggered__c = true));
            }


            System.debug(' TERM CHECK RESULT');
            System.debug('Has Percent      : ' + termResult.hasPercent);
            System.debug('Percent Value    : ' + termResult.percent);
            System.debug('Payment Days     : ' + termResult.paymentWithinDays);
            System.debug('Policy Id        : ' + pol.Id);

            for (Opportunity b : bookings) {
                if (b.Project__c != cu.Project__c) continue;
                Boolean policyMatch = b.Payment_Policy__c == cu.Policy__c;
                if (!policyMatch) continue;
                
                if (shouldTriggerPayment) {
                    Decimal payableAmount;
                    if (b.Amount != null && termResult.percent != null) {
                        payableAmount = (b.Amount * termResult.percent) / 100;
                    }
                    System.debug('Demand Letter Email sent to: ' + b.Owner.Email);
                    ConstructionEmailService.sendUpdateWithDemandLetter(b, cu, termResult.percent, payableAmount, termResult.paymentWithinDays);

                    Date dueDate = Date.today()+termResult.paymentWithinDays;
                    Payment_Schedule__c ps = new Payment_Schedule__c(Name = cu.Name + ' - ' + dueDate.format(), Due_Date__c = dueDate, DueAmount__c = payableAmount, MilestoneName__c = cu.Name, DuePercentage__c = termResult.percent, PaymentStatus__c = 'Pending', Opportunity__c = b.Id, Is_Construction_Linked__c = true, Is_Active__c = true);
                    System.debug('Payment Schedule:'+ps);
                    paymentScheduleToInsert.add(ps);
                
                } else {
                    System.debug('Normal Update Email sent to: ' + b.Owner.Email);
                    ConstructionEmailService.sendConstructionUpdate(b, cu);
                }
            }
        }
        if(!paymentScheduleToInsert.isEmpty()){
            insert paymentScheduleToInsert;
        }
        if (!updatesToMarkTriggered.isEmpty()) {
            update updatesToMarkTriggered;
        }

    }

    public void finish(Database.BatchableContext bc) {}
}
