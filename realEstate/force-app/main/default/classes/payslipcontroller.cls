public class payslipcontroller {

    @AuraEnabled
    public static String generateAndSavePDF(String recordId) {
        try {
             Salary__c sal = [SELECT Id, Month__c, year__c From Salary__c WHERE Id = :recordId LIMIT 1];
            // Generate PDF
            Blob pdfBlob = getPdfBlob(recordId);
            ContentVersion content = new ContentVersion();
            content.Title = 'payslip- ' + sal.Month__c + ' ' + sal.year__c;
            content.PathOnClient = 'payslip' + recordId + '.pdf';
            content.VersionData = pdfBlob;
            content.FirstPublishLocationId = recordId;
            insert content;
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String sendPdfEmail(String recordId) {
        try {
            Salary__c sal = [SELECT Id, Name, Contact__r.Name, Month__c, year__c, Contact__r.Email from Salary__c WHERE Id = :recordId LIMIT 1];
            // Generate PDF
            Blob pdfBlob = getPdfBlob(recordId);
            String subject = 'Payslip for ' + sal.Month__c + ' ' + sal.year__c;

            // Get the contact email and first name
            // Contact contact = [SELECT FirstName, Email FROM Contact WHERE Id = :recordId LIMIT 1];
            	
               
            
            // Create the custom email body
            String body = 'Dear ' + sal.Contact__r.Name + ',\n\n' +
                          'Please find attached the salary slip for the ' + sal.Month__c + ' '+ sal.year__c  +'.\n\n' +
                          'If you have any queries, please contact the HR Department.\n\n' +
                          'Thank you,\n' +
                          'HR Department\n\n' +
                          '** This is a system generated email. Please do not reply to this email.';

            // Create email attachment
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Payslip-' + sal.Month__c + ' ' + sal.year__c + '.pdf');
            attachment.setBody(pdfBlob);

            // Send email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { sal.Contact__r.Email });
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

            // Set the sender's name
            mail.setSenderDisplayName('HRMS Portal');  // Display name of the sender

            // Set a non-reply email address (ensure you have a no-reply email address configured)
            mail.setReplyTo('noreply@vortexifysync.com');  // Non-reply email address

            // Add CC (Carbon Copy) - using sender's email address as the CC
            mail.setCcAddresses(new String[] { 'hr@vortexifysync.com' });  // Add sender's email as CC

            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error sending email: ' + e.getMessage());
        }
    }

    private static Blob getPdfBlob(String recordId) {
        PageReference pdfPage = Page.Payslip;
        pdfPage.getParameters().put('id', recordId);
        return pdfPage.getContent();
    }
}