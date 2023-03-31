@isTest
public without sharing class ZD_ApplicationTest {
    
    static Integer invocableCallCount = 0;
    
    @isTest
    public static void testStartMocking(){
        ZD_Application.startMocking();
        try{
            ZD_Application.startMocking();
            Assert.fail();
        }catch(ZD_Application.ApplicationException ex){
            Assert.isTrue(ex.getMessage().contains('Start mocking can only be called once'), 'unexpected error message');
        }
		
    }
    
    @isTest
    public static void testStopMocking(){
        
        try{
            ZD_Application.stopMocking();
            Assert.fail();
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
            Assert.fail();
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('This instance is not currently configured to mock, wrap this call in the startMocking and stopMocking methods'));
        }
    }
    
    @isTest
    public static void testSetReturnValueInsideMock_NullArgs(){
        TestMockable t = new TestMockable();
        ZD_Application.startMocking();
        t.setReturnValue('test', null);
        ZD_Application.stopMocking();
        Assert.isTrue(t.getReturnValues().containsKey('test'), 'test return value is set');
    }
    
    @isTest
    public static void testSetReturnValue_NonNullArgs(){
        TestMockable t = new TestMockable();
        ZD_Application.startMocking();
        t.setReturnValue('test', new Map<String,Object>{'param1' => 'value1'}, 'hello world!');
        ZD_Application.stopMocking();
        Assert.isTrue(t.getReturnValues().containsKey('test;' + String.valueOf(new Map<String,Object>{'param1' => 'value1'}) ), 'test return value is set');
        Assert.areEqual(t.getReturnValues().get('test;' + String.valueOf(new Map<String,Object>{'param1' => 'value1'})), 'hello world!', 'test return value is hello world!');
    }
    
    @isTest
    public static void testUtilMethods(){
       	Assert.areEqual('0To000000000000001' , ZD_Application.util.getFakeId('0To'));
		Assert.areEqual('0T2000000000000002' , ZD_Application.util.getFakeId('0T2'));
        Assert.areEqual('0T2000000000000003' , ZD_Application.util.getFakeId('0T2'));
    }
    
    @isTest
    public static void testStubInvocable_isNotRunningTest(){
        ZD_Application.isRunningTest = false;
        Assert.areEqual(0, invocableCallCount);
        try{
            new ZD_Application.StubInvocable().call('test', null);
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('StubInvocable class can only be called in Test context'));
        }
        Assert.areEqual(0, invocableCallCount);
    }
    
    @isTest
    public static void testStubInvocable_isRunningTest(){
        Assert.areEqual(0, invocableCallCount);
       	new TestInvocable().call('test', null);
        Assert.areEqual(1, invocableCallCount);
        new ZD_Application.StubInvocable().call('test', null);
        Assert.areEqual(1, invocableCallCount);
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