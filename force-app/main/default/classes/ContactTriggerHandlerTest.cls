@isTest
private class ContactTriggerHandlerTest {
    @isTest
    static void testHandler() {
        Contact c = new Contact(LastName = 'Test Contact');
        Test.startTest();
        insert c;
        c.LastName = 'Updated Name';
        update c;
        delete c;
        undelete c;
        Test.stopTest();
        System.assert(c.Id != null, 'Contact should be inserted');
    }
}
