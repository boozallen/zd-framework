/**
 * @description class for Application Mocking
 * This software package is licensed under the Booz Allen Public License. 
 * Copyright © 2023 Booz Allen Hamilton Inc.  All Rights Reserved.
 */
public inherited sharing class ZD_Application {
    
    private static boolean isSettingMockValues;
    @TestVisible private static boolean isRunningTest = Test.isRunningTest();

    /**
     * @description util instance for accessing the utility methods
     */
    public static Utils util{
        get{
            if(util == null){
                util = new Utils();
            }
            return util;
        }
        private set;
    }

    /**
     * @description starts mocking for a test. similiar to Test.startTest()
     */
    @TestVisible
    private static void startMocking(){
        if(isSettingMockValues != null){
            throw new ApplicationException('Start mocking can only be called once');
        }
        isSettingMockValues = true;
    }

    /**
     * @description stops the mocking section. Similar to Test.stopTest()
     */
    @TestVisible
    private static void stopMocking(){
        if(isSettingMockValues != true){
            throw new ApplicationException('stopMocking must be called after startMocking');
        }
        isSettingMockValues = false;
    }

    /**
     * @description abstract class for enabling mocking. 
     */
    public abstract inherited sharing class Mockable{
        protected Map<String,Object> returnValues = new Map<String,Object>();
        @TestVisible protected Map<String, Integer> invokedMethodsMap = new Map<String, Integer>();
        
        protected boolean isMocked = false;

        /**
         * @description sets a return value at a particular method for mocking
         * @param methodName - method to mock
         * @param returnValue - value to return when that method is called
         */
        @TestVisible
        protected void setReturnValue(String methodName, Object returnValue){
            setReturnValue(methodName, null, returnValue);
        }

        /**
         * @description sets a return value at a particular method for mocking
         * @param methodName - method to mock
         * @param args - arguments associated with that method
         * @param returnValue - value to return when that method is called
         */
        @TestVisible
        protected virtual void setReturnValue(String methodName, Map<String,Object> args, Object returnValue){
            if(isSettingMockValues != true){
                throw new ApplicationException('This instance is not currently configured to mock, wrap this call in the startMocking and stopMocking methods');
            }
            returnValues.put(ZD_Application.util.serializeMethodCall(methodName, args), returnValue);
        }
    }

    /**
     * @description special class for mocking void methods
     */
    public virtual inherited sharing class StubInvocable implements System.Callable{
       
        /**
         * @description executes action with args via handleMethodCall
         * @param action - method to run
         * @param args - arguments for that method
         * @return - null always, this is for void methods. must return null to be a callable
         */
        public Object call(String action, Map<String,Object> args){
            if(!isRunningTest){
                throw new ApplicationException('StubInvocable class can only be called in Test context');
            }
            handleMethodCall(action,args);
            return null;
        }

        /**
         * @description executes action with args, allows injecting apex into virtual callables
         * @param action - method to run
         * @param args - arguments for that method
         */
        public virtual void handleMethodCall(String action, Map<String,Object> args){return;}
    }

    /**
     * @description utility methods for mocking
     */
    public without sharing class Utils{
        @TestVisible Integer numRecords = 1;

        /**
         * @description utility methods for mocking
         * @param prefix - object prefix
         * @return - mocked id for testing
         */
        @TestVisible 
        private String getFakeId(String prefix){
            String result = String.valueOf(numRecords++);
            return prefix + 
                '0'.repeat(15-result.length()) + result;
        }

        /**
         * @description converts a method - argument map combo into a string
         * @param methodName - method to call
         * @param args - arguments for that method
         * @return - String representing the method and args 
         */
        public String serializeMethodCall(String methodName, Map<String,Object> args) {
            methodName = methodName?.toLowerCase();
            if(args?.keySet() == null){
                return methodName;
            }
            return methodName + ';' + String.valueOf(args);
        }
    }

    /**
     * @description Exception class for this class
     */
    public without sharing class ApplicationException extends Exception{}
}