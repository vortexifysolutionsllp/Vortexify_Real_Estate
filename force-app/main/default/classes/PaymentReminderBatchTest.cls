@isTest
public with sharing class PaymentReminderBatchTest {
    @testSetup
    static void createTestDta(){
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contact con = new Contact(
            FirstName = 'test',
            LastName ='Contact',
            Email ='testcontact@sample.com',
            AccountId = acc.Id
        );
        insert con;
        Opportunity opp = new Opportunity(
            Name = 'test opp',
            StageName ='Pospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = con.Id,
            Role = 'Decision Maker',
            IsPrimary = true
        );
        insert ocr;


        List<Payment_Schedule__c> schedules = new List<Payment_Schedule__c>{
            new Payment_Schedule__c(
                 Name = 'PS-15',
                Opportunity__c = opp.Id,
                Due_Date__c = Date.today().addDays(15),
                DueAmount__c = 15000
            ),
            new Payment_Schedule__c(
                Name = 'PS-7',
                Opportunity__c = opp.Id,
                Due_Date__c = Date.today().addDays(7),
                DueAmount__c = 7000
            ),
            new Payment_Schedule__c(
                Name = 'PS-1',
                Opportunity__c = opp.Id,
                Due_Date__c = Date.today().addDays(1),
                DueAmount__c = 1000
            )
        };
        insert schedules;

       
        Account accNoEmail = new Account(Name = 'No Email Account');
        insert accNoEmail;

        Contact conNoEmail = new Contact(
            FirstName = 'No',
            LastName = 'Email',
            AccountId = accNoEmail.Id
        );
        insert conNoEmail;

        Opportunity oppNoEmail = new Opportunity(
            Name = 'Opp No Email',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = accNoEmail.Id
        );
        insert oppNoEmail;

        insert new OpportunityContactRole(
            OpportunityId = oppNoEmail.Id,
            ContactId = conNoEmail.Id,
            Role = 'Decision Maker',
            IsPrimary = true
        );

        insert new Payment_Schedule__c(
            Name = 'PS-NoEmail',
            Opportunity__c = oppNoEmail.Id,
            Due_Date__c = Date.today().addDays(7),
            DueAmount__c = 5000
        );
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new PaymentReminderBatch(), 5);
        Test.stopTest();

        
        System.assertEquals(3, Limits.getEmailInvocations());
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2099';
        System.schedule('Payment Reminder Job Test', cronExp, new PaymentReminderBatch());
        Test.stopTest();

        
        System.assertEquals(1, Limits.getEmailInvocations());
    }

    @isTest
    static void testNoMatchingRecords() {
        delete [SELECT Id FROM Payment_Schedule__c];

        Test.startTest();
        Database.executeBatch(new PaymentReminderBatch(), 5);
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations());
    }
}