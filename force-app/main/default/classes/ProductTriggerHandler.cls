public class ProductTriggerHandler {

    public static void createPBE(List<Product2> productList) {

        Id standardPBId = Test.isRunningTest()
            ? Test.getStandardPricebookId()
            : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

        List<PricebookEntry> pbeList = new List<PricebookEntry>();

        for (Product2 prod : productList) {
            //if (prod.Family == 'Unit'||) {

                PricebookEntry pbe = new PricebookEntry();
                pbe.Pricebook2Id     = standardPBId;
                pbe.Product2Id       = prod.Id;
                pbe.UnitPrice        = 0;          
                pbe.IsActive         = true;
                pbe.UseStandardPrice = false;
                //pbe.ProductCode      = prod.ProductCode;

                pbeList.add(pbe);
          //  }
        }

        if (!pbeList.isEmpty()) {
            insert pbeList;
        }
    }
}
