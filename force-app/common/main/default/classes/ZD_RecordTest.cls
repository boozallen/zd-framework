/**
 * @description test for the zd record class
 * This software package is licensed under the Booz Allen Public License. 
 * Copyright © 2023 Booz Allen Hamilton Inc.  All Rights Reserved.
 */
@isTest
public class ZD_RecordTest {
    
    @isTest
    public static void testZDRecordWithSObject(){
        String childAccountId = ZD_Application.Util.getFakeId('001');
        String parentAccountId = ZD_Application.Util.getFakeId('001');
        String contact1Id = ZD_Application.Util.getFakeId('003');
        String jsonString = '{"attributes":{"type":"Account"},"Id":"' + childAccountId + '","Name":"Test Child Account","ParentId":"' + parentAccountId + '","Contacts":{"totalSize":2,"done":true,"records":[{"attributes":{"type":"Contact"},"AccountId":"' + childAccountId + '","Id":"' + contact1Id + '","Name":"Test Person1"},{"attributes":{"type":"Contact"},"AccountId":"' + childAccountId + '","Id":"' + contact1Id + '","Name":"Test Person2"}]},"Parent":{"attributes":{"type":"Account"},"Id":"' + parentAccountId + '","Name":"Test Parent Account"}}';
    	Account acc = (Account) JSON.deserialize(jsonString, Account.class);
        ZD_Record accWrapper = new ZD_Record(acc.clone(true, false, false, false));
        Assert.areEqual(accWrapper.get('Name'), acc.get('Name'), 'Wrapper and record Name should be the same');
        Assert.areEqual(accWrapper.getSObjects('Contacts')[0].get('Name'), acc.getSObjects('Contacts')[0].get('Name'), 'Wrapper and record Name should be the same');
        Assert.areEqual(accWrapper.getSObject('Parent').Id, acc.getSObject('Parent').Id, 'Wrapper and record id should be the same');
        acc.put('Name', 'New Name');
        Assert.isFalse(accWrapper.get('Name') == acc.get('Name'), 'Names Should now be different');
        accWrapper.put('Name', 'New Name');
        Assert.areEqual(accWrapper.get('Name'), acc.get('Name'), 'Names Should now be the same again');
        Assert.areEqual(acc.Id, accWrapper.sObject().Id, 'Account ids should be the same');
        ZD_Record contact = new ZD_Record(new Contact());
        contact.putSObject('Account', acc);
        Assert.isTrue(contact.getSObject('Account').sobject() == acc, 'Account should be set');
    }

    @isTest
    public static void testZDRecordWithoutSObject(){
        String childAccountId = ZD_Application.Util.getFakeId('001');
        String parentAccountId = ZD_Application.Util.getFakeId('001');
        
        ZD_Record mockedChildWrapper = new ZD_Record('Account');
        ZD_Record mockedParentWrapper = new ZD_Record('Account');
        ZD_Record mockedContact1Wrapper = new ZD_Record('Contact');
        ZD_Record mockedContact2Wrapper = new ZD_Record('Contact');

        //parent account fields/relationships
        mockedParentWrapper.Id = parentAccountId;
        mockedParentWrapper.put('Name', 'Test Parent Account');

        //contact1 fields/relationships
        mockedContact1Wrapper.put('Name', 'Test Person1');
        mockedContact1Wrapper.put('AccountId', childAccountId);

        //contact2 fields/relationships
        mockedContact2Wrapper.put('Name', 'Test Person2');
        mockedContact2Wrapper.put('AccountId', childAccountId);

        //child account fields/relationships
        mockedChildWrapper.Id = childAccountId;
        mockedChildWrapper.put('ParentId', parentAccountId);
        mockedChildWrapper.putSObject('Parent', mockedParentWrapper);
        mockedChildWrapper.put('Name', 'Test Child Account');
        mockedChildWrapper.put('Contacts', new List<ZD_Record>{mockedContact1Wrapper, mockedContact2Wrapper});
        
        Assert.areEqual(mockedChildWrapper.get('Name'), 'Test Child Account', 'Name Mismatch on child account');
        Assert.areEqual(mockedChildWrapper.getSObjects('Contacts')[0].get('Name'), 'Test Person1', 'Wrapper and record Name should be the same');
        Assert.areEqual(mockedChildWrapper.getSObject('Parent').get('Id'), parentAccountId, 'Wrapper and record Id should be the same');
        mockedChildWrapper.put('Name', 'New Name');
        Assert.areEqual(mockedChildWrapper.get('Name'), 'New Name', 'Names should be new name');
        Assert.areEqual(null, mockedChildWrapper.sObject(), 'no sobject in this record');
    }

    @isTest
    public static void testNullErrorsThrown(){
        ZD_Record.allowNullSObjects = false;
        try{
            new ZD_Record('Account');
            Assert.fail('Constructor should fail');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('String constructor for ZD_Record class is for Test classes only.'), 'MSG should be: Default constructor for ZD_Record class is for Test classes only');
        }
        try{
            SObject s = (SObject) Type.forName('NON_EXISITENT_SOBJECT')?.newInstance();
            new ZD_Record(s);
            Assert.fail('Constructor should fail');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('Cannot pass null into the ZD_Record class.'), 'MSG should be: Cannot pass null into the ZD_Record class.');
        }
    }
    
    @isTest
    public static void testToZDRecords(){
        List<SObject> accSObjList = new List<SObject>{new Account()};
        List<ZD_Record> accZDRecordList = ZD_Record.toRecords(accSObjList);
        Assert.areEqual(1, accZDRecordList.size(), 'should be a record list of size 1');
        Assert.areEqual(true, accZDRecordList[0].sObject() instanceof Account, 'entry should be an account');
    }
    
    @isTest
    public static void testToSObjects(){
        List<ZD_Record> accZDRecordList = new List<ZD_Record>{new ZD_Record(new Account())};
        List<SObject> accSObjList = ZD_Record.toSObjects(accZDRecordList);
        Assert.areEqual(1, accSObjList.size(), 'should be a record list of size 1');
        Assert.areEqual(true, accSObjList[0] instanceof Account, 'entry should be an account');
    }
    
    @isTest
    public static void testGetObjectAPIName(){
        ZD_Record o = new ZD_Record('Opportunity');
        ZD_Record a = new ZD_Record(new Account());
        Assert.isTrue(o.getObjectApiName() == 'Opportunity', 'o should be an opportunity');
        Assert.isTrue(a.getObjectApiName() == 'Account', 'a should be an Account');
    }
    
    @isTest
    public static void testToRecordsMap(){
        ZD_Record o = new ZD_Record('Opportunity');
        o.Id = ZD_Application.Util.getFakeId('006');
        ZD_Record a = new ZD_Record(new Account(Id = ZD_Application.Util.getFakeId('001')));
        List<ZD_Record> recordList = new List<ZD_Record>{o,a};
        List<SObject> sObjList = new List<SObject>{new Account(Id=ZD_Application.Util.getFakeId('001')), new Account(Id=ZD_Application.Util.getFakeId('001'))};
        Assert.isTrue(ZD_Record.toRecordsMap(sObjList).keySet().contains('001000000000000004'), 'should contain account ending in 004');
        Assert.isTrue(ZD_Record.toRecordsMap(recordList).keySet().contains('006000000000000001'), 'should contain opp ending in 001');
        Assert.isTrue(ZD_Record.toRecordsMap(recordList).keySet().contains('001000000000000002'), 'should contain account ending in 002');
    }
    
    @isTest
    public static void testRecordConstructorWithNullSObj(){
        ZD_Record.allowNullSObjects = true;
        Account a = null;
        ZD_Record recordA = new ZD_Record(a);
        Assert.isNull(recordA.getObjectAPIName(), 'null sobject passed in, cannot determine sobject name');
    }
}