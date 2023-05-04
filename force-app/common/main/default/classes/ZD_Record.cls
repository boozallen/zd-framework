/**
 * @description Domain class for handling interactions with a single record
 * This software package is licensed under the Booz Allen Public License. 
 * Copyright © 2023 Booz Allen Hamilton Inc.  All Rights Reserved.
 * 
 * @author Jonathan Devlin
 */
@SuppressWarnings('PMD.PropertyNamingConventions, PMD.VariableNamingConventions')
public with sharing class ZD_Record {
    
    @TestVisible private Map<String,Object> fields;
    @TestVisible private SObject sObj;
    @TestVisible private static Boolean allowNullSObjects = Test.isRunningTest();
    private String objectAPIName;

     /**
     * @description salesforce id of the record
     */
    public Id Id{
        get{
            return (Id) this.get('Id');
        }
        set{
            this.put('Id', value);
        }
    }

    /**
     * @description exception class
     */
    public class ZD_RecordException extends Exception{}

    /**
     * @description constructor with the name of the object, used for unit tests
     * @param objectAPIName - name of the object to instantiate
     */
    @TestVisible 
    private ZD_Record(String objectAPIName) {
        if(!allowNullSObjects){
            throw new ZD_RecordException('String constructor for ZD_Record class is for Test classes only.');
        }
        fields = new Map<String,Object>();
        this.objectAPIName = objectAPIName;
    }

    /**
     * @description constructor an sobject passed in
     * @param sObj - sobject the record holds/represents
     */
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

    /**
     * @description get method simiar to sobject or map get method
     * @param key - string value of field to get
     * @return value stored at that key in the fields map or the sobject
     */
    public Object get(String key){
        return sObj != null ? sObj.get(key) : fields.get(key);
    }

    /**
     * @description put method simiar to sobject or map put method
     * @param key - string value of field to put value at
     * @param value - stored at that key in the fields map or the sobject
     */
    public void put(String key, Object value){
        if(sObj != null){
            sObj.put(key, value);
        }else{
            fields.put(key, value);
        }
    }

    /**
     * @description analagous to the sobject putSObjectMethod but also works with the fields map
     * @param key - string value of field to put value at
     * @param value - stored at that key in the fields map or the sobject
     */
    public void putSObject(String key, Object value){
        if(sObj != null){
            sObj.putSObject(key, (SObject) value);
        }else{
            fields.put(key, value);
        }
    }


    /**
     * @description get method simiar to sobject getSObject method
     * @param key - string value of field to get value from
     * @return zd_record stored at that key
     */
    public ZD_Record getSObject(String key){
        return sObj != null ? new ZD_Record(sObj.getSObject(key)) : (ZD_Record) fields.get(key);
    }

    /**
     * @description get method simiar to sobject getSObjects method
     * @param key - string value of field to put value at
     * @return list of zd_records stored at that key
     */
    public List<ZD_Record> getSObjects(String key){
        if(sObj == null){
            return (List<ZD_Record>) fields.get(key);
        }
        return ZD_Record.toRecords(sObj.getSObjects(key));
    }

    /**
     * @description utility method for getting the name of the object we are operating on
     * @return string representing the object api name of the record
     */
    public String getObjectAPIName(){
        return sObj != null ? sObj.getSObjectType().getDescribe().getName() : this.objectAPIName;
    }

    /**
     * @description utility method for getting the sobject inside the zd record
     * @return sobject the zd record is holding
     */
    public SObject sObject(){
        return sObj;
    }

    /**
     * @description utility method for converting a list of ZD_Records to sobjects
     * @param recordsList - list of ZD_Records
     * @return List of sobjects the zd records were holding
     */
    public static List<SObject> toSObjects(List<ZD_Record> recordsList){
        List<SObject> sObjs = new List<SObject>();
        if(recordsList != null){
            for(ZD_Record rec : recordsList){
                sObjs.add(rec.sObject());
            }
        }
        return sObjs;
    }

    /**
     * @description utility method for converting a list of sobjects to ZD records
     * @param sObjs - list of sobjects
     * @return List of ZD_Records that hold the sobjects
     */
    public static List<ZD_Record> toRecords(List<SObject> sObjs){
        List<ZD_Record> records = new List<ZD_Record>();
        if(sObjs != null){
            for(SObject sObj : sObjs){
                records.add(new ZD_Record(sObj));
            }
        }
        return records;
    }

    /**
     * @description utility method for converting a list of sobjects to a map of ZD records
     * @param sObjs - list of sobjects
     * @return map of ZD_Records by id that hold the sobjects
     */
    public static Map<Id, ZD_Record> toRecordsMap(List<SObject> sObjs){
        Map<Id, ZD_Record> records = new Map<Id, ZD_Record>();
        if(sObjs != null){
            for(SObject sObj : sObjs){
                records.put(sObj.Id, new ZD_Record(sObj));
            }
        }
        return records;
    }

    /**
     * @description utility method for converting a list of zd records to a map of ZD records
     * @param records - list of zd records
     * @return map of ZD_Records by id
     */
    public static Map<Id, ZD_Record> toRecordsMap(List<ZD_Record> records){
        Map<Id, ZD_Record> recordsMap = new Map<Id, ZD_Record>();
        if(records != null){
            for(ZD_Record record : records){
                recordsMap.put(record.Id, record);
            }
        }
        return recordsMap;
    }
}