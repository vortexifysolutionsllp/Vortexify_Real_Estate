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

        List<Opportunity> bookings = [SELECT Id, Owner.Email, Project__c, Amount FROM Opportunity WHERE Project__c IN :projectIds ];
        System.debug('Bookings: ' + bookings);

        for (Construction_Update__c cu : scope) {

            Policy__c pol = policyMap.get(cu.Policy__c);
            if (pol == null) continue;

            ConstructionPolicyUtil.TermCheckResult termResult = ConstructionPolicyUtil.checkAnyPercent(pol.Term__c);

            System.debug(' TERM CHECK RESULT');
            System.debug('Has Percent      : ' + termResult.hasPercent);
            System.debug('Percent Value    : ' + termResult.percent);
            System.debug('Payment Days     : ' + termResult.paymentWithinDays);
            System.debug('Policy Id        : ' + pol.Id);

            for (Opportunity b : bookings) {

                if (b.Project__c != cu.Project__c) continue;

                if (cu.Is_Payment_Triggered__c) {
                    System.debug(('Email sent to 1: ' + b.Owner.Email));
                    ConstructionEmailService.sendConstructionUpdate(b, cu);

                } else if (termResult.hasPercent) {
                    System.debug(('Email sent to 2: ' + b.Owner.Email));
                    ConstructionEmailService.sendConstructionUpdate( b, cu, termResult.paymentWithinDays);

                } else {
                    System.debug(('Email sent to 3: ' + b.Owner.Email));
                    ConstructionEmailService.sendUpdateWithDemandLetter(b, cu);
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}
}
