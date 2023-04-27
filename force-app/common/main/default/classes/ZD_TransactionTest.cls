/**
 * @description test for the zd transaction class
 * This software package is licensed under the Booz Allen Public License. 
 * Portions of this code are Copyright © 2023 FinancialForce.com, Inc. All Rights Reserved.
 */
@isTest
@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ApexDoc')
public without sharing class ZD_TransactionTest {

     private static Map<String, Map<Id,ZD_Record>> mockedDatabase = new Map<String,Map<Id,ZD_Record>>{
         	'Product2' => new Map<Id,ZD_Record>(),
            'PricebookEntry' => new Map<Id,ZD_Record>(),
            'Opportunity' => new Map<Id,ZD_Record>(),
            'OpportunityLineItem' => new Map<Id,ZD_Record>(),
                'Before__e' => new Map<Id,ZD_Record>(),
                'AfterSuccess__e' => new Map<Id,ZD_Record>(),
                'AfterFailure__e' => new Map<Id,ZD_Record>()
     };
       
    @isTest
    private static void testTransactionFactoryGetInstance(){
        ZD_Transaction zdt = ZD_Transaction.factory.getInstance('unitTest', new List<String>(mockedDatabase.keySet()));
        zdt.registerNew(new Opportunity());
        ZD_Transaction.factory.getInstance('unitTest', new List<String>(mockedDatabase.keySet()));
        Assert.isTrue(zdt.newListByType.get('Opportunity').size() == 1, 'should be same transaction');                                                  	
    }
    
    @isTest
    private static void testTransactionFactoryGetInstanceDifferentModes(){
        ZD_Transaction zdt = ZD_Transaction.factory.getInstance('unitTest', new List<String>(mockedDatabase.keySet()));
        zdt.registerNew(new Opportunity());
        ZD_Transaction zdt2 = ZD_Transaction.factory.getInstance('unitTest', new List<String>(mockedDatabase.keySet()));
        Assert.isTrue(zdt2.newListByType.get('Opportunity').size() == 1, 'should be same transaction');    
        ZD_Transaction zdt3 = ZD_Transaction.factory.getInstance('unitTest', new List<String>(mockedDatabase.keySet()), System.AccessLevel.SYSTEM_MODE);
        Assert.isTrue(zdt3.newListByType.get('Opportunity').size() == 0, 'should not be same transaction');    
    }
    
    @isTest
    private static void testTransactionFactoryGetInstanceExtension(){
        ZD_Transaction zdt = ZD_Transaction.factory.getInstance('unitTest', new List<String>(mockedDatabase.keySet()), 'ZD_TransactionTest.DerivedTransaction');
        zdt.registerNew(new Opportunity());
        ZD_Transaction zdt2 = ZD_Transaction.factory.getInstance('unitTest', new List<String>(mockedDatabase.keySet()));
        Assert.isTrue(zdt2 instanceof ZD_TransactionTest.DerivedTransaction, 'ZD_TransactionTest.DerivedTransaction');  
        Assert.isTrue(zdt2.newListByType.get('Opportunity').size() == 1, 'should be same transaction');                                                  	
    }
                
    @IsTest
    private static void testTransactionEmail(){
        ZD_DatabaseService.dbService = new MockDBService();
        String testRecordName = 'ZD Transaction Test Name 1';

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ 'foobar@test.com' });
        email.setPlainTextBody('See Spot run.');

        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));

        zdt.emailWork = new Mock_SendEmailWork();

        ZD_Record opp = new ZD_Record('Opportunity');
        opp.put('Name',testRecordName);
        opp.put('StageName','Open');
        opp.put('CloseDate',System.today());
        zdt.registerNew(opp);
        
        ZD_Record opp2 = new ZD_Record('Opportunity');
        opp2.put('Name',testRecordName);
        opp2.put('StageName','Open');
        opp2.put('CloseDate',System.today());
        zdt.registerNew(new List<ZD_Record>{opp2});
        
        Opportunity opp3 = new Opportunity();
        opp3.Name = testRecordName;
        opp3.StageName = 'Open';
        opp3.CloseDate = System.today();
		zdt.registerNew(opp3);
        
        zdt.registerEmail(email);

        zdt.registerRelationship(email,opp);
        zdt.registerRelationship(email,opp3);

        zdt.commitTransaction();

        // assert that mock email functionality was called
        Assert.isTrue(((Mock_SendEmailWork) zdt.emailWork).doWorkWasCalled, 'Email doWork should have been called');

        Assert.areEqual(3, mockedDatabase.get('Opportunity').values().size(), '3 opportunities should have been inserted into the mock db');
    }
    
    @IsTest
    private static void testRegisterNewThrowExceptionOnDirtyRecord(){
        // GIVEN an existing record
        Opportunity opportunity = new Opportunity(Id = ZD_Application.util.getFakeId('006'));
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));

        // WHEN we register the existing record as new
        Boolean exceptionThrown = false;
        try
        {
            zdt.registerNew(opportunity);
            Assert.fail('This should fail and go to the catch block');
        }
        catch (Exception e)
        {
            exceptionThrown = true;
            Assert.areEqual(
                    'Only new records can be registered as new',
                    e.getMessage(),
                    'Incorrect exception message thrown'
            );
        }

        // THEN it should have thrown an exception
        Assert.isTrue(exceptionThrown, 'exception should have been thrown');
    }
    
    @IsTest
    private static void testRegisterDirtyThrowExceptionOnNewRecord(){
        // GIVEN an new record
        Opportunity opportunity = new Opportunity();
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));

        // WHEN we register the existing record as new
        Boolean exceptionThrown = false;
        try{
            zdt.registerDirty(opportunity);
            Assert.fail('should fail and go to catch block');
        }
        catch (Exception e){
            exceptionThrown = true;
            Assert.areEqual(
                    'New records cannot be registered as dirty',
                    e.getMessage(),
                    'Incorrect exception message thrown'
            );
        }

        // THEN it should have thrown an exception
        Assert.isTrue(exceptionThrown, 'exception should have been thrown');
    }
    
    @IsTest
    private static void testRegisterDeleted(){
        ZD_DatabaseService.dbService = new MockDBService();
        // GIVEN - two existing records
        ZD_Record opportunity1 = new ZD_Record('Opportunity');
        Opportunity opportunity2 = new Opportunity();
        Opportunity opportunity3 = new Opportunity();
        ZD_Record product = new ZD_Record('Product2');
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        ZD_DatabaseService.doInsert(new List<ZD_Record> { opportunity1, product, new ZD_Record(opportunity2), new ZD_Record(opportunity3) });
		Assert.areEqual(3, mockedDatabase.get('Opportunity').values().size(), 'Should be 3 opps in the mocked database');
        Assert.areEqual(1, mockedDatabase.get('Product2').values().size(), 'Should be 1 product in the mocked database');
        // WHEN - we mark the records as deleted
        zdt.registerDeleted(new List<ZD_Record> { opportunity1 });
        zdt.registerDeleted(product);
        zdt.registerDeleted(opportunity2);
        zdt.registerDeleted(new List<SObject>{opportunity3});
        zdt.commitTransaction();

        // THEN - the dmlDelete action should be invoked
        Assert.areEqual(0, mockedDatabase.get('Opportunity').values().size(), 'should now be zero opps in the mocked database');
        Assert.areEqual(0, mockedDatabase.get('Product2').values().size(), 'should be zero products in the mocked database');
    }
    
    @IsTest
    private static void testRegisterDeletedNewRecord(){
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        try{
            zdt.registerDeleted(new Opportunity());
            Assert.fail('should go to catch block');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('New records cannot be registered for deletion'), 'wrong error caught - should be new record deletion error message');
        }
    }
    
    @IsTest
    private static void testAssertForNonEventSObjectType(){
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        try{
            zdt.assertForNonEventSObjectType('CustomObject__c');
        }catch(Exception e){
            Assert.fail('should not throw an exception');
        }
        
    }
    
    @IsTest
    private static void testAssertForNonEventSObjectTypeThrowExceptionOnEventObject (){
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        Boolean exceptionThrown = false;
        try{
            zdt.assertForNonEventSObjectType('PlatformEventObject__e');
            Assert.fail('should go to catch block');
        }
        catch (Exception e){
            exceptionThrown = true;
            Assert.isTrue(
                    e.getMessage().contains('registerPublishBeforeTransaction'),
                    'Incorrect exception message thrown'
            );
        }
        Assert.isTrue(exceptionThrown, 'exception should have been thrown');
    }
    
    @IsTest
    private static void testAssertForEventSObjectType(){
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        try{
            zdt.assertForEventSObjectType('PlatformEventObject__e');
        }catch(Exception e){
            Assert.fail('should not throw an exception');
        }
    }

    @IsTest
    private static void testAssertForEventSObjectTypeThrowExceptionOnNonEventObject()
    {
        Boolean exceptionThrown = false;
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        try{
            zdt.assertForEventSObjectType('CustomObject__c');
            Assert.fail('should go to catch block');
        }
        catch (Exception e)
        {
            exceptionThrown = true;
            Assert.isTrue(
                    e.getMessage().contains('invalid for publishing'),
                    'Incorrect exception message thrown'
            );
        }

        Assert.isTrue(exceptionThrown, 'exception should have been thrown');
    }
    
    @IsTest
    private static void testAssertForSupportedSObjectTypethrowExceptionOnUnsupportedType(){
        Boolean exceptionThrown = false;
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        try{
            zdt.registerNew(new Account());
            Assert.fail('should go to catch block');
        }
        catch (Exception e){
            exceptionThrown = true;
            Assert.isTrue(
                    e.getMessage().contains('not supported by this transaction'),
                    'Incorrect exception message thrown'
            );
        }

        Assert.isTrue(exceptionThrown, 'exception should have been thrown');
    }
    
    @IsTest
    private static void testDerivedTransactionCommitSuccess()
    {
        ZD_DatabaseService.dbService = new MockDBService();
        // Insert Opportunities with derived transaction
        DerivedTransaction dt = new DerivedTransaction(new List<String>(mockedDatabase.keySet()));
        for(Integer o=0; o<5; o++)
        {
            Opportunity opp = new Opportunity();
            opp.Name = 'Transaction Test Name ' + o;
            opp.StageName = 'Open';
            opp.CloseDate = System.today();
            dt.registerNew(new List<SObject>{opp});
            for(Integer i=0; i<o+1; i++)
            {
                Product2 product = new Product2();
                product.Name = opp.Name + ' : Product : ' + i;
                dt.registerNew(new List<SObject>{product});
                PricebookEntry pbe = new PricebookEntry();
                pbe.UnitPrice = 10;
                pbe.IsActive = true;
                pbe.UseStandardPrice = false;
                dt.registerNew(pbe, 'Product2Id', product);
                OpportunityLineItem oppLineItem = new OpportunityLineItem();
                oppLineItem.Quantity = 1;
                oppLineItem.TotalPrice = 10;
                dt.registerRelationship(oppLineItem, 'PricebookEntryId', pbe);
                dt.registerNew(oppLineItem, 'OpportunityId', opp);
            }
        }
        dt.commitTransaction();

        // Assert Results
        Assert.areEqual(5, mockedDatabase.get('Opportunity').values().size(), 'Should be 10 ops');
        Assert.areEqual(15, mockedDatabase.get('Product2').values().size(), 'Should be 55 Product2');
        Assert.areEqual(15, mockedDatabase.get('PricebookEntry').values().size(), 'Should be 55 PricebookEntry');
        Assert.areEqual(15, mockedDatabase.get('OpportunityLineItem').values().size(), 'Should be 55 OpportunityLineItem');

        Assert.isTrue(dt.commitWorkEventsFired.contains('onCommitStart'), 'onCommitStart should be in the events fired');
        Assert.isTrue(dt.commitWorkEventsFired.contains('doWork'), 'doWork should be in the events fired');
        Assert.isTrue(dt.commitWorkEventsFired.contains('onCommitWorkFinished - true'), 'onCommitWorkFinished - true should be in the events fired');
    }
    
    @IsTest
    private static void testDerivedTransactionCommitDMLFail(){
        // Insert Opportunities with derived transaction
        DerivedTransaction dt = new DerivedTransaction(new List<String>(mockedDatabase.keySet()));
        Opportunity opp = new Opportunity();
        dt.registerNew(new List<SObject>{opp});
        Boolean didFail = false;
        Exception caughtEx = null;

        try {
            dt.commitTransaction();
        }
        catch (Exception dmlex) {
            didFail = true;
            caughtEx = dmlex;
        }

        // Assert Results
        System.assertEquals(didFail, true, 'didFail');
        System.assert(caughtEx.getMessage().contains('REQUIRED_FIELD_MISSING'), String.format('Exception message was ', new List<String> { caughtEx.getMessage() }));
        Assert.isTrue(dt.commitWorkEventsFired.contains('onCommitStart'), 'onCommitStart should be in the events fired');
        Assert.isTrue(dt.commitWorkEventsFired.contains('onCommitWorkFinished - false'), 'onCommitWorkFinished - false should be in the events fired');

    }
    
    @IsTest
    private static void testRegisterDirtyExpectReplacement()
    {
        ZD_DatabaseService.dbService = new MockDBService();
        final Opportunity insertedOpp = new Opportunity(
                Id = ZD_Application.util.getFakeId('006'),
                Name = 'Original',
                StageName = 'Open',
                CloseDate = System.today());

        Opportunity opp = new Opportunity(Id = insertedOpp.Id, Name = 'Never');
        Opportunity opp2 = new Opportunity(Id = insertedOpp.Id, Name = 'Expected');

        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        zdt.registerDirty(opp);
        zdt.registerDirty(opp2);
        zdt.commitTransaction();

        Assert.areEqual(1, mockedDatabase.get('Opportunity').values().size(), 'should be one opp in the database');
        Assert.areEqual('Expected', mockedDatabase.get('Opportunity').values()[0].get('Name'), 'name should be "Expected"');
    }
    
    @IsTest
    private static void testRegisterDirtyField() {
        ZD_DatabaseService.dbService = new MockDBService();
        Opportunity opp = new Opportunity(
                Id = ZD_Application.util.getFakeId('006'),
                Name = 'test name',
                StageName = 'Open',
                CloseDate = System.today());

        ZD_Record nameUpdate = new ZD_Record('Opportunity');
        nameUpdate.Id = opp.Id;
        nameUpdate.put('Name', 'UpdateName');
        Opportunity amountUpdate = new Opportunity(Id = opp.Id, Amount = 250);
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        zdt.registerDirty(nameUpdate);
        zdt.registerDirty(amountUpdate, new List<String> { 'Amount' } );
        zdt.commitTransaction();

        Assert.areEqual(1, mockedDatabase.get('Opportunity').values().size(), 'should be 1 opp in the database');
        Assert.areEqual(nameUpdate.get('Name'), mockedDatabase.get('Opportunity').values()[0].get('Name'), 'name should be updated');
        Assert.areEqual(amountUpdate.Amount, mockedDatabase.get('Opportunity').values()[0].get('Amount'), 'amount should be updated');
    }
    
    @IsTest
    private static void testRegisterDirtyRecordsWithDirtyFieldsNotUpdating(){
        ZD_DatabaseService.dbService = new MockDBService();
        // GIVEN a list of existing records
        Opportunity opportunityA = new Opportunity(
                Id = ZD_Application.util.getFakeId('006'),
                Name = 'test name A',
                StageName = 'Open',
                CloseDate = System.today());
        Opportunity opportunityB = new Opportunity(
                Id = ZD_Application.util.getFakeId('006'),
                Name = 'test name B',
                StageName = 'Open',
                CloseDate = System.today());

        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        zdt.registerDirty(new List<Opportunity>{ opportunityA, opportunityB });

        // WHEN we register the records again with different fields updated
        List<Opportunity> recordsWithStageUpdate = new List<Opportunity>
        {
                new Opportunity(Id = opportunityA.Id, StageName = 'Closed'),
                new Opportunity(Id = opportunityB.Id, StageName = 'Closed')
        };
        List<Opportunity> recordsWithAmountUpdate = new List<Opportunity>
        {
                new Opportunity(Id = opportunityA.Id, Amount = 250),
                new Opportunity(Id = opportunityB.Id, Amount = 250)
        };
        zdt.registerDirty(recordsWithStageUpdate, new List<String> { 'StageName' });
        zdt.registerDirty(recordsWithAmountUpdate, new List<String> { 'Amount' });
        zdt.registerDirty( // Register again the original record, should overwrite the one with the dirty fields
                new Opportunity(
                Id = opportunityB.Id,
                Name = 'test name B',
                StageName = 'Open',
                CloseDate = System.today())
        ); 
        zdt.commitTransaction();

        // THEN the records should be registered with both changed values for Amount and StageName
        Assert.areEqual(2, mockedDatabase.get('Opportunity').values().size(), 'should be two opps in database');
        Assert.areEqual('Closed', mockedDatabase.get('Opportunity').values()[0].get('StageName'), '1st opp should be closed');
        Assert.areEqual(250, mockedDatabase.get('Opportunity').values()[0].get('Amount'), '1st opp should have an amount of 250');
        Assert.areEqual('Open', mockedDatabase.get('Opportunity').values()[1].get('StageName'), '2nd opp should have as status of open');
        Assert.areEqual(null, mockedDatabase.get('Opportunity').values()[1].get('Amount'), 'second opp should have a null amount');
    }
    
    @IsTest
    private static void testRegisterDirtyRecordsWithDirtyFields(){
        ZD_DatabaseService.dbService = new MockDBService();
        // GIVEN a list of existing records
        Opportunity opportunityA = new Opportunity(
                Id = ZD_Application.util.getFakeId('006'),
                Name = 'test name A',
                StageName = 'Open',
                CloseDate = System.today());
        Opportunity opportunityB = new Opportunity(
                Id = ZD_Application.util.getFakeId('006'),
                Name = 'test name B',
                StageName = 'Open',
                CloseDate = System.today());

        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        zdt.registerDirty(new List<Opportunity>{ opportunityA, opportunityB });

        // WHEN we register the records again with different fields updated
        List<Opportunity> recordsWithStageUpdate = new List<Opportunity>
        {
                new Opportunity(Id = opportunityA.Id, StageName = 'Closed'),
                new Opportunity(Id = opportunityB.Id, StageName = 'Closed')
        };
        List<ZD_Record> recordsWithAmountUpdate = new List<ZD_Record>();
        ZD_Record amountUpdateOpp1 = new ZD_Record('Opportunity');
        amountUpdateOpp1.Id = opportunityA.Id;
        amountUpdateOpp1.put('Amount', 250);
        recordsWithAmountUpdate.add(amountUpdateOpp1);
        
        ZD_Record amountUpdateOpp2 = new ZD_Record('Opportunity');
        amountUpdateOpp2.Id = opportunityB.Id;
        amountUpdateOpp2.put('Amount', 250);
        recordsWithAmountUpdate.add(amountUpdateOpp2);
        
        zdt.registerDirty(recordsWithStageUpdate, new List<String> { 'StageName' });
        zdt.registerDirty(recordsWithAmountUpdate, new List<String> { 'Amount' });
        zdt.commitTransaction();

        // THEN the records should be registered with both changed values for Amount and StageName
        Assert.areEqual(2, mockedDatabase.get('Opportunity').values().size(), 'should be 2 opps in the database');
        Assert.areEqual('Closed', mockedDatabase.get('Opportunity').values()[0].get('StageName'), '1st opp should be closed');
        Assert.areEqual(250, mockedDatabase.get('Opportunity').values()[0].get('Amount'), '1st opp should have an amount of 250');
        Assert.areEqual('Closed', mockedDatabase.get('Opportunity').values()[1].get('StageName'), '2nd opp should be closed');
        Assert.areEqual(250, mockedDatabase.get('Opportunity').values()[1].get('Amount'), '2nd opp should have an amount of 250');
    }
    
    @IsTest
    private static void testRegisterUpsert() {
        ZD_DatabaseService.dbService = new MockDBService();
        Opportunity existingOpp = new Opportunity(
                Id = ZD_Application.util.getFakeId('006'),
                Name = 'Existing Opportunity',
                StageName = 'Closed',
                CloseDate = System.today());
        
        ZD_Record existingOpp2 = new ZD_Record('Opportunity');
        existingOpp2.Id = ZD_Application.util.getFakeId('006');

        Opportunity newOpportunity = new Opportunity(Name = 'New Opportunity', StageName = 'Closed', CloseDate = System.today());
        ZD_Record newOpportunity2 = new ZD_Record('Opportunity');

        Test.startTest();
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        zdt.registerUpsert(new List<Opportunity>{existingOpp, newOpportunity});
        zdt.registerUpsert(existingOpp2);
        zdt.registerUpsert(new List<ZD_Record>{newOpportunity2});
        zdt.commitTransaction();
        Test.stopTest();

        Assert.areEqual(4, mockedDatabase.get('Opportunity').values().size(), 'should be 4 opps in the database');
    }
    
    @IsTest
    private static void testRegisterPublishBefore() {
        ZD_DatabaseService.dbService = new MockDBService();
       
        
        ZD_Record before1 = new ZD_Record('Before__e');
        before1.Id = ZD_Application.util.getFakeId('0B4');
		ZD_Record before2 = new ZD_Record('Before__e');
        before2.Id = ZD_Application.util.getFakeId('0B4');

        Test.startTest();
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        zdt.registerPublishBeforeTransaction(new List<ZD_Record>{before1});
        zdt.registerPublishBeforeTransaction(before2);
        zdt.commitTransaction();
        Test.stopTest();

        Assert.areEqual(2, mockedDatabase.get('Before__e').values().size(), 'should be 2 before__e events');
    }
    
    @IsTest
    private static void testRegisterPublishAfterSuccess() {
        ZD_DatabaseService.dbService = new MockDBService();
       
        
        ZD_Record as1 = new ZD_Record('AfterSuccess__e');
        as1.Id = ZD_Application.util.getFakeId('0AS');
		ZD_Record as2 = new ZD_Record('AfterSuccess__e');
        as2.Id = ZD_Application.util.getFakeId('0AS');
        ZD_Record af1 = new ZD_Record('AfterFailure__e');
        af1.Id = ZD_Application.util.getFakeId('0AF');
		ZD_Record af2 = new ZD_Record('AfterFailure__e');
        af2.Id = ZD_Application.util.getFakeId('0AF');

        Test.startTest();
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        zdt.registerPublishAfterSuccessTransaction(new List<ZD_Record>{as1});
        zdt.registerPublishAfterSuccessTransaction(as2);
        zdt.registerPublishAfterFailureTransaction(new List<ZD_Record>{af1});
        zdt.registerPublishAfterFailureTransaction(af2);
        zdt.commitTransaction();
        Test.stopTest();

        Assert.areEqual(2, mockedDatabase.get('AfterSuccess__e').values().size(), 'should be 2 after success events');
        Assert.areEqual(0, mockedDatabase.get('AfterFailure__e').values().size(), 'should be 0 after failure events');
    }
    
    @IsTest
    private static void testRegisterPublishAfterFailure() {
        ZD_DatabaseService.dbService = new MockDBService();
       
        
        ZD_Record as1 = new ZD_Record('AfterSuccess__e');
        as1.Id = ZD_Application.util.getFakeId('0AS');
		ZD_Record as2 = new ZD_Record('AfterSuccess__e');
        as2.Id = ZD_Application.util.getFakeId('0AS');
        ZD_Record af1 = new ZD_Record('AfterFailure__e');
        af1.Id = ZD_Application.util.getFakeId('0AF');
		ZD_Record af2 = new ZD_Record('AfterFailure__e');
        af2.Id = ZD_Application.util.getFakeId('0AF');

        Test.startTest();
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        zdt.registerPublishAfterSuccessTransaction(new List<ZD_Record>{as1});
        zdt.registerPublishAfterSuccessTransaction(as2);
        zdt.registerPublishAfterFailureTransaction(new List<ZD_Record>{af1});
        zdt.registerPublishAfterFailureTransaction(af2);
        zdt.registerWork(new ErrorThrower());
        try{
            zdt.commitTransaction();
            Assert.fail('should go to catch block');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('Always fail'), 'wrong error message');
        }
        
        Test.stopTest();

        Assert.areEqual(0, mockedDatabase.get('AfterSuccess__e').values().size(), 'should be 0 after success events');
        Assert.areEqual(2, mockedDatabase.get('AfterFailure__e').values().size(), 'should be 2 after failure events');
    }
    
    //cant actually assert on the publish because no standard platform event exists. if it ever does
    //then update this test to assert on the event
    @IsTest
    private static void testRegisterPublishSObject() {
        ZD_DatabaseService.dbService = new MockDBService();
       
        Opportunity opp1 = new Opportunity(Id = ZD_Application.util.getFakeId('006'));
        Opportunity opp2 = new Opportunity(Id = ZD_Application.util.getFakeId('006'));
        
        ZD_Record as1 = new ZD_Record('AfterSuccess__e');
        as1.Id = ZD_Application.util.getFakeId('0AS');
		ZD_Record as2 = new ZD_Record('AfterSuccess__e');
        as2.Id = ZD_Application.util.getFakeId('0AS');
        ZD_Record af1 = new ZD_Record('AfterFailure__e');
        af1.Id = ZD_Application.util.getFakeId('0AF');
		ZD_Record af2 = new ZD_Record('AfterFailure__e');
        af2.Id = ZD_Application.util.getFakeId('0AF');

        Test.startTest();
        ZD_Transaction zdt = new ZD_Transaction(new List<String>(mockedDatabase.keySet()));
        try{
            zdt.registerPublishAfterSuccessTransaction(new List<SObject>{opp1});
            Assert.fail('should go to catch black');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('is invalid for publishing within this transaction'), 'wrong error message');
        }
        try{
            zdt.registerPublishAfterSuccessTransaction(opp2);
            Assert.fail('should go to catch black');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('is invalid for publishing within this transaction'), 'wrong error message');
        }
        try{
            zdt.registerPublishAfterFailureTransaction(new List<SObject>{opp1});
            Assert.fail('should go to catch black');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('is invalid for publishing within this transaction'), 'wrong error message');
        }
        try{
            zdt.registerPublishAfterFailureTransaction(opp2);
            Assert.fail('should go to catch black');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('is invalid for publishing within this transaction'), 'wrong error message');
        }
        try{
            zdt.registerPublishBeforeTransaction(new List<SObject>{opp1});
            Assert.fail('should go to catch black');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('is invalid for publishing within this transaction'), 'wrong error message');
        }
        try{
            zdt.registerPublishBeforeTransaction(opp2);
            Assert.fail('should go to catch black');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('is invalid for publishing within this transaction'), 'wrong error message');
        }
        
        Test.stopTest();
		Assert.areEqual(0, mockedDatabase.get('Before__e').values().size(), 'should be zero before events');
        Assert.areEqual(0, mockedDatabase.get('AfterSuccess__e').values().size(), 'should be zero after success events');
        Assert.areEqual(0, mockedDatabase.get('AfterFailure__e').values().size(), 'should be zero after failure events');
    }
    
    class ErrorThrower implements ZD_Transaction.IDoWork{
        public void doWork(){
            throw new TestException('Always fail');
        }
    }
    
    public class DerivedTransaction extends ZD_Transaction implements ZD_Transaction.IDoWork
    {
        @TestVisible private List<String> commitWorkEventsFired = new List<String>();
        @TestVisible private Set<String> registeredTypes = new Set<String>();
        
        public DerivedTransaction(){
            super();
        }
        
        public List<String> getCommitWorkEventsFired(){
            return commitWorkEventsFired.clone();
        }

        public Set<String> getRegisteredTypes(){
            return registeredTypes.clone();
        }

        public DerivedTransaction(List<String> sObjectTypes){
            super(sObjectTypes);
            super.registerWork(this);
        }

        private void addEvent(String event)
        {
            // events should only be fired one time
            // ensure that this event has not been fired already
            for (String eventName :commitWorkEventsFired)
            {
                if (event == eventName){
                    throw new DerivedTransactionException(String.format('Event {0} has already been fired.', new List<String> { event }));
                }
            }
            commitWorkEventsFired.add(event);
        }


        public override void onCommitStart(){
            addEvent('onCommitStart');
        }
        
        public void doWork(){
            addEvent('doWork');
        }


        public override void onCommitFinish(Boolean wasSuccessful, Exception e)
        {
            addEvent('onCommitWorkFinished - ' + wasSuccessful);
        }
    }
    
    public class DerivedTransactionException extends Exception {}
    
    private class Mock_SendEmailWork extends ZD_Transaction.SendEmailWork{
        private Boolean doWorkWasCalled = false;
        public override void doWork(){
            doWorkWasCalled = true;
        }
    }
    
    private class MockDBService extends ZD_VirtualCallable{
        protected override Object doCall(String action, Map<String,Object> args){
            switch on action {
                when 'insert' {
                    List<ZD_Record> records = (List<ZD_Record>)args.get('records');
                    for(ZD_Record record : records){
                        record.Id = ZD_Application.util.getFakeId('000');
                        mockedDatabase.get(record.getObjectAPIName()).put(record.Id, record);
                    }
                }
                when 'update' {
                    List<ZD_Record> records = (List<ZD_Record>)args.get('records');
                    for(ZD_Record record : records){
                        if(String.isBlank(record.Id)){
                            throw new TestException('Cannot update a new record');
                        }
                        mockedDatabase.get(record.getObjectAPIName()).put(record.Id, record);
                    }
                }
                when 'delete' {
                    List<ZD_Record> records = (List<ZD_Record>)args.get('records');
                    for(ZD_Record record : records){
                        mockedDatabase.get(record.getObjectAPIName()).remove(record.Id);
                    }
                }
                when 'eventpublish' {
                    List<ZD_Record> records = (List<ZD_Record>)args.get('records');
                    for(ZD_Record record : records){
                        mockedDatabase.get(record.getObjectAPIName()).put(record.Id, record);
                    }
                }
            }
            return null;
        }
    }
    
    class TestException extends Exception{}
}