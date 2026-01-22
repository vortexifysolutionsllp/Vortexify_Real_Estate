public class ConstructionPolicyUtil {

    public class TermCheckResult {
        public Boolean hasPercent = false;
        public Decimal percent = 0;
        public Integer paymentWithinDays = 0;
    }

    public static TermCheckResult checkAnyPercent(String termJson, Construction_Update__c cu ) {

        System.debug('Current Construction Update:' + cu);

        TermCheckResult result = new TermCheckResult();

        if (String.isBlank(termJson)) {
            return result;
        }

        List<PolicyTermWrapper> terms = (List<PolicyTermWrapper>) JSON.deserialize(termJson, List<PolicyTermWrapper>.class );
        System.debug('terms:'+terms);

        for (PolicyTermWrapper term : terms) {
            System.debug('term percentage:'+term.percent);
            System.debug('term name:' +term.termName);
            System.debug('construction update name:'+ cu.Name);

            // 'Construction Update' record name should matches with any 'Term' record name.
            if (term.termName == cu.Name && !String.isBlank(term.percent)) {

                Decimal pct = Decimal.valueOf(term.percent);
                System.debug('pct: ' + pct);

                if (pct > 0) {
                    result.hasPercent = true;
                    result.percent = pct;

                    if (!String.isBlank(term.paymentWithin)) {
                        System.debug('paymentWithin:'+ term.paymentWithin);
                        result.paymentWithinDays = Integer.valueOf(term.paymentWithin);
                    }
                    break;
                }
            }
        }
        return result;
    }
}
