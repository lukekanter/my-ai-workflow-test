@isTest
private class TriggerHandlerTest {

  private static final String TRIGGER_CONTEXT_ERROR = 'Trigger handler called outside of Trigger execution';

  private class TestHandler extends TriggerHandler {
    public override void beforeInsert() {
      TriggerHandlerTest.lastMethodCalled = 'beforeInsert';
    }
    public override void  beforeUpdate() {
      TriggerHandlerTest.lastMethodCalled = 'beforeUpdate';
    }
    public override void beforeDelete() {
      TriggerHandlerTest.lastMethodCalled = 'beforeDelete';
    }
    public override void afterInsert() {
      TriggerHandlerTest.lastMethodCalled = 'afterInsert';
    }
    public override void afterUpdate() {
      TriggerHandlerTest.lastMethodCalled = 'afterUpdate';
    }
    public override void afterDelete() {
      TriggerHandlerTest.lastMethodCalled = 'afterDelete';
    }
    public override void afterUndelete() {
      TriggerHandlerTest.lastMethodCalled = 'afterUndelete';
    }
  }

  private static String lastMethodCalled;

  @isTest
  static void testBeforeInsert() {
    TestHandler handler = new TestHandler();
    handler.setTriggerContext('before insert', true);
    handler.run();
    System.assertEquals('beforeInsert', lastMethodCalled, 'beforeInsert should be called');
  }

  @isTest
  static void testBeforeUpdate() {
    TestHandler handler = new TestHandler();
    handler.setTriggerContext('before update', true);
    handler.run();
    System.assertEquals('beforeUpdate', lastMethodCalled, 'beforeUpdate should be called');
  }

  @isTest
  static void testBeforeDelete() {
    TestHandler handler = new TestHandler();
    handler.setTriggerContext('before delete', true);
    handler.run();
    System.assertEquals('beforeDelete', lastMethodCalled, 'beforeDelete should be called');
  }

  @isTest
  static void testAfterInsert() {
    TestHandler handler = new TestHandler();
    handler.setTriggerContext('after insert', true);
    handler.run();
    System.assertEquals('afterInsert', lastMethodCalled, 'afterInsert should be called');
  }

  @isTest
  static void testAfterUpdate() {
    TestHandler handler = new TestHandler();
    handler.setTriggerContext('after update', true);
    handler.run();
    System.assertEquals('afterUpdate', lastMethodCalled, 'afterUpdate should be called');
  }

  @isTest
  static void testAfterDelete() {
    TestHandler handler = new TestHandler();
    handler.setTriggerContext('after delete', true);
    handler.run();
    System.assertEquals('afterDelete', lastMethodCalled, 'afterDelete should be called');
  }

  @isTest
  static void testAfterUndelete() {
    TestHandler handler = new TestHandler();
    handler.setTriggerContext('after undelete', true);
    handler.run();
    System.assertEquals('afterUndelete', lastMethodCalled, 'afterUndelete should be called');
  }

  @isTest
  static void testBypassAPI() {
    TriggerHandler.bypass('TestHandler');
    TestHandler handler = new TestHandler();
    handler.setTriggerContext('before insert', true);
    handler.run();
    System.assertEquals(null, lastMethodCalled, 'Handler should be bypassed');

    TriggerHandler.clearBypass('TestHandler');
    handler = new TestHandler();
    handler.setTriggerContext('before insert', true);
    handler.run();
    System.assertEquals('beforeInsert', lastMethodCalled, 'Handler should execute after clear bypass');
  }
  
  @isTest
  static void testIsBypassed() {
      TriggerHandler.bypass('TestHandler');
      System.assert(TriggerHandler.isBypassed('TestHandler'), 'Should be true');
      TriggerHandler.clearAllBypasses();
      System.assert(!TriggerHandler.isBypassed('TestHandler'), 'Should be false');
  }

  @isTest
  static void testLoopCount() {
    TestHandler handler = new TestHandler();
    handler.setMaxLoopCount(2);
    handler.setTriggerContext('before insert', true);
    
    handler.run(); // 1
    handler.run(); // 2
    
    try {
      handler.run(); // 3 - Exception
      System.assert(false, 'Should have thrown exception');
    } catch(Exception e) {
      System.assert(e.getMessage().contains('Maximum loop count'), 'Exception message mismatch');
    }
    
    handler.clearMaxLoopCount();
    try {
        handler.run(); // Should pass
    } catch(Exception e) {
        System.assert(false, 'Should not throw exception after clear');
    }
  }

  @isTest
  static void testVirtualMethods() {
    TriggerHandler th = new TriggerHandler();
    th.beforeInsert();
    th.beforeUpdate();
    th.beforeDelete();
    th.afterInsert();
    th.afterUpdate();
    th.afterDelete();
    th.afterUndelete();
  }
}
