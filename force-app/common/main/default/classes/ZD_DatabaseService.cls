/**
 * @description class for handling database operations
 * This software package is licensed under the Booz Allen Public License. 
 * Copyright © 2023 Booz Allen Hamilton Inc.  All Rights Reserved.
 */
public inherited sharing virtual class ZD_DatabaseService extends ZD_VirtualCallable{

    @TestVisible private System.AccessLevel accessLevel = System.AccessLevel.USER_MODE;

    @TestVisible private static Callable dbService{
        get{
            if(dbService == null){
                dbService = ZD_CallableFactory.getFactory().getCallableInstance('ZD_DatabaseService');
            }
            return dbService;
        }
        private set;
    }

    /**
     * @description utility static method that puts the insert call in a more readable format
     * @param records - list of records to insert, could be zd_record or sobject instances
     * @return SaveResult[] indicating the success/failure
     */
    public static Database.SaveResult[] doInsert(Object records){
        return (Database.SaveResult[]) dbService.call('insert', new Map<String,Object>{'records' => records});
    }

    /**
     * @description utility static method that puts the event publish call in a more readable format
     * @param records - list of records to insert, could be zd_record or sobject instances
     * @return SaveResult[] indicating the success/failure
     */
    public static Database.SaveResult[] eventPublish(Object records){
        return (Database.SaveResult[]) dbService.call('eventpublish', new Map<String,Object>{'records' => records});
    }

    /**
     * @description utility static method that puts the update call in a more readable format
     * @param records - list of records to insert, could be zd_record or sobject instances
     * @return SaveResult[] indicating the success/failure
     */
    public static Database.SaveResult[] doUpdate(Object records){
        return (Database.SaveResult[]) dbService.call('update', new Map<String,Object>{'records' => records});
    }

    /**
     * @description utility static method that puts the upsert call in a more readable format
     * @param records - list of records to insert, could be zd_record or sobject instances
     * @return UpsertResult[] indicating the success/failure
     */
    public static Database.UpsertResult[] doUpsert(Object records){
        return (Database.UpsertResult[]) dbService.call('upsert', new Map<String,Object>{'records' => records});
    }

    /**
     * @description utility static method that puts the delete call in a more readable format
     * @param records - list of records to insert, could be zd_record or sobject instances
     * @return DeleteResult[] indicating the success/failure
     */
    public static Database.DeleteResult[] doDelete(Object records){
        return (Database.DeleteResult[]) dbService.call('delete', new Map<String,Object>{'records' => records});
    }

    /**
     * @description utility static method that puts the query call in a more readable format, defaults to usermode
     * @param query - query to execute
     * @return List<SObject> the query returns
     */
    @AuraEnabled
    public static List<SObject> query(String query){
        return query(query, System.accessLevel.USER_MODE);
    }

    /**
     * @description utility static method that puts the query call in a more readable format
     * @param query - query to execute
     * @param accessLevel - level of access for the query
     * @return List<SObject> the query returns
     */
    public static List<SObject> query(String query, System.AccessLevel accessLevel){
        return (List<SObject>) dbService.call('query', new Map<String,Object>{'query' => query, 'accessLevel' => accessLevel});
    }

    /**
     * @description utility static method that puts the query call in a more readable format as a list of ZD records in user mode
     * @param query - query to execute
     * @return List<ZD_Record> the query returns
     */
    public static List<ZD_Record> queryAsZDRecords(String query){
        return queryAsZDRecords(query, System.AccessLevel.USER_MODE);
    }

    /**
     * @description utility static method that puts the query call in a more readable format as a list of ZD records
     * @param query - query to execute
     * @param accessLevel - level of access for the query
     * @return List<ZD_Record> the query returns
     */
    public static List<ZD_Record> queryAsZDRecords(String query, System.AccessLevel accessLevel){
        return (List<ZD_Record> ) dbService.call('queryaszdrecords', new Map<String,Object>{'query' => query, 'accessLevel' => accessLevel});
    }

    /**
     * @description utility static method that puts the queryWithBinds call in a more readable format
     * @param query - query to execute
     * @param bindMap - map of values to replace in the query
     * @param accessLevel - level of access for the query
     * @return List<ZD_Record> the query returns
     */
    public static List<SObject> queryWithBinds(String query, Map<String, Object> bindMap, System.AccessLevel accessLevel){
        return (List<SObject>) dbService.call('querywithbinds', new Map<String,Object>{'query' => query,
                                                                              'bindMap' => bindMap,
                                                                              'accessLevel' => accessLevel});
    }

    /**
     * @description utility static method that puts the setAccessLevel call in a more readable format
     * @param accessLevel - level of access for the transaction
     */
    public static void setAccessLevel(System.AccessLevel accessLevel){
        dbService.call('setaccesslevel', new Map<String,Object>{'accessLevel' => accessLevel});
    }

    /**
     * @description override of the doCall method, handles the method routing based off the action
     * @param action - method to run
     * @param args - arguments for the method
     * @return - null if a void method, returns whatever the routed method returns if not void
     */
    @SuppressWarnings('PMD.NcssMethodCount')
    public override Object doCall(String action, Map<String,Object> args){
        switch on action {
            when 'insert' {
                List<SObject> records = args.get('records') instanceof List<ZD_Record> 
                                    ? ZD_Record.toSObjects((List<ZD_Record>)args.get('records'))
                                    : (List<SObject>)args.get('records');
                return Database.insert(records, this.accessLevel);
            }
            when 'update' {
                List<SObject> records = args.get('records') instanceof List<ZD_Record> 
                                    ? ZD_Record.toSObjects((List<ZD_Record>)args.get('records'))
                                    : (List<SObject>)args.get('records');
                return Database.update(records, this.accessLevel);
            }
            when 'upsert' {
                List<SObject> records = args.get('records') instanceof List<ZD_Record> 
                                    ? ZD_Record.toSObjects((List<ZD_Record>)args.get('records'))
                                    : (List<SObject>)args.get('records');
                return Database.upsert(records, this.accessLevel);
            }
            when 'delete' {
                List<SObject> records = args.get('records') instanceof List<ZD_Record> 
                                    ? ZD_Record.toSObjects((List<ZD_Record>)args.get('records'))
                                    : (List<SObject>)args.get('records');
                return Database.delete(records, this.accessLevel);
            }
            when 'query' {
                String query = String.valueOf(args.get('query'));
                System.AccessLevel accessLevel = args.get('accessLevel') != null
                                                ? (System.AccessLevel) args.get('accessLevel')
                                                : this.accessLevel;
                List<SObject> sObjList = Database.query(query, accessLevel);
                return sObjList;
            }
            when 'queryaszdrecords'{
                List<SObject> sObjs = (List<SObject>) this.call('query', args);
                return ZD_Record.toRecords(sObjs);
            }
            when 'querywithbinds' {
                String query = String.valueOf(args.get('query'));
                Map<String, Object> bindMap = (Map<String, Object>) args.get('bindMap');
                System.AccessLevel accessLevel = (System.AccessLevel) args.get('accessLevel');
                return Database.queryWithBinds(query, bindMap, accessLevel);
            }
            when 'eventpublish' {
                List<SObject> records = args.get('records') instanceof List<ZD_Record> 
                                    ? ZD_Record.toSObjects((List<ZD_Record>)args.get('records'))
                                    : (List<SObject>)args.get('records');
                return EventBus.publish(records);
            }when 'setaccesslevel' {
                this.accessLevel = (System.AccessLevel) args.get('accessLevel');
            }
            
        }
        return null;
    }

    /**
     * @description special override of the return value, it adds an access level to the return value
     * if none is provided
     * @param methodName - method to mock
     * @param args - arguments for the method
     * @param returnValue - returnValue when a method is called
     */
    @TestVisible
    protected override void setReturnValue(String methodName, Map<String,Object> args, Object returnValue){
        if(methodName?.startsWith('query') == true && !(args?.containsKey('accessLevel') != false)){
            args.put('accessLevel', System.AccessLevel.USER_MODE);
        }
        super.setReturnValue(methodName, args, returnValue);
    }
}