public class ConstructionEmailService {

    // When percentage > 0
    public static void sendConstructionUpdate(Opportunity opp, Construction_Update__c cu, Integer paymentWithinDays) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(
            new String[] { opp.Owner.Email }
        );

        mail.setSubject('Construction Update – Payment Due');

        String amountStr = opp.Amount != null ? '₹' + String.valueOf(opp.Amount) : 'the applicable amount';

        String body = 'Construction update has been posted.\n\n' + 'Your payment for ' + amountStr + ' is due.';

        if (paymentWithinDays != null && paymentWithinDays > 0) {
            body += '\nPlease make the payment within ' + paymentWithinDays + ' days.';
        }

        mail.setPlainTextBody(body);

        Messaging.sendEmail(
            new Messaging.SingleEmailMessage[] { mail }
        );
    }

    // When Is_Payment_Triggered__c = true
    public static void sendConstructionUpdate( Opportunity opp, Construction_Update__c cu) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(
            new String[] { opp.Owner.Email }
        );

        mail.setSubject('Construction Update');

        mail.setPlainTextBody( 'Construction update has been posted.' );

        Messaging.sendEmail(
            new Messaging.SingleEmailMessage[] { mail }
        );
    }

    public static void sendUpdateWithDemandLetter( Opportunity opp, Construction_Update__c cu) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(
            new String[] { opp.Owner.Email }
        );

        mail.setSubject('Construction Update & Demand Letter');

        mail.setPlainTextBody( 'Construction update has been posted along with a demand letter.' );

        Messaging.sendEmail(
            new Messaging.SingleEmailMessage[] { mail }
        );
    }
}
