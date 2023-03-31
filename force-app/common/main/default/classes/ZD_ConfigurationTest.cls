@isTest
public without sharing class ZD_ConfigurationTest {
    
    private static ZD_Application__mdt app1;
    private static ZD_Application__mdt app2;
    private static ZD_ApplicationConfiguration__mdt config1;
    private static ZD_ApplicationConfiguration__mdt config2;
    private static ZD_ApplicationConfiguration__mdt config3;
    
    private static void initializeMDT(){
        app1 = new ZD_Application__mdt();
        app1.DeveloperName = 'ZD_ConfigurationTest_testApp1';
        app1.Label = 'ZD_ConfigurationTest_testApp';
        app1.Id = ZD_Application.util.getFakeId(app1.getSObjectType().getDescribe().getKeyPrefix());
        
        app2 = new ZD_Application__mdt();
        app2.DeveloperName = 'ZD_ConfigurationTest_testApp2';
        app2.Label = 'ZD_ConfigurationTest_testApp';
        app2.Id = ZD_Application.util.getFakeId(app2.getSObjectType().getDescribe().getKeyPrefix());

        config1 = new ZD_ApplicationConfiguration__mdt();
        config1.Application__c = app1.Id;
        config1.Application__r = app1;
        config1.Active__c = true;
        config1.Key__c = 'key1';
        config1.Value__c = 'value1';
        config1.Id = ZD_Application.util.getFakeId(config1.getSObjectType().getDescribe().getKeyPrefix());

        config2 = new ZD_ApplicationConfiguration__mdt();
        config2.Application__c = app1.Id;
        config2.Application__r = app1;
        config2.Active__c = true;
        config2.Key__c = 'key2';
        config2.Value__c = 'value2';
        config2.Id = ZD_Application.util.getFakeId(config2.getSObjectType().getDescribe().getKeyPrefix());
        
        config3 = new ZD_ApplicationConfiguration__mdt();
        config3.Application__c = app2.Id;
        config3.Application__r = app2;
        config3.Active__c = true;
        config3.Key__c = 'key3';
        config3.Value__c = 'value3';
        config3.Id = ZD_Application.util.getFakeId(config3.getSObjectType().getDescribe().getKeyPrefix());
    }
    
    @isTest
    public static void testConstructorWithAppName(){
        initializeMDT();
        List<SObject> appConfigMdtList = new List<SObject>{config1, config2};
        ZD_VirtualCallable svc = (ZD_VirtualCallable) ZD_CallableFactory.getFactory().getCallableInstance('ZD_DatabaseService');
        ZD_Application.startMocking();
       	String query = 'SELECT Key__c, Value__c, Application__r.DeveloperName FROM ZD_ApplicationConfiguration__mdt WHERE Application__r.DeveloperName =: appName';
        svc.setReturnValue('querywithbinds', new Map<String,Object>{'query' => query, 
            														'bindMap' => new Map<String,Object>{'appName' => 'ZD_ConfigurationTest_testApp1'}, 
            														'accessLevel' => System.AccessLevel.SYSTEM_MODE},appConfigMdtList);
        ZD_Application.stopMocking();
        
        Test.startTest();
        ZD_Configuration zdc = new ZD_Configuration('ZD_ConfigurationTest_testApp1');
        Test.stopTest();
        Assert.areEqual(zdc.get('key1'), 'value1', 'key1 should have value1 in the cache');
        Assert.areEqual(zdc.get('key2'), 'value2', 'key2 should have value2 in the cache');
    }
    
    @isTest
    public static void testConstructorWithoutAppName(){
        initializeMDT();
        List<SObject> appConfigMdtList = new List<SObject>{config3};
        ZD_VirtualCallable svc = (ZD_VirtualCallable) ZD_CallableFactory.getFactory().getCallableInstance('ZD_DatabaseService');
        ZD_Application.startMocking();
       	String query = 'SELECT Key__c, Value__c, Application__r.DeveloperName FROM ZD_ApplicationConfiguration__mdt WHERE Application__r.DeveloperName =: appName';
        svc.setReturnValue('querywithbinds', new Map<String,Object>{'query' => query, 
            														'bindMap' => new Map<String,Object>{'appName' => 'ZD_ConfigurationTest_testApp2'}, 
            														'accessLevel' => System.AccessLevel.SYSTEM_MODE},appConfigMdtList);
        ZD_Application.stopMocking();
        
        Test.startTest();
        ZD_Configuration zdc = new ZD_Configuration();
        try{
            zdc.get('ZD_ConfigurationTest_testApp2', 'key3');
            Assert.fail();
        }catch(ZD_Configuration.ZD_ConfigurationException e){
            Assert.isTrue(e.getMessage().contains('ZD_ConfigurationTest_testApp2 config has not been loaded'));
        }
        zdc.loadConfig('ZD_ConfigurationTest_testApp2');
        Assert.areEqual(zdc.get('ZD_ConfigurationTest_testApp2', 'key3'), 'value3', 'key3 should have value3 in the cache');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetWithoutDefaultApp(){
        Test.startTest();
        ZD_Configuration zdc = new ZD_Configuration();
        try{
            zdc.get('key3');
            Assert.fail();
        }catch(ZD_Configuration.ZD_ConfigurationException e){
            Assert.isTrue(e.getMessage().contains('No default app set, please provide an application name'));
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testKeysetWithoutDefaultApp(){
        Test.startTest();
        ZD_Configuration zdc = new ZD_Configuration();
        try{
            zdc.keySet();
            Assert.fail();
        }catch(ZD_Configuration.ZD_ConfigurationException e){
            Assert.isTrue(e.getMessage().contains('No default app set, please provide an application name'));
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testKeysetWithDefaultApp(){
        initializeMDT();
        List<SObject> appConfigMdtList = new List<SObject>{config1, config2};
        ZD_VirtualCallable svc = (ZD_VirtualCallable) ZD_CallableFactory.getFactory().getCallableInstance('ZD_DatabaseService');
        ZD_Application.startMocking();
       	String query = 'SELECT Key__c, Value__c, Application__r.DeveloperName FROM ZD_ApplicationConfiguration__mdt WHERE Application__r.DeveloperName =: appName';
        svc.setReturnValue('querywithbinds', new Map<String,Object>{'query' => query, 
            														'bindMap' => new Map<String,Object>{'appName' => 'ZD_ConfigurationTest_testApp1'}, 
            														'accessLevel' => System.AccessLevel.SYSTEM_MODE},appConfigMdtList);
        ZD_Application.stopMocking();
        
        Test.startTest();
        ZD_Configuration zdc = new ZD_Configuration('ZD_ConfigurationTest_testApp1');
        Assert.areEqual(zdc.keySet().size(), 2, '2 keys in the cache');
        Assert.isTrue(zdc.keySet().contains('key1'), 'key1 should be in the cache');
        Assert.isTrue(zdc.keySet().contains('key2'), 'key2 should be in the cache');
        Test.stopTest();
    }
    
     @isTest
    public static void testKeysetWithoutAppLoaded(){
        Test.startTest();
        ZD_Configuration zdc = new ZD_Configuration();
        try{
            Set<String> keySet = zdc.keySet('ZD_ConfigurationTest_testApp1');
            Assert.fail();
        }catch(ZD_Configuration.ZD_ConfigurationException e){
            Assert.isTrue(e.getMessage().contains('Application: ZD_ConfigurationTest_testApp1 config has not been loaded'));
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testKeysetWithMultipleApps(){
        initializeMDT();
        List<SObject> appConfigMdtList1 = new List<SObject>{config1, config2};
        List<SObject> appConfigMdtList2 = new List<SObject>{config3};
        ZD_VirtualCallable svc = (ZD_VirtualCallable) ZD_CallableFactory.getFactory().getCallableInstance('ZD_DatabaseService');
        ZD_Application.startMocking();
       	String query = 'SELECT Key__c, Value__c, Application__r.DeveloperName FROM ZD_ApplicationConfiguration__mdt WHERE Application__r.DeveloperName =: appName';
        svc.setReturnValue('querywithbinds', new Map<String,Object>{'query' => query, 
            														'bindMap' => new Map<String,Object>{'appName' => 'ZD_ConfigurationTest_testApp1'}, 
            														'accessLevel' => System.AccessLevel.SYSTEM_MODE},appConfigMdtList1);
        svc.setReturnValue('querywithbinds', new Map<String,Object>{'query' => query, 
            														'bindMap' => new Map<String,Object>{'appName' => 'ZD_ConfigurationTest_testApp2'}, 
            														'accessLevel' => System.AccessLevel.SYSTEM_MODE},appConfigMdtList2);
        ZD_Application.stopMocking();
        
        Test.startTest();
        ZD_Configuration zdc = new ZD_Configuration();
        zdc.loadConfig('ZD_ConfigurationTest_testApp1');
        zdc.loadConfig('ZD_ConfigurationTest_testApp2');
        Assert.areEqual(zdc.keySet('ZD_ConfigurationTest_testApp1').size(), 2, '2 keys in the cache');
        Assert.isTrue(zdc.keySet('ZD_ConfigurationTest_testApp1').contains('key1'), 'key1 should be in the cache');
        Assert.isTrue(zdc.keySet('ZD_ConfigurationTest_testApp1').contains('key2'), 'key2 should be in the cache');
        Assert.areEqual(zdc.keySet('ZD_ConfigurationTest_testApp2').size(), 1, '1 keys in the cache');
        Assert.isTrue(zdc.keySet('ZD_ConfigurationTest_testApp2').contains('key3'), 'key3 should be in the cache');
        Test.stopTest();
    }
}