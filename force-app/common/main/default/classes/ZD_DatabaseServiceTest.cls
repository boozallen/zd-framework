/**
 * @description Test for the database service class
 * This software package is licensed under the Booz Allen Public License. 
 * Copyright © 2023 Booz Allen Hamilton Inc.  All Rights Reserved.
 */
@isTest
public without sharing class ZD_DatabaseServiceTest {
    
    @isTest
    public static void testSetAccessLevel(){
        Assert.areEqual(System.AccessLevel.USER_MODE, ((ZD_DatabaseService) ZD_DatabaseService.dbService).accessLevel, 'should be user mode by default');
        ZD_DatabaseService.setAccessLevel(System.AccessLevel.SYSTEM_MODE);
        Assert.areEqual(System.AccessLevel.SYSTEM_MODE, ((ZD_DatabaseService) ZD_DatabaseService.dbService).accessLevel, 'should be system mode now');
    }
    
    @isTest
    public static void testInsert(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        
        Test.startTest();
        Group g = new Group(Name='ZD_DatabaseService Group');
        ZD_DatabaseService.doInsert(new List<SObject>{g});
        Test.stopTest();
        
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(1, gList.size(), 'Should be one group');
    }
    
    @isTest
    public static void testInsertWithZDRecord(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        
        Test.startTest();
        Group g = new Group(Name='ZD_DatabaseService Group');
        ZD_DatabaseService.doInsert(new List<ZD_Record>{new ZD_Record(g)});
        Test.stopTest();
        
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(1, gList.size(), 'Should be one group');
    }
    
    @isTest
    public static void testUpdate(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        
        Test.startTest();
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        
        g.Name = 'ZD_DatabaseService Group - Update';
        ZD_DatabaseService.doUpdate(new List<SObject>{g});
        Test.stopTest();
        
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group - Update'];
        Assert.areEqual(1, gList.size(), 'Should be one group');
    }
    
    @isTest
    public static void testUpdateWithZDRecord(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        
        Test.startTest();
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        
        g.Name = 'ZD_DatabaseService Group - Update';
        ZD_DatabaseService.doUpdate(new List<ZD_Record>{new ZD_Record(g)});
        Test.stopTest();
        
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group - Update'];
        Assert.areEqual(1, gList.size(), 'Should be one group');
    }
    
    @isTest
    public static void testUpsert(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        
        Test.startTest();
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        
        g.Name = 'ZD_DatabaseServiceGroup-ZD_GroupSuffix';
        Group g2 = new Group(Name='ZD_DatabaseServiceGroup2-ZD_GroupSuffix');
        ZD_DatabaseService.doUpsert(new List<SObject>{g, g2});
        Test.stopTest();
        
        gList = [SELECT Id FROM Group WHERE Name LIKE '%ZD_GroupSuffix'];
        Assert.areEqual(2, gList.size(), 'Should be two groups');
    }
    
    @isTest
    public static void testUpsertWithZDRecords(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        
        Test.startTest();
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        
        g.Name = 'ZD_DatabaseServiceGroup-ZD_GroupSuffix';
        Group g2 = new Group(Name='ZD_DatabaseServiceGroup2-ZD_GroupSuffix');
        ZD_DatabaseService.doUpsert(new List<ZD_Record>{new ZD_Record(g), new ZD_Record(g2)});
        Test.stopTest();
        
        gList = [SELECT Id FROM Group WHERE Name LIKE '%ZD_GroupSuffix'];
        Assert.areEqual(2, gList.size(), 'Should be two groups');
    }
    
    @isTest
    public static void testDelete(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(1, gList.size(), 'should be 1 groups');
        
        Test.startTest();
        ZD_DatabaseService.doDelete(new List<SObject>{g});
        Test.stopTest();
        
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'Should be no group');
    }
    
    @isTest
    public static void testDeleteWithZDRecord(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(1, gList.size(), 'should be 1 groups');
        
        Test.startTest();
        ZD_DatabaseService.doDelete(new List<ZD_Record>{new ZD_Record(g)});
        Test.stopTest();
        
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'Should be no group');
    }
    
    @isTest
    public static void testQuery(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(1, gList.size(), 'should be 1 groups');
        
        Test.startTest();
        gList = ZD_DatabaseService.query('SELECT Id FROM Group WHERE Name=\'ZD_DatabaseService Group\'');
        Test.stopTest();
        Assert.areEqual(1, gList.size(), 'Should be 1 group');
    }
    
    @isTest
    public static void testEventPublishSObject(){
        BatchApexErrorEvent evt = new BatchApexErrorEvent();        
        Test.startTest();
        Database.SaveResult[] publishResult = ZD_DatabaseService.eventPublish(new List<SObject>{evt});
        Test.stopTest();
        Assert.areEqual(publishResult.size(), 1, 'Should be one save result');
        Assert.isTrue(publishResult[0].isSuccess(), 'Should be successful');
    }

    @isTest
    public static void testEventPublishZDRecord(){
        BatchApexErrorEvent evt = new BatchApexErrorEvent();        
        Test.startTest();
        Database.SaveResult[] publishResult = ZD_DatabaseService.eventPublish(new List<ZD_Record>{new ZD_Record(evt)});
        Test.stopTest();
        Assert.areEqual(publishResult.size(), 1, 'Should be one save result');
        Assert.isTrue(publishResult[0].isSuccess(), 'Should be successful');
    }
    
    @isTest
    public static void testQueryWithBinds(){
        String gName = 'ZD_DatabaseService Group';
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(1, gList.size(), 'should be 1 groups');
        
        Test.startTest();
        gList = ZD_DatabaseService.queryWithBinds('SELECT Id FROM Group WHERE Name=:gName', 
                                                  new Map<String,Object>{'gName' => gName},
                                                  System.AccessLevel.USER_MODE);
        Test.stopTest();
        Assert.areEqual(1, gList.size(), 'Should be 1 group');
    }
    
    @isTest
    public static void testQueryWithAccessLevel(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(1, gList.size(), 'should be 1 groups');
        
        Test.startTest();
        gList = ZD_DatabaseService.query('SELECT Id FROM Group WHERE Name= \'ZD_DatabaseService Group\'', 
                                                  System.AccessLevel.USER_MODE);
        Test.stopTest();
        Assert.areEqual(1, gList.size(), 'Should be 1 group');
    }
    
    @isTest
    public static void testQueryWithNullAccessLevel(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(1, gList.size(), 'should be 1 groups');
        
        Test.startTest();
        gList = ZD_DatabaseService.query('SELECT Id FROM Group WHERE Name= \'ZD_DatabaseService Group\'', 
                                                  null);
        Test.stopTest();
        Assert.areEqual(1, gList.size(), 'Should be 1 group');
    }
    
    @isTest
    public static void testQueryAsZDRecords(){
        List<Group> gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(0, gList.size(), 'should be no groups');
        Group g = new Group(Name='ZD_DatabaseService Group');
        insert g;
        gList = [SELECT Id FROM Group WHERE Name='ZD_DatabaseService Group'];
        Assert.areEqual(1, gList.size(), 'should be 1 groups');
        
        Test.startTest();
        List<ZD_Record> gListAsZDRecords = ZD_DatabaseService.queryAsZDRecords('SELECT Id FROM Group WHERE Name= \'ZD_DatabaseService Group\'');
        Test.stopTest();
        Assert.areEqual(1, gListAsZDRecords.size(), 'Should be 1 group');
    }
    
    @isTest
    public static void testStubbingQueries(){
        ZD_VirtualCallable dbSvc = (ZD_VirtualCallable) ZD_CallableFactory.getFactory().getCallableInstance('ZD_DatabaseService');
        Group g1 = new Group(Name='ZD_DatabaseService Group1');
        Group g2 = new Group(Name='ZD_DatabaseService Group2');
        ZD_Application.startMocking();
        dbSvc.setReturnValue('query', new Map<String,Object>{'query' => 'queryOne'}, new List<SObject>{g1});
        
        dbSvc.setReturnValue('query', new Map<String,Object>{'query' => 'queryTwo', 'accessLevel' => System.AccessLevel.USER_MODE}, new List<SObject>{g2});
        ZD_Application.stopMocking();
        Test.startTest();
        List<SObject> sObjListQuery1 = ZD_DatabaseService.query('queryOne');
        List<SObject> sObjListQuery2 = ZD_DatabaseService.query('queryTwo');
        List<ZD_Record> zdRecordListQuery2 = ZD_DatabaseService.queryAsZDRecords('queryTwo');
        Test.stopTest();
        Assert.areEqual(1, sObjListQuery1.size(), 'Should be 1 group');
        Assert.areEqual(sObjListQuery1[0].get('Name'), 'ZD_DatabaseService Group1', 'Should be ZD_DatabaseService Group1');
        Assert.areEqual(1, sObjListQuery2.size(), 'Should be 1 group');
        Assert.areEqual(sObjListQuery2[0].get('Name'), 'ZD_DatabaseService Group2', 'Should be ZD_DatabaseService Group2');
        Assert.areEqual(1, zdRecordListQuery2.size(), 'Should be 1 group');
        Assert.areEqual(zdRecordListQuery2[0].get('Name'), 'ZD_DatabaseService Group2', 'Should be ZD_DatabaseService Group2');
    }
}