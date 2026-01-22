@isTest
private class LeadTriggerHandlerTest {
    @isTest
    static void testHandler() {
        Lead l = new Lead(LastName = 'Test Lead', Company = 'Test Company');
        Test.startTest();
        insert l;
        l.Company = 'Updated Company';
        update l;
        delete l;
        undelete l;
        Test.stopTest();
        System.assert(l.Id != null, 'Lead should be inserted');
    }
}
