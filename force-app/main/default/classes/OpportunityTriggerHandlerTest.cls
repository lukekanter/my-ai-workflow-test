@isTest
private class OpportunityTriggerHandlerTest {
    @isTest
    static void testHandler() {
        Opportunity o = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today());
        Test.startTest();
        insert o;
        o.StageName = 'Closed Won';
        update o;
        delete o;
        undelete o;
        Test.stopTest();
        System.assert(o.Id != null, 'Opportunity should be inserted');
    }
}
