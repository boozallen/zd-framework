@isTest
/**
 * @description test class for virtual callable
 * This software package is licensed under the Booz Allen Public License. 
 * Copyright © 2023 Booz Allen Hamilton Inc.  All Rights Reserved.
 */
public with sharing class ZD_VirtualCallableTest {
    
    private static String testOutput = '';

    @isTest
    public static void testDoCallWithImpl(){
        ZD_VirtualCallable tvc = new TestVirtualCallable();
        tvc.call('action1', null);
        Assert.areEqual(testOutput, 'Called action1 from TestVirtualCallable', 'wrong action called');
        tvc.call('action2');
        Assert.areEqual(testOutput, 'Called action2 from TestVirtualCallable', 'wrong action called');
        String result = (String) tvc.call('action3');
        Assert.areEqual(result, 'action 3 called', 'action 3 called returned');
    }
    
    @isTest
    public static void testDoCallWithVirtual(){
        ZD_VirtualCallable vc = new ZD_VirtualCallable();
        vc.call('action1', null);
        vc.call('action2');
        Assert.areEqual(vc.invokedMethodsMap.get('action1'),1, 'action1 called once');
        Assert.areEqual(vc.invokedMethodsMap.get('action2'),1, 'action2 called once');
    }

    @isTest
    public static void testDoCallWithImplMockedReturnValue(){
        ZD_VirtualCallable tvc = new TestVirtualCallable();
        ZD_Application.startMocking();
        tvc.setReturnValue('action3', 'Mocked Action 3 default');
        tvc.setReturnValue('action3', new Map<String,Object>{}, 'Mocked Action 3 with args');
        ZD_Application.stopMocking();
        String result1 = (String) tvc.call('action3');
        String result2 = (String) tvc.call('action3', new Map<String,Object>{});
        String result3 = (String) tvc.call('AcTioN3');
        String result4 = (String) tvc.call('AcTioN3', new Map<String,Object>{});
        Assert.areEqual('Mocked Action 3 default', result1, 'Mocked Action 3 default');
        Assert.areEqual('Mocked Action 3 with args', result2, 'Mocked Action 3 with args');
        Assert.areEqual('Mocked Action 3 default', result3, 'Mocked Action 3 default');
        Assert.areEqual('Mocked Action 3 with args', result4, 'Mocked Action 3 with args');
    }
    
    @isTest
    public static void testDoCallWithImplMockedReturnValueDefaultTest(){
        ZD_VirtualCallable tvc = new TestVirtualCallable();
        ZD_Application.startMocking();
        tvc.setReturnValue('action3', 'Mocked Action 3 default');
        ZD_Application.stopMocking();
        String result = (String) tvc.call('action3', new Map<String,Object>{});
        Assert.areEqual('Mocked Action 3 default', result, 'Mocked Action 3 default');
    }
    
    @isTest
    public static void testDoCallWithImplMockedReturnValueOutsideMocking(){
        ZD_VirtualCallable tvc = new TestVirtualCallable();
        try{
            tvc.setReturnValue('action3', 'Mocked Action 3');
            Assert.fail('should go to catch block');
        }catch(ZD_Application.ApplicationException e){
            Assert.isTrue(e.getMessage().contains('This instance is not currently configured to mock, wrap this call in the startMocking and stopMocking methods'), 'wrong error caught');
        }
    }
    
    @isTest
    public static void testDoCallWithImplMockedReturnValueStubInvocable(){
        ZD_VirtualCallable tvc = new TestVirtualCallable();
        ZD_Application.startMocking();
        tvc.setReturnValue('action1', new TestInvocable());
        ZD_Application.stopMocking();
        tvc.call('action1', null);
        Assert.areEqual(testOutput, 'Called action1 from TestInvocable', 'action1 was not called');
        tvc.call('action2');
        Assert.areEqual(testOutput, 'Called action2 from TestVirtualCallable', 'action2 was not called');
        String result = (String) tvc.call('action3');
        Assert.areEqual('action 3 called', result, 'action 3 called returned');
    }

    private class TestVirtualCallable extends ZD_VirtualCallable{
        public override Object doCall(String action, Map<String,Object> args){
            switch on action {
                when 'action1' {
                    testOutput = 'Called action1 from TestVirtualCallable';
                }when 'action2' {
                    testOutput = 'Called action2 from TestVirtualCallable';
                }when 'action3'{
                    return 'action 3 called';
                }
            }
            return null;
        }
    }

    private class TestInvocable extends ZD_Application.StubInvocable{
        public override void handleMethodCall(String action, Map<String,Object> args){
            testOutput = 'Called ' + action + ' from TestInvocable';
        }
    }
}