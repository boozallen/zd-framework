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

    public static Database.SaveResult[] doInsert(Object records){
        return (Database.SaveResult[]) dbService.call('insert', new Map<String,Object>{'records' => records});
    }

    public static Database.SaveResult[] eventPublish(Object records){
        return (Database.SaveResult[]) dbService.call('eventpublish', new Map<String,Object>{'records' => records});
    }

    public static Database.SaveResult[] doUpdate(Object records){
        return (Database.SaveResult[]) dbService.call('update', new Map<String,Object>{'records' => records});
    }

    public static Database.UpsertResult[] doUpsert(Object records){
        return (Database.UpsertResult[]) dbService.call('upsert', new Map<String,Object>{'records' => records});
    }

    public static Database.DeleteResult[] doDelete(Object records){
        return (Database.DeleteResult[]) dbService.call('delete', new Map<String,Object>{'records' => records});
    }

    @AuraEnabled
    public static List<SObject> query(String query){
        return query(query, System.accessLevel.USER_MODE);
    }

    public static List<SObject> query(String query, System.AccessLevel accessLevel){
        return (List<SObject>) dbService.call('query', new Map<String,Object>{'query' => query, 'accessLevel' => accessLevel});
    }

    public static List<ZD_Record> queryAsZDRecords(String query){
        return queryAsZDRecords(query, System.AccessLevel.USER_MODE);
    }

    public static List<ZD_Record> queryAsZDRecords(String query, System.AccessLevel accessLevel){
        return (List<ZD_Record> ) dbService.call('queryaszdrecords', new Map<String,Object>{'query' => query, 'accessLevel' => accessLevel});
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> queryWithBinds(String query, Map<String, Object> bindMap, System.AccessLevel accessLevel){
        return (List<SObject>) dbService.call('querywithbinds', new Map<String,Object>{'query' => query,
                                                                              'bindMap' => bindMap,
                                                                              'accessLevel' => accessLevel});
    }

    @AuraEnabled(cacheable=true)
    public static void setAccessLevel(System.AccessLevel accessLevel){
        dbService.call('setaccesslevel', new Map<String,Object>{'accessLevel' => accessLevel});
    }

    
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
                System.AccessLevel accessLevel = (System.AccessLevel) args.get('accessLevel');
                this.accessLevel = accessLevel;
            }
            
        }
        return null;
    }

    @TestVisible
    protected override void setReturnValue(String methodName, Map<String,Object> args, Object returnValue){
        if(methodName?.startsWith('query') == true && !(args?.containsKey('accessLevel') != false)){
            args.put('accessLevel', System.AccessLevel.USER_MODE);
        }
        super.setReturnValue(methodName, args, returnValue);
    }
}