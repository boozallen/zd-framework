public with sharing class ZD_Record {
    
    Map<String,Object> fields;
    SObject sObj;
    @TestVisible private static boolean allowNullSObjects = Test.isRunningTest();
    private String objectAPIName;

    public Id Id{
        get{
            return (Id) this.get('Id');
        }
        set{
            this.put('Id', value);
        }
    }

    public class ZD_RecordException extends Exception{}

    public ZD_Record(String objectAPIName) {
        if(!allowNullSObjects){
            throw new ZD_RecordException('String constructor for ZD_Record class is for Test classes only.');
        }
        fields = new Map<String,Object>();
        this.objectAPIName = objectAPIName;
    }

    public ZD_Record(SObject sObj) {
        if(sObj == null && !allowNullSObjects){
            throw new ZD_RecordException('Cannot pass null into the ZD_Record class.');
        }
        else if(sObj == null){
            fields = new Map<String,Object>();
        }else{
            this.sObj = sObj;
        }
        
    }

    public Object get(String key){
        return sObj != null ? sObj.get(key) : fields.get(key);
    }

    public void put(String key, Object value){
        if(sObj != null){
            sObj.put(key, value);
        }else{
            fields.put(key, value);
        }
    }

    public void putSObject(String key, Object value){
        if(sObj != null){
            sObj.putSObject(key, (SObject) value);
        }else{
            fields.put(key, value);
        }
    }

    public ZD_Record getSObject(String key){
        return sObj != null ? new ZD_Record(sObj.getSObject(key)) : (ZD_Record) fields.get(key);
    }

    public List<ZD_Record> getSObjects(String key){
        if(sObj == null){
            return (List<ZD_Record>) fields.get(key);
        }
        List<ZD_Record> records = new List<ZD_Record>();
        for(SObject child : sObj.getSObjects(key)){
            records.add(new ZD_Record(child));
        }
        return records;
    }

    public String getObjectAPIName(){
        return sObj != null ? sObj.getSObjectType().getDescribe().getName() : this.objectAPIName;
    }

    public SObject sObject(){
        return sObj;
    }

    public static List<SObject> toSObjects(List<ZD_Record> recordsList){
        List<SObject> sObjs = new List<SObject>();
        for(ZD_Record rec : recordsList){
            sObjs.add(rec.sObject());
        }
        return sObjs;
    }

    public static List<ZD_Record> toRecords(List<SObject> sObjs){
        List<ZD_Record> records = new List<ZD_Record>();
        for(SObject sObj : sObjs){
            records.add(new ZD_Record(sObj));
        }
        return records;
    }

    public static Map<Id, ZD_Record> toRecordsMap(List<SObject> sObjs){
        Map<Id, ZD_Record> records = new Map<Id, ZD_Record>();
        for(SObject sObj : sObjs){
            records.put(sObj.Id, new ZD_Record(sObj));
        }
        return records;
    }

    public static Map<Id, ZD_Record> toRecordsMap(List<ZD_Record> records){
        Map<Id, ZD_Record> recordsMap = new Map<Id, ZD_Record>();
        for(ZD_Record record : records){
            recordsMap.put(record.Id, record);
        }
        return recordsMap;
    }
}