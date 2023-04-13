public inherited sharing virtual class ZD_VirtualCallable extends ZD_Application.Mockable implements System.Callable{
    
    public virtual Object doCall(String action, Map<String,Object> args){return null;}
    @TestVisible protected boolean isSpyingEnabled = Test.isRunningTest();

    public Object call(String action){
        return this.call(action, null);
    }

    public Object call(String action, Map<String,Object> args){
        action = action.toLowerCase();
        if(this.isSpyingEnabled){
            if(!this.invokedMethodsMap.containsKey(action)){
                this.invokedMethodsMap.put(action, 0);
            }
            this.invokedMethodsMap.put(action, (this.invokedMethodsMap.get(action) + 1));
        }
        if(this.containsReturnValue(action,args)){
            if(this.getReturnValue(action,args) instanceof ZD_Application.StubInvocable){
                return ((Callable) this.getReturnValue(action,args)).call(action,args);
            }
            return this.getReturnValue(action,args);
        }
        return doCall(action, args);
    }
    
    @TestVisible
    private boolean containsReturnValue(String action, Map<String,Object> args){
        return returnValues.containsKey(action) || returnValues.containsKey(ZD_Application.util.serializeMethodCall(action,args));
    }
    
    private Object getReturnValue(String action, Map<String,Object> args){
        if(returnValues.containsKey(ZD_Application.util.serializeMethodCall(action,args))){
            return returnValues.get(ZD_Application.util.serializeMethodCall(action,args));
        }
        //return the default
		return returnValues.get(action);
    }
}