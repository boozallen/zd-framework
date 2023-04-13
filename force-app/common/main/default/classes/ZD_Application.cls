public inherited sharing class ZD_Application {
    
    private static boolean isSettingMockValues;
    @TestVisible private static boolean isRunningTest = Test.isRunningTest();

    public static Utils util{
        get{
            if(util == null){
                util = new Utils();
            }
            return util;
        }
        private set;
    }

    @TestVisible
    private static void startMocking(){
        if(isSettingMockValues != null){
            throw new ApplicationException('Start mocking can only be called once');
        }
        isSettingMockValues = true;
    }

    @TestVisible
    private static void stopMocking(){
        if(isSettingMockValues != true){
            throw new ApplicationException('stopMocking must be called after startMocking');
        }
        isSettingMockValues = false;
    }

    public abstract inherited sharing class Mockable{
        protected Map<String,Object> returnValues = new Map<String,Object>();
        @TestVisible protected Map<String, Integer> invokedMethodsMap = new Map<String, Integer>();
        
        protected boolean isMocked = false;

        @TestVisible
        protected void setReturnValue(String methodName, Object returnValue){
            setReturnValue(methodName, null, returnValue);
        }

        @TestVisible
        protected virtual void setReturnValue(String methodName, Map<String,Object> args, Object returnValue){
            if(isSettingMockValues != true){
                throw new ApplicationException('This instance is not currently configured to mock, wrap this call in the startMocking and stopMocking methods');
            }
            returnValues.put(ZD_Application.util.serializeMethodCall(methodName, args), returnValue);
        }
    }

    public virtual inherited sharing class StubInvocable implements System.Callable{
        public Object call(String action, Map<String,Object> args){
            if(!isRunningTest){
                throw new ApplicationException('StubInvocable class can only be called in Test context');
            }
            handleMethodCall(action,args);
            return null;
        }

        public virtual void handleMethodCall(String action, Map<String,Object> args){}
    }

    public without sharing class Utils{
        @TestVisible Integer s_num = 1;

        @TestVisible 
        private String getFakeId(String prefix){
            String result = String.valueOf(s_num++);
            return prefix + 
                '0'.repeat(15-result.length()) + result;
        }

        public String serializeMethodCall(String methodName, Map<String,Object> args) {
            methodName = methodName?.toLowerCase();
            if(args?.keySet() == null){
                return methodName;
            }
            return methodName + ';' + String.valueOf(args);
        }
    }

    public without sharing class ApplicationException extends Exception{}
}