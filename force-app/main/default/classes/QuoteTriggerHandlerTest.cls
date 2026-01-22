@isTest
private class QuoteTriggerHandlerTest {
    @isTest
    static void testHandler() {
        // Create an Opportunity first as Quote requires it
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;
        
        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id);
        Test.startTest();
        insert q;
        q.Name = 'Updated Quote';
        update q;
        delete q;
        undelete q;
        Test.stopTest();
        System.assert(q.Id != null, 'Quote should be inserted');
    }
}
