@isTest
private class ContractTriggerHandlerTest {
    @isTest
    static void testHandler() {
        Account a = new Account(Name = 'Contract Account');
        insert a;
        
        Contract c = new Contract(AccountId = a.Id, Status = 'Draft', StartDate = Date.today(), ContractTerm = 12);
        Test.startTest();
        insert c;
        c.Status = 'Activated';
        update c;
        delete c;
        undelete c;
        Test.stopTest();
        System.assert(c.Id != null, 'Contract should be inserted');
    }
}
