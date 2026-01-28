public with sharing class PaymentReminderBatch implements Database.Batchable<sObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext bc){
        Date today = Date.today();
        
        Set<Date> remainderDate = new Set<Date>{
            today.addDays(15),
            today.addDays(7),
            today.addDays(1)
        };
        return Database.getQueryLocator([
            SELECT Id, Name, Due_Date__c, Opportunity__c, DueAmount__c
            FROM Payment_Schedule__c
            WHERE Due_Date__c IN :remainderDate
            AND Opportunity__c != NULL
        ]);
    }
    public void execute(Database.BatchableContext bc, List<Payment_Schedule__c> scope){
        /*Map<String, Id> templateMap = new Map<String, Id>();
        for(EmailTemplate template : [
            SELECT Id, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName IN ('X15_Days_Payment_alert', 'X7_Days_Payment_alert', 'X1_Day_Payment_alert')
        ]){
             templateMap.put(template.DeveloperName, template.Id);
        }*/
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Set<Id> oppIds = new Set<Id>();
        for(Payment_Schedule__c pay : scope){
            if(pay.Opportunity__c != null){
                oppIds.add(pay.Opportunity__c);
            }
            }
            Map<Id,Contact> oppToContact = new Map<Id, Contact>();
            for(OpportunityContactRole ocr : [
            SELECT OpportunityId, Contact.Name, Contact.Email
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIds
            AND IsPrimary = true
        ]){
            if(ocr.Contact != null && !String.isBlank(ocr.Contact.Email)){
                oppToContact.put(ocr.OpportunityId, ocr.Contact);
            }
        }
        for(Payment_Schedule__c pay : scope){

            if(pay.Due_Date__c == null) continue;

            Contact c = oppToContact.get(pay.Opportunity__c);
            if(c == null) continue;

            String contactName = c.Name;
            String contactEmail = c.Email;
           String amountText = pay.DueAmount__c != null 
           ? '₹ ' + pay.DueAmount__c.format() 
           : 'N/A';


            //Integer daysLeft = pay.Due_Date__c.daysBetween(Date.today())
            Integer daysLeft = Date.today().daysBetween(pay.Due_Date__c);
            /*Id templateId;
            if(daysLeft == 15){
                templateId = templateMap.get('X15_Days_Payment_alert');
            }
            else if(daysLeft == 7){
                 templateId = templateMap.get('X7_Days_Payment_alert');
            }
            else if(daysLeft == 1){
                 templateId = templateMap.get('X1_Day_Payment_alert');
            }
            if(templateId == null){
                System.debug('Template missing for daysLeft = ' + daysLeft);
                 continue;
            }*/
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{contactEmail});
            /*mail.setSubject('Payment Reminder - ' + daysLeft + 'day(s) remaining');
            String body ='Hello ' + pay.Contact__r.Name + ',\n\n' +
            'This is a reminder that your payment is due in ' + daysLeft + ' day(s).\n\n' +
            'Please make the payment as soon as possible.\n\n' +
            'Thank you for your business.\n\n' +
            'Best regards,\n' +
            'Vortexify Team';*/
            String subject;
            String body;
            if(daysLeft == 15){
                subject = 'Payment Reminder - 15 days remaining';
                body = 'Hello ' + contactName + ',\n\n' +
                       'Just a friendly reminder that your payment "' + pay.Name +
                       '" is due in 15 days on ' + pay.Due_Date__c.format() + '.\n\n' +
                       'Pending Amount: ' + amountText + '\n\n' +
                       'Kindly ensure the payment is made on time.\n\n' +
                       'Thank you for your business.\n\n' +
                       'Best regards,\n' +
                       'Vortexify Team';
            }
            else if(daysLeft == 7){
                subject = 'Payment Reminder - 7 days remaining';
                body = 'Hello ' + contactName + ',\n\n' +
                       'This is an important reminder that your payment "' + pay.Name +
                       '" is due in 7 days on ' + pay.Due_Date__c.format() + '.\n\n' +
                       'Pending Amount: ' + amountText + '\n\n' +
                       'Kindly ensure the payment is made on time.\n\n' +
                       'Thank you for your business.\n\n' +
                       'Best regards,\n' +
                       'Vortexify Team';
            }
            else if(daysLeft == 1){
                subject = 'Payment Reminder - 1 day remaining';
                body = 'Hello ' + contactName + ',\n\n' +
                       'This is a final reminder that your payment "' + pay.Name +
                       '" is due TOMORROW (' + pay.Due_Date__c.format() + ').\n\n' +
                       'Pending Amount: ' + amountText + '\n\n' +
                       'Kindly ensure the payment is made immediately.\n\n' +
                       'Thank you for your business.\n\n' +
                       'Best regards,\n' +
                       'Vortexify Team';
            }
            else{
                continue;
            }
                

            mail.setSubject(subject);
           mail.setPlainTextBody(body);
            //mail.setTemplateId(templateId);
            //mail.setTargetObjectId(c.Id);
            //mail.setWhatId(pay.Id);  
           // mail.setSaveAsActivity(true);
            emails.add(mail);
        }
        if(!emails.isEmpty()){
            Messaging.sendEmail(emails);
        }
    }
    public void finish(Database.BatchableContext bc){
        System.debug('Batch completed');
    }
    public void execute(SchedulableContext sc){
        Database.executeBatch(new PaymentReminderBatch(), 100);
    }
   // public PaymentReminderBatch() {


}
