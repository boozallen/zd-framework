/**
 * @description test for callable factory
 * This software package is licensed under the Booz Allen Public License. 
 * Copyright © 2023 Booz Allen Hamilton Inc.  All Rights Reserved. 
 * 
 * @author Jonathan Devlin
 */
@isTest
public without sharing class ZD_CallableFactoryTest {
    
    @isTest
    public static void testGetFactory(){
        Assert.areEqual(null, ZD_CallableFactory.factory, 'Factory should be null right now');
        ZD_CallableFactory factory = ZD_CallableFactory.getFactory();
        Assert.areEqual(factory, ZD_CallableFactory.factory, 'Factory should exist');
    }
    
    @isTest
    public static void testSetFactory(){
        ZD_CallableFactory passedInFactory = new ZD_CallableFactory();
        Assert.areEqual(null, ZD_CallableFactory.factory, 'Factory should be null right now');
        ZD_CallableFactory.setFactory(passedInFactory);
        Assert.areEqual(passedInFactory, ZD_CallableFactory.factory, 'Factory should be passedInFactory now');
    }
    
    @isTest
    public static void testGetCallableInstance(){
        Callable c = ZD_CallableFactory.getFactory().getCallableInstance('ZD_VirtualCallable');
        Assert.isTrue(c instanceof ZD_VirtualCallable, 'factory should return a ZD_VirtualCallable');
        Assert.isTrue(c == ZD_CallableFactory.getFactory().getCallableInstance('ZD_VirtualCallable'), 'should be returning the same instance');
    }
    
    @isTest
    public static void testGetCallableInstanceWithnullClass(){
        try{
            ZD_CallableFactory.getFactory().getCallableInstance('!!BADCLASSNAME!!');
            Assert.fail('Should get an error when the class does not exist in the org');
        }catch(ZD_Application.ApplicationException ex){
            Assert.isTrue(ex.getMessage().contains('The class !!BADCLASSNAME!! does not exist in the org.'), 'error message should be The class !!BADCLASSNAME!! does not exist in the org.');
        }
    }
    
    @isTest
    public static void testGetCallableInstanceWithNullClassWithAllowNulls(){
        ZD_CallableFactory.allowNullInstances = true;
        Callable c = ZD_CallableFactory.getFactory().getCallableInstance('!!BADCLASSNAME!!');
        Assert.isNull(c, 'factory should return null');
    }

}