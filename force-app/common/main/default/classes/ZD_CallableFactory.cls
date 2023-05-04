/**
 * @description class for handling all callable instance creation/caching
 * This software package is licensed under the Booz Allen Public License. 
 * Copyright © 2023 Booz Allen Hamilton Inc.  All Rights Reserved.
 * 
 * @author Jonathan Devlin
 */
public inherited sharing class ZD_CallableFactory {
    
    @TestVisible private static ZD_CallableFactory factory;
    @TestVisible private Map<String, Callable> callableInstanceMap;
    @TestVisible private static Boolean allowNullInstances = false;
    
    //instantiation only happens via getFactory()
    @TestVisible 
    private ZD_CallableFactory(){
        this.callableInstanceMap = new Map<String, Callable>();
    }

    /**
     * @description set the factory, allows crossing contexts
     * @param instance - factory instance to pass around
     */
    public static void setFactory(ZD_CallableFactory instance){
        factory = instance;
    }

    /**
     * @description returns the factory instance for this transaction
     * @return ZD_CallableFactory instance
     */
    public static ZD_CallableFactory getFactory(){
        if(factory == null){
            factory = new ZD_CallableFactory();
        }
        return factory;
    }

    /**
     * @description instantiates and/or returns the desired callable instance through dynamic 
     * type instantiation
     * @param className - the instance to get or create
     * @return Callable instance stored at the className key
     */
    public Callable getCallableInstance(String className){
        if(!callableInstanceMap.containsKey(className)){
            Callable newInstance = (Callable) Type.forName(className)?.newInstance();
            if(!allowNullInstances && newInstance == null){
                throw new ZD_Application.ApplicationException('The class ' + className + ' does not exist in the org.');
            }
            callableInstanceMap.put(className, newInstance);
        }
        return callableInstanceMap.get(className);
    }

}