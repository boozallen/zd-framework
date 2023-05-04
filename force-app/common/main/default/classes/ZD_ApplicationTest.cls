/**
 * @description test for ZD_Application
 * This software package is licensed under the Booz Allen Public License. 
 * Copyright © 2023 Booz Allen Hamilton Inc.  All Rights Reserved. 
 * 
 * @author Jonathan Devlin
 */
@isTest
public without sharing class ZD_ApplicationTest {
    
    static Integer invocableCallCount = 0;
    
    @isTest
    public static void testStartMocking(){
        ZD_Application.startMocking();
        try{
            ZD_Application.startMocking();
            Assert.fail('Should not successfully call startMocking');
        }catch(ZD_Application.ApplicationException ex){
            Assert.isTrue(ex.getMessage().contains('Start mocking can only be called once'), 'unexpected error message');
        }
		
    }
    
    @isTest
    public static void testStopMocking(){
        
        try{
            ZD_Application.stopMocking();
            Assert.fail('Should not successfullt call stop mocking here');
        }catch(ZD_Application.ApplicationException ex){
            Assert.isTrue(ex.getMessage().contains('stopMocking must be called after startMocking'), 'unexpected error message');
        }
        ZD_Application.startMocking();
        ZD_Application.stopMocking();
		
    }
    
    @isTest
    public static void testSetReturnValueOutsideOfMock(){
        TestMockable t = new TestMockable();
        try{
            t.setReturnValue('test', null);
            Assert.fail('should not be able to call set return value here');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('This instance is not currently configured to mock, wrap this call in the startMocking and stopMocking methods'), 'Message is wrong exception');
        }
    }
    
    @isTest
    public static void testSetReturnValueInsideMockWithNullArgs(){
        TestMockable t = new TestMockable();
        ZD_Application.startMocking();
        t.setReturnValue('test', null);
        ZD_Application.stopMocking();
        Assert.isTrue(t.getReturnValues().containsKey('test'), 'test return value is set');
    }
    
    @isTest
    public static void testSetReturnValueWithNonNullArgs(){
        TestMockable t = new TestMockable();
        ZD_Application.startMocking();
        t.setReturnValue('test', new Map<String,Object>{'param1' => 'value1'}, 'hello world!');
        ZD_Application.stopMocking();
        Assert.isTrue(t.getReturnValues().containsKey('test;' + String.valueOf(new Map<String,Object>{'param1' => 'value1'}) ), 'test return value is set');
        Assert.areEqual(t.getReturnValues().get('test;' + String.valueOf(new Map<String,Object>{'param1' => 'value1'})), 'hello world!', 'test return value is hello world!');
    }
    
    @isTest
    public static void testUtilMethods(){
       	Assert.areEqual('0To000000000000001' , ZD_Application.util.getFakeId('0To'), 'should be the first record');
		Assert.areEqual('0T2000000000000002' , ZD_Application.util.getFakeId('0T2'), 'should be the second record');
        Assert.areEqual('0T2000000000000003' , ZD_Application.util.getFakeId('0T2'), 'should be the third record');
    }
    
    @isTest
    public static void testStubInvocableWhenisNotRunningTest(){
        ZD_Application.isRunningTest = false;
        Assert.areEqual(0, invocableCallCount, 'invocable call count should be zero');
        try{
            new ZD_Application.StubInvocable().call('test', null);
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('StubInvocable class can only be called in Test context'), 'Wrong error message');
        }
        Assert.areEqual(0, invocableCallCount, 'invocable call count should still be zero');
    }
    
    @isTest
    public static void testStubInvocableWhenisRunningTest(){
        Assert.areEqual(0, invocableCallCount, 'invocable call count should be zero');
       	new TestInvocable().call('test', null);
        Assert.areEqual(1, invocableCallCount, 'invocable call count should be 1');
        new ZD_Application.StubInvocable().call('test', null);
        Assert.areEqual(1, invocableCallCount, 'invocable call count should be 1');
    }

    class TestInvocable extends ZD_Application.StubInvocable{
        
        public override void handleMethodCall(String action, Map<String,Object> args){
            invocableCallCount++;
        }
    }
    
    class TestMockable extends ZD_Application.Mockable{
        @TestVisible private Map<String,Object> getReturnValues(){
            return this.returnValues;
        }
    }
}