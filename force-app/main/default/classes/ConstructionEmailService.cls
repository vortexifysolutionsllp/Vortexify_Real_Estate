public class ConstructionEmailService {

    public static void sendConstructionUpdate( Opportunity opp, Construction_Update__c cu) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { opp.Owner.Email });

        mail.setSubject('Construction Update - ' + cu.Name);

        System.debug('Opp Owner Name:'+ opp.Owner.Name);
        System.debug('Construction Milestone:'+ cu.Name);

        String htmlBody =
            '<html>' +
            '<body style="margin:0;padding:0;font-family:Arial,Helvetica,sans-serif;color:#333333;">' +

            '<table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f9;padding:20px;">' +
            '<tr><td align="center">' +

            '<table width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border:1px solid #dddddd;">' +

            // Header
            '<tr>' +
            '<td style="padding:16px 24px;background-color:#1f2937;color:#ffffff;font-size:16px;font-weight:bold;">' +
            'Construction Update Notification' +
            '</td>' +
            '</tr>' +

            // Body
            '<tr>' +
            '<td style="padding:24px;font-size:14px;line-height:1.6;">' +
            '<p>Dear ' + opp.Owner.Name + ',</p>' +

            '<p>This is to formally inform you that a construction update has been recorded for your booking.</p>' +

            '<p><strong>Construction Milestone: </strong>' + cu.Name + '</p>' +

            '<p>At this stage, no payment action is required from your end.</p>' +

            '<p>We appreciate your continued cooperation.</p>' +

            '<p style="margin-top:24px;">Yours sincerely,<br/>' +
            '<strong>Project Management Office</strong></p>' +
            '</td>' +
            '</tr>' +

            // Footer
            '<tr>' +
            '<td style="padding:12px 24px;background-color:#f9fafb;font-size:11px;color:#666666;border-top:1px solid #dddddd;">' +
            'This is a system-generated email. Please do not reply.' +
            '</td>' +
            '</tr>' +

            '</table>' +
            '</td></tr>' +
            '</table>' +

            '</body></html>';

            System.debug(htmlBody);

        mail.setHtmlBody(htmlBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public static void sendUpdateWithDemandLetter( Opportunity opp, Construction_Update__c cu, Decimal percentValue, Decimal payableAmount, Integer paymentWithinDays) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { opp.Owner.Email });
        mail.setSubject('Payment Due - Construction Milestone ' + cu.Name);

        String deadlineText = '';
        if (paymentWithinDays != null && paymentWithinDays > 0) {
            deadlineText =
                '<p><strong>Payment Timeline:</strong><br/>' +
                'Payment to be completed within ' +
                paymentWithinDays + ' days from this notification.</p>';
        }

        System.debug('Opp Owner Name:' +opp.Owner.Name);
        System.debug('percentage value:'+percentValue);
        System.debug('payableamount:'+payableAmount.setScale(0));
        System.debug('deadlineText:'+deadlineText);

        String htmlBody =
            '<html><body style="font-family:Arial,Helvetica,sans-serif;color:#333;">' +
            '<table width="100%" style="background:#f4f6f9;padding:20px;"><tr><td align="center">' +
            '<table width="600" style="background:#ffffff;border:1px solid #dddddd;">' +

            '<tr><td style="padding:16px;background:#991b1b;color:#ffffff;font-weight:bold;">' +
            'Payment Due Notification</td></tr>' +

            '<tr><td style="padding:24px;font-size:14px;line-height:1.6;">' +
            '<p>Dear ' + opp.Owner.Name + ',</p>' +
            '<p>The following construction milestone has been completed:</p>' +
            '<p><strong>Milestone: </strong>' + cu.Name + '</p>' +
            '<p>As per your payment plan, <strong>' + percentValue +
            '%</strong> of the total booking amount is now due.</p>' +
            '<p><strong>Payable Amount: </strong>' +
            '<strong>₹' + payableAmount.setScale(0) + '</strong></p>' +
            deadlineText +
            '<p>Kindly ensure timely payment to avoid any inconvenience.</p>' +
            '<p>Yours sincerely,<br/><strong>Finance & Accounts Department</strong></p>' +
            '</td></tr>' +

            '<tr><td style="padding:12px;font-size:11px;color:#666;border-top:1px solid #ddd;">' +
            'This is a system-generated email. Please do not reply.</td></tr>' +

            '</table></td></tr></table></body></html>';

            System.debug(htmlBody);

        mail.setHtmlBody(htmlBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
}
