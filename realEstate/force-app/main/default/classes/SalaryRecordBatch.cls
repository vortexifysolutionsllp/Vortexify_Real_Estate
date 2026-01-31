global class SalaryRecordBatch implements Database.Batchable<SObject>, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, CreatedDate
            FROM Contact
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Contact> contacts) {
        List<Salary__c> salaryToInsert = new List<Salary__c>();

        Date today = Date.today();
        Integer fyStartYear = getFinancialYear(today);

        for (Contact c : contacts) {
            if (c.Id == null) continue;

            Integer contactStartMonth = Math.max(4, c.CreatedDate.month()); // at least April
            for (Integer i = contactStartMonth; i <= 15; i++) {
                Integer actualMonth = (i > 12) ? i - 12 : i;
                String monthName = getMonthPicklistValue(actualMonth);

                Salary__c salary = new Salary__c(
                    Contact__c = c.Id,
                    Month__c = monthName,
                    Year__c = fyStartYear
                );

                salaryToInsert.add(salary);
            }
        }

        if (!salaryToInsert.isEmpty()) {
            try {
                insert salaryToInsert;
            } catch (DmlException e) {
                System.debug('⚠️ DML Error: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {}

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SalaryRecordBatch(), 200);
    }

    // Always uses system date to get FY start year
    public static Integer getFinancialYear(Date dt) {
        return (dt.month() >= 4) ? dt.year() : dt.year() - 1;
    }

    public static String getMonthPicklistValue(Integer monthNumber) {
        List<String> months = new List<String>{
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        };
        return (monthNumber >= 1 && monthNumber <= 12) ? months[monthNumber - 1] : 'Unknown';
    }
}