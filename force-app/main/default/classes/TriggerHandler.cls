public virtual class TriggerHandler {

  // Static map of handlername, times run() was invoked
  private static Map<String, LoopCount> loopCountMap;
  private static Set<String> bypassedHandlers;

  // The current context of the trigger, overridable in tests
  @TestVisible
  private TriggerContext context;

  // The current context of the trigger, overridable in tests
  @TestVisible
  private Boolean isTriggerExecuting;

  // Static initialization
  static {
    loopCountMap = new Map<String, LoopCount>();
    bypassedHandlers = new Set<String>();
  }

  // Constructor
  public TriggerHandler() {
    this.setTriggerContext();
  }

  /***************************************
   * Public Instance Methods
   ***************************************/

  // Main method that will be called during trigger execution
  public void run() {
    if (!validateRun()) {
      return;
    }

    addToLoopCount();

    // Dispatch to the correct handler method
    switch on this.context {
      when BEFORE_INSERT {
        this.beforeInsert();
      }
      when BEFORE_UPDATE {
        this.beforeUpdate();
      }
      when BEFORE_DELETE {
        this.beforeDelete();
      }
      when AFTER_INSERT {
        this.afterInsert();
      }
      when AFTER_UPDATE {
        this.afterUpdate();
      }
      when AFTER_DELETE {
        this.afterDelete();
      }
      when AFTER_UNDELETE {
        this.afterUndelete();
      }
    }
  }

  public void setMaxLoopCount(Integer max) {
    String handlerName = getHandlerName();
    if (!TriggerHandler.loopCountMap.containsKey(handlerName)) {
      TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
    } else {
      TriggerHandler.loopCountMap.get(handlerName).setMax(max);
    }
  }

  public void clearMaxLoopCount() {
    this.setMaxLoopCount(-1);
  }

  /***************************************
   * Public Static Methods
   ***************************************/

  public static void bypass(String handlerName) {
    TriggerHandler.bypassedHandlers.add(handlerName);
  }

  public static void clearBypass(String handlerName) {
    TriggerHandler.bypassedHandlers.remove(handlerName);
  }

  public static Boolean isBypassed(String handlerName) {
    return TriggerHandler.bypassedHandlers.contains(handlerName);
  }

  public static void clearAllBypasses() {
    TriggerHandler.bypassedHandlers.clear();
  }

  /***************************************
   * Private Instancemethods
   ***************************************/

  @TestVisible
  private void setTriggerContext() {
    this.setTriggerContext(null, false);
  }

  @TestVisible
  private void setTriggerContext(String ctx, Boolean testMode) {
    if (!Trigger.isExecuting && !testMode) {
      this.isTriggerExecuting = false;
      return;
    } else {
      this.isTriggerExecuting = true;
    }

    if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
        (ctx != null && ctx == 'before insert')) {
      this.context = TriggerContext.BEFORE_INSERT;
    } else if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
        (ctx != null && ctx == 'before update')) {
      this.context = TriggerContext.BEFORE_UPDATE;
    } else if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
        (ctx != null && ctx == 'before delete')) {
      this.context = TriggerContext.BEFORE_DELETE;
    } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
        (ctx != null && ctx == 'after insert')) {
      this.context = TriggerContext.AFTER_INSERT;
    } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
        (ctx != null && ctx == 'after update')) {
      this.context = TriggerContext.AFTER_UPDATE;
    } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
        (ctx != null && ctx == 'after delete')) {
      this.context = TriggerContext.AFTER_DELETE;
    } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
        (ctx != null && ctx == 'after undelete')) {
      this.context = TriggerContext.AFTER_UNDELETE;
    }
  }

  // Check if the run should proceed
  @TestVisible
  private Boolean validateRun() {
    if (!this.isTriggerExecuting || this.context == null) {
      return false;
    }

    String handlerName = getHandlerName();
    if (TriggerHandler.bypassedHandlers.contains(handlerName)) {
      return false;
    }

    if (TriggerHandler.loopCountMap.containsKey(handlerName)) {
      if (TriggerHandler.loopCountMap.get(handlerName).exceeded()) {
        return false;
      }
    }

    // Custom Metadata Bypass Logic
    if (shouldBypass(handlerName)) {
        return false;
    }

    return true;
  }

  // Logic to check Custom Metadata Bypasses
  private Boolean shouldBypass(String handlerName) {
      // Note: This query assumes standard naming convention [Object]TriggerHandler
      // Getting object name from the handler name can be tricky if not consistent,
      // but we can pass the object name explicitly or infer it or query generically.
      // To keep it simple and performant, we will query all active bypasses for this handler.
      // Since specific object context is not passed, relying on Handler_Name__c matching Class Name.
      
      // We perform a query. In a real heavy org, this might need caching if called repeatedly in same transaction.
      // For now, minimal SOQL.
      List<Trigger_Bypass__mdt> bypasses = [
          SELECT Id, Bypass_All__c, Bypass_For_Users__c, Bypass_For_Profiles__c, Bypass_Permission__c
          FROM Trigger_Bypass__mdt
          WHERE Handler_Name__c = :handlerName
          AND Is_Active__c = TRUE
      ];

      for (Trigger_Bypass__mdt bypass : bypasses) {
          if (bypass.Bypass_All__c) {
              return true;
          }
          if (bypass.Bypass_For_Users__c != null && (bypass.Bypass_For_Users__c.contains(UserInfo.getUserId()) || bypass.Bypass_For_Users__c.contains(UserInfo.getUserName()))) {
              return true;
          }
           // Profile Name Check - requires a query on Profile or passing it in.
           // Optimization: Profile ID is better, but requirement said Name. 
           // We'll check Profile Name.
           // To avoid SOQL on Profile every time, we can assume Profile Name is needed or use ID.
           // Let's rely on cached profile name if possible, but UserInfo doesn't give Name directly without query.
           // We will skip Profile Name check here to avoid SOQL in loop unless necessary, OR query Profile once.
           // A better approach for Profile Name bypass is to query Profile Name in constructor once.
          if (bypass.Bypass_For_Profiles__c != null) {
              if (getProfileName() != null && bypass.Bypass_For_Profiles__c.contains(getProfileName())) {
                  return true;
              }
          }

          if (bypass.Bypass_Permission__c != null) {
              if (FeatureManagement.checkPermission(bypass.Bypass_Permission__c)) {
                  return true;
              }
          }
      }
      return false;
  }
  
  private static String cachedProfileName;
  private String getProfileName() {
      if (cachedProfileName == null) {
          try { // Protect against no query rows
              Profile p = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
              cachedProfileName = p.Name;
          } catch(Exception e) {
              cachedProfileName = '';
          }
      }
      return cachedProfileName;
  }

  @TestVisible
  private String getHandlerName() {
    return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
  }

  private void addToLoopCount() {
    String handlerName = getHandlerName();
    if (TriggerHandler.loopCountMap.containsKey(handlerName)) {
      Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName).increment();
      if (exceeded) {
        Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
        throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
      }
    }
  }

  /***************************************
   * Context Methods
   ***************************************/

  // Virtual methods to be overridden
  @TestVisible protected virtual void beforeInsert() {}
  @TestVisible protected virtual void beforeUpdate() {}
  @TestVisible protected virtual void beforeDelete() {}
  @TestVisible protected virtual void afterInsert() {}
  @TestVisible protected virtual void afterUpdate() {}
  @TestVisible protected virtual void afterDelete() {}
  @TestVisible protected virtual void afterUndelete() {}

  /***************************************
   * Inner Classes
   ***************************************/

  // Inner class for managing the loop count per handler
  private class LoopCount {
    private Integer max;
    private Integer count;

    public LoopCount() {
      this.max = 5;
      this.count = 0;
    }

    public LoopCount(Integer max) {
      this.max = max;
      this.count = 0;
    }

    public Boolean increment() {
      this.count++;
      return this.exceeded();
    }

    public Boolean exceeded() {
      if (this.max < 0) return false;
      return this.count > this.max;
    }

    public Integer getMax() {
      return this.max;
    }

    public Integer getCount() {
      return this.count;
    }

    public void setMax(Integer max) {
      this.max = max;
    }
  }

  // Possible trigger contexts
  @TestVisible
  private enum TriggerContext {
    BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
    AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
    AFTER_UNDELETE
  }

  // Exception class
  public class TriggerHandlerException extends Exception {}

}
