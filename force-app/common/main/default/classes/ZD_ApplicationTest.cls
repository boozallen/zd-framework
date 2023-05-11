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

    @isTest
    public static void testMockableWhenNotMocking(){
        TestMockable t = new TestMockable();
        try{
            t.when('test');
            Assert.fail('should not be able to call when outside of mocking block');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('This instance is not currently configured to mock, wrap this call in the startMocking and stopMocking methods'), 'Message is wrong exception');
        } 
    }

    @isTest
    public static void testMockableWithNotMocking(){
        TestMockable t = new TestMockable();
        t.methodToMock = 'test';
        try{
            t.with(new Map<String,Object>());
            Assert.fail('should not be able to call when outside of mocking block');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('This instance is not currently configured to mock, wrap this call in the startMocking and stopMocking methods'), 'Message is wrong exception');
        } 
    }

    @isTest
    public static void testMockableWhenMocking(){
        TestMockable t = new TestMockable();
        ZD_Application.startMocking();
        t.when('test');
        Assert.areEqual(t.methodToMock, 'test', 'method should be test');
        t.when('test1').when('test2');
        Assert.areEqual(t.methodToMock, 'test2', 'method should be test2');
        ZD_Application.stopMocking();
    }

    @isTest
    public static void testMockableWithMocking(){
        TestMockable t = new TestMockable();
        ZD_Application.startMocking();
        try{
            t.with(new Map<String,Object>{'key' => 'val'});
            Assert.fail('shouldnt succeed');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('cannot mock a null method'), 'Message is wrong exception');
        }
        t.when('test').with(new Map<String,Object>{'key' => 'val'});
        Assert.areEqual(t.methodToMock, 'test', 'method should be test');
        Assert.areEqual(t.argsForMethodToMock?.get('key'), 'val', 'should be val');
        t.when('test2').with(new Map<String,Object>{'key' => 'val1'}).with(new Map<String,Object>{'key' => 'val2'});
        Assert.areEqual(t.argsForMethodToMock?.get('key'), 'val2', 'should be val2');
        ZD_Application.stopMocking();
    }

    @isTest
    public static void testMockableThenMocking(){
        TestMockable t = new TestMockable();
        TestInvocable ti = new TestInvocable();
        TestException te = new TestException('error');
        ZD_Application.startMocking();
        t.when('testReturn').thenReturn('value');
        Assert.isNull(t.methodToMock, 'method to mock returns to null after then statement');
        t.when('testInvocable').thenExecute(ti);
        Assert.isNull(t.methodToMock, 'method to mock returns to null after then statement');
        t.when('testException').thenThrowException(te);
        Assert.isNull(t.methodToMock, 'method to mock returns to null after then statement');
        ZD_Application.stopMocking();
        Assert.areEqual('value', t.getReturnValues().get('testreturn'), 'method return value should be value');
        Assert.areEqual(ti.toString(), t.getReturnValues().get('testinvocable').toString(), 'method return value should be the ti variable');
        Assert.areEqual(String.valueOf(te), String.valueOf(t.getReturnValues().get('testexception')), 'method return value should be the te variable');
    }

    @isTest
    public static void testMockableThenNotMockingNoMethod(){
        TestMockable t = new TestMockable();
        
        try{
            t.thenReturn(null);
            Assert.fail('should fail with null method');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('cannot mock a null method'), 'Message is wrong exception');
        } 
        try{
            t.thenExecute(null);
            Assert.fail('should fail with null method');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('cannot mock a null method'), 'Message is wrong exception');
        } 
        try{
            t.thenThrowException(null);
            Assert.fail('should fail with null method');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('cannot mock a null method'), 'Message is wrong exception');
        }
    }

    @isTest
    public static void testMockableThenNotMocking(){
        TestMockable t = new TestMockable();
        t.methodToMock = 'test';
        
        try{
            t.thenReturn(null);
            Assert.fail('should not be able to call when outside of mocking block');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('This instance is not currently configured to mock, wrap this call in the startMocking and stopMocking methods'), 'Message is wrong exception');
        } 
        try{
            t.thenExecute(null);
            Assert.fail('should not be able to call when outside of mocking block');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('This instance is not currently configured to mock, wrap this call in the startMocking and stopMocking methods'), 'Message is wrong exception');
        } 
        try{
            t.thenThrowException(null);
            Assert.fail('should not be able to call when outside of mocking block');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('This instance is not currently configured to mock, wrap this call in the startMocking and stopMocking methods'), 'Message is wrong exception');
        }
    }

    class TestInvocable extends ZD_Application.StubInvocable{
        
        public override void handleMethodCall(String action, Map<String,Object> args){
            invocableCallCount++;
        }
    }
    
    class TestMockable extends ZD_Application.Mockable{
        @TestVisible 
        private Map<String,Object> getReturnValues(){
            return this.returnValues;
        }
    }

    class TestException extends Exception{}
}