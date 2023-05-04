/**
 * @description transaction management class
 * This software package is licensed under the Booz Allen Public License. 
 * Portions of this code are Copyright © 2023 FinancialForce.com, Inc. All Rights Reserved.
 * 
 * @author Jonathan Devlin
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.ExcessiveParameterList, PMD.EmptyStatementBlock')
public inherited sharing virtual class ZD_Transaction {
    
    @TestVisible private System.AccessLevel accessLevel;

    protected List<String> sObjectTypes = new List<String>();

    @TestVisible protected Map<String, List<ZD_Record>> newListByType = new Map<String, List<ZD_Record>>();

    protected Map<String, Map<Id, ZD_Record>> dirtyMapByType = new Map<String, Map<Id, ZD_Record>>();

    protected Map<String, Map<Id, ZD_Record>> deletedMapByType = new Map<String, Map<Id, ZD_Record>>();
    protected Map<String, Map<Id, ZD_Record>> emptyRecycleBinMapByType = new Map<String, Map<Id, ZD_Record>>();

    protected Map<String, Relationships> relationships = new Map<String, Relationships>();

    protected Map<String, List<ZD_Record>> publishBeforeListByType = new Map<String, List<ZD_Record>>();
    protected Map<String, List<ZD_Record>> publishAfterSuccessListByType = new Map<String, List<ZD_Record>>();
    protected Map<String, List<ZD_Record>> publishAfterFailureListByType = new Map<String, List<ZD_Record>>();

    @TestVisible
    protected SendEmailWork emailWork = new SendEmailWork();

    protected List<IDoWork> workList = new List<IDoWork>();

    /**
     * @description factory to get transactions from
     */
    public static TransactionFactory factory{
        get{
            if(factory == null){
                factory = new TransactionFactory();
            }
            return factory;
        }
        private set;
    }

    /**
     * @description interface to do work
     */
    public interface IDoWork{

        /**
         * @description method to override and do something (execute work)
         */
        void doWork();
    }
    
    /**
     * @description adds an IDoWork instance to the worklist
     * @param work - IDoWork implementation instance to add
     */
    public void registerWork(IDoWork work){
        workList.add(work);
    }

    /**
     * @description standard constructor to create a transaction
     * @param sObjectTypes - list of sobjects to operate on
     */
    public ZD_Transaction(List<String> sObjectTypes){
        this(sObjectTypes, System.AccessLevel.USER_MODE);
    }

    /**
     * @description only accessible within this class/subclass
     */
    protected ZD_Transaction(){
        //prevents dynamic type instantiation
    }
    
    /**
     * @description constructor with sobject types and a specified accessLevel
     * @param sObjectTypes - list of objects to operate on
     * @param accessLevel - accessLevel of the transaction
     */
    @TestVisible
    private ZD_Transaction(List<String> sObjectTypes, System.AccessLevel accessLevel){
        this.initializeTransaction(sObjectTypes, accessLevel);
    }

    /**
     * @description initializes the transactions by setting the variables and registering the object types
     * @param sObjectTypes - list of objects to operate on
     * @param accessLevel - accessLevel of the transaction
     */
    private void initializeTransaction(List<String> sObjectTypes, System.AccessLevel accessLevel){
        this.accessLevel = accessLevel;
        this.sObjectTypes = sObjectTypes.clone();
        for (String sObjectType : sObjectTypes){
            // register the type
            handleRegisterType(sObjectType);
        }
		relationships.put(Messaging.SingleEmailMessage.class.getName(), new Relationships());
    }
    
    /**
     * @description adds the sobject api name to all of the maps/lists
     * @param sObjectName - object name to register
     */
    private void handleRegisterType(String sObjectName){
        newListByType.put(sObjectName, new List<ZD_Record>());
        dirtyMapByType.put(sObjectName, new Map<Id, ZD_Record>());
        deletedMapByType.put(sObjectName, new Map<Id, ZD_Record>());
	    emptyRecycleBinMapByType.put(sObjectName, new Map<Id, ZD_Record>());
        relationships.put(sObjectName, new Relationships());

        publishBeforeListByType.put(sObjectName, new List<ZD_Record>());
        publishAfterSuccessListByType.put(sObjectName, new List<ZD_Record>());
        publishAfterFailureListByType.put(sObjectName, new List<ZD_Record>());
    }

    /**
     * @description sets the database service access level to this transactions access level
     */
    public virtual void onCommitStart() {
        //set the transaction system mode
        ZD_DatabaseService.setAccessLevel(this.accessLevel);
    }

    /**
     * @description sets the database service access level back to user mode
     * @param wasSuccessful - indicating if the transaction was successful or not
     * @param caughtException - caught exception from committing the transaction
     */
    public virtual void onCommitFinish(Boolean wasSuccessful, Exception caughtException) {
        //restore usermode
        ZD_DatabaseService.setAccessLevel(System.AccessLevel.USER_MODE);
    }

    /**
     * @description tries to commit the transaction to the database
     */
    public void commitTransaction(){
		Savepoint sp = Database.setSavepoint();
        Exception caughtException;
		Boolean wasSuccessful = false;
		try
		{
			doCommit();
			wasSuccessful = true;
		}
		catch (Exception e)
		{
			Database.rollback(sp);
            caughtException = e;
			throw e;
		}
		finally
		{
			doAfterCommit(wasSuccessful, caughtException);
		}
	}

    /**
     * @description does the actual commit methods
     */
    private void doCommit(){
		onCommitStart();
		publishEventsBeforeDML();

		insertDmlByType();
		updateDmlByType();
		deleteDmlByType();
		resolveEmailRelationships();

		doWork();
	}

    /**
     * @description executes all the IDoWork instances in the workList
     */
    private void doWork()
	{
		workList.add(emailWork);
		for (IDoWork work : workList)
		{
			work.doWork();
		}
	}

    /**
     * @description publish the events before dml
     */
    private void publishEventsBeforeDML()
	{
		for (String sObjectType : sObjectTypes)
		{
			ZD_DatabaseService.eventPublish(publishBeforeListByType.get(sObjectType));
		}
	}

    /**
     * @description handles all the insert dml
     */
    private void insertDmlByType()
	{
		for (String sObjectType : sObjectTypes)
		{
			relationships.get(sObjectType).resolve();
			ZD_DatabaseService.doInsert(newListByType.get(sObjectType));
		}
	}

    /**
     * @description handles all the update dml
     */
    private void updateDmlByType()
	{
		for (String sObjectType : sObjectTypes)
		{
			ZD_DatabaseService.doUpdate(dirtyMapByType.get(sObjectType).values());
		}
	}

    /**
     * @description handles all the delete dml
     */
    private void deleteDmlByType()
	{
        for (String sObjectType : sObjectTypes)
		{
			ZD_DatabaseService.doDelete(deletedMapByType.get(sObjectType).values());
		}
	}

    /**
     * @description publishes events if successful
     */
    private void publishAfterSuccessEvents()
	{
		for (String sObjectType : sObjectTypes)
		{
			ZD_DatabaseService.eventPublish(publishAfterSuccessListByType.get(sObjectType));
		}
	}

    /**
     * @description publishes events if transaction fails
     */
    private void publishAfterFailureEvents()
	{
		for (String sObjectType : sObjectTypes)
		{
			ZD_DatabaseService.eventPublish(publishAfterFailureListByType.get(sObjectType));
		}
	}

    /**
     * @description publishes events and executes doCommitFinish
     * @param wasSuccessful - indicating if the transaction was successful or not
     * @param caughtException - caught exception from committing the transaction
     */
    private void doAfterCommit(Boolean wasSuccessful, Exception caughtException){
		if (wasSuccessful)
		{
			publishAfterSuccessEvents();
		}
		else
		{
			publishAfterFailureEvents();
		}
		onCommitFinish(wasSuccessful, caughtException);
	}

    /**
     * @description overloaded method that registers a new sobject to the transaction
     * @param record - record to register to the transaction
     */
    public void registerNew(SObject record){
        registerNew(new ZD_Record(record), null, null);
    }

    /**
     * @description overloaded method that registers a new zd record to the transaction
     * @param record - record to register to the transaction
     */
    public void registerNew(ZD_Record record){
        registerNew(record, null, null);
    }

    /**
     * @description overloaded method that registers a new list of sobjects to the transaction
     * @param records - records to register to the transaction
     */
    public void registerNew(List<SObject> records){
        for (SObject record : records){
            registerNew(record, null, null);
        }
    }
    
     /**
     * @description overloaded method that registers a new list of zd records to the transaction
     * @param records - records to register to the transaction
     */
    public void registerNew(List<ZD_Record> records){
        for (ZD_Record record : records){
            registerNew(record, null, null);
        }
    }

     /**
     * @description overloaded method that registers a sobject with a relationship in the transaction
     * @param record - record to register to the transaction
     * @param relatedToParentField - relationship field
     * @param relatedToParentRecord - parent record
     */
    public void registerNew(SObject record, String relatedToParentField, SObject relatedToParentRecord){
        registerNew(new ZD_Record(record), relatedToParentField, new ZD_Record(relatedToParentRecord));
    }

    /**
     * @description overloaded method that registers a zd record with a relationship in the transaction
     * @param record - record to register to the transaction
     * @param relatedToParentField - relationship field
     * @param relatedToParentRecord - parent record
     */
    public void registerNew(ZD_Record record, String relatedToParentField, ZD_Record relatedToParentRecord){
        if (record.Id != null){
            throw new TransactionException('Only new records can be registered as new');
        }
        String sObjectType = record.getObjectAPIName();

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(newListByType, sObjectType);

        newListByType.get(sObjectType).add(record);
        if (relatedToParentRecord!=null && relatedToParentField!=null){
            registerRelationship(record, relatedToParentField, relatedToParentRecord);
        }
    }

    /**
     * @description registers record relationship
     * @param record - record to register to the transaction
     * @param relatedToField - relationship field
     * @param relatedTo - related record
     */
    public void registerRelationship(ZD_Record record, String relatedToField, ZD_Record relatedTo){
        String sObjectType = record.getObjectAPIName();

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(newListByType, sObjectType);

        relationships.get(sObjectType).add(record, relatedToField, relatedTo);
    }
    
    /**
     * @description registers record email relationship
     * @param email - email to send
     * @param relatedTo - related record
     */
    public void registerRelationship( Messaging.SingleEmailMessage email, SObject relatedTo ){
        registerRelationship(email, new ZD_Record(relatedTo));
    }
    
    /**
     * @description registers record email relationship
     * @param email - email to send
     * @param relatedTo - related record
     */
    public void registerRelationship( Messaging.SingleEmailMessage email, ZD_Record relatedTo ){
        relationships.get( Messaging.SingleEmailMessage.class.getName()).add(email, relatedTo);
    }

    /**
     * @description registers record relationship
     * @param record - record to register to the transaction
     * @param relatedToField - relationship field
     * @param relatedTo - related record
     */
    public void registerRelationship(SObject record, String relatedToField, SObject relatedTo){
        registerRelationship(new ZD_Record(record), relatedToField, new ZD_Record(relatedTo));
    }

    /**
     * @description registers record for update
     * @param record - record to register to the transaction
     */
    public void registerDirty(SObject record){
        registerDirty(new ZD_Record(record), new List<String>());
    }

    /**
     * @description registers record for update
     * @param record - record to register to the transaction
     * @param dirtyFields - fields that are updated
     */
    public void registerDirty(SObject record, List<String> dirtyFields){
        registerDirty(new ZD_Record(record), dirtyFields);
    }

    /**
     * @description registers record for update
     * @param record - record to register to the transaction
     */
    public void registerDirty(ZD_Record record){
        registerDirty(record, new List<String>());
    }

    /**
     * @description registers records for update
     * @param records - record to register to the transaction
     * @param dirtyFields - fields that are updated
     */
    public void registerDirty(List<SObject> records, List<String> dirtyFields){
	    for (SObject record : records){
		    registerDirty(record, dirtyFields);
	    }
    }

    /**
     * @description registers record for update
     * @param records - list of records to register to the transaction
     * @param dirtyFields - fields that are updated
     */
    public void registerDirty(List<ZD_Record> records, List<String> dirtyFields){
	    for (ZD_Record record : records){
		    registerDirty(record, dirtyFields);
	    }
    }

    /**
     * @description registers record for update
     * @param record - record to register to the transaction
     * @param dirtyFields - fields that are updated
     */
    public void registerDirty(ZD_Record record, List<String> dirtyFields){
        if (record.Id == null){
            throw new TransactionException('New records cannot be registered as dirty');
        }
        String sObjectType = record.getObjectAPIName();

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(dirtyMapByType, sObjectType);

        // If record isn't registered as dirty, or no dirty fields to drive a merge
        if (!dirtyMapByType.get(sObjectType).containsKey(record.Id) || (dirtyFields?.isEmpty() != false)){
            // Register the record as dirty
            dirtyMapByType.get(sObjectType).put(record.Id, record);
        }
        else{
            // Update the registered record's fields
            ZD_Record registeredRecord = dirtyMapByType.get(sObjectType).get(record.Id);

            for (String dirtyField : dirtyFields) {
                registeredRecord.put(dirtyField, record.get(dirtyField));
            }
            dirtyMapByType.get(sObjectType).put(record.Id, registeredRecord);
        }
    }

    /**
     * @description registers records for update
     * @param records - records to register to the transaction
     */
    public void registerDirty(List<SObject> records){
        for (SObject record : records){
            this.registerDirty(record);
        }
    }

    /**
     * @description registers record for upsert (more accuratelly sets it as new or dirty)
     * @param record - record to register to the transaction
     */
    public void registerUpsert(ZD_Record record)
    {
        if (record.Id == null) {
            registerNew(record, null, null);
        }else{
            registerDirty(record, new List<String>());
        }
    }

    /**
     * @description registers records for upsert (more accuratelly sets it as new or dirty)
     * @param records - records to register to the transaction
     */
    public void registerUpsert(List<ZD_Record> records){
        for (ZD_Record record : records){
            this.registerUpsert(record);
        }
    }

    /**
     * @description registers record for upsert (more accuratelly sets it as new or dirty)
     * @param record - record to register to the transaction
     */
    public void registerUpsert(SObject record)
    {
        if (record.Id == null) {
            registerNew(record, null, null);
        }else{
            registerDirty(record, new List<String>());
        }
    }

    /**
     * @description registers record for upsert (more accuratelly sets it as new or dirty)
     * @param records - records to register to the transaction
     */
    public void registerUpsert(List<SObject> records){
        for (SObject record : records){
            this.registerUpsert(record);
        }
    }

    /**
     * @description registers record to publish pre commit
     * @param record - event to register to the transaction
     */
    public void registerPublishBeforeTransaction(ZD_Record record){
        String sObjectType = record.getObjectAPIName();

		assertForEventSObjectType(sObjectType);
		assertForSupportedSObjectType(publishBeforeListByType, sObjectType);

        publishBeforeListByType.get(sObjectType).add(record);
    }

    /**
     * @description registers records to publish pre commit
     * @param records - events to register to the transaction
     */
    public void registerPublishBeforeTransaction(List<ZD_Record> records){
        for (ZD_Record record : records){
            this.registerPublishBeforeTransaction(record);
        }
    }

     /**
     * @description registers record to publish pre commit
     * @param record - event to register to the transaction
     */
    public void registerPublishBeforeTransaction(SObject record){
        this.registerPublishBeforeTransaction(new ZD_Record(record));
    }

     /**
     * @description registers record to publish pre commit
     * @param records - events to register to the transaction
     */
    public void registerPublishBeforeTransaction(List<SObject> records)
    {
        for (SObject record : records){
            this.registerPublishBeforeTransaction(record);
        }
    }

     /**
     * @description registers record to publish post commit success
     * @param record - event to register to the transaction
     */
    public void registerPublishAfterSuccessTransaction(ZD_Record record){
        String sObjectType = record.getObjectAPIName();

		assertForEventSObjectType(sObjectType);
		assertForSupportedSObjectType(publishBeforeListByType, sObjectType);

        publishAfterSuccessListByType.get(sObjectType).add(record);
    }

     /**
     * @description registers records to publish post commit success
     * @param records - events to register to the transaction
     */
    public void registerPublishAfterSuccessTransaction(List<ZD_Record> records){
        for (ZD_Record record : records){
            this.registerPublishAfterSuccessTransaction(record);
        }
    }

     /**
     * @description registers record to publish post commit success
     * @param record - event to register to the transaction
     */
    public void registerPublishAfterSuccessTransaction(SObject record){
        this.registerPublishAfterSuccessTransaction(new ZD_Record(record));
    }

     /**
     * @description registers records to publish post commit success
     * @param records - events to register to the transaction
     */
    public void registerPublishAfterSuccessTransaction(List<SObject> records)
    {
        for (SObject record : records){
            this.registerPublishAfterSuccessTransaction(record);
        }
    }

     /**
     * @description registers record to publish post commit failure
     * @param record - event to register to the transaction
     */
    public void registerPublishAfterFailureTransaction(ZD_Record record){
        String sObjectType = record.getObjectAPIName();

		assertForEventSObjectType(sObjectType);
		assertForSupportedSObjectType(publishBeforeListByType, sObjectType);

        publishAfterFailureListByType.get(sObjectType).add(record);
    }

    /**
     * @description registers records to publish post commit failure
     * @param records - events to register to the transaction
     */
    public void registerPublishAfterFailureTransaction(List<ZD_Record> records){
        for (ZD_Record record : records){
            this.registerPublishAfterFailureTransaction(record);
        }
    }

    /**
     * @description registers record to publish post commit failure
     * @param record - event to register to the transaction
     */
    public void registerPublishAfterFailureTransaction(SObject record){
        this.registerPublishAfterFailureTransaction(new ZD_Record(record));
    }

    /**
     * @description registers records to publish post commit failure
     * @param records - events to register to the transaction
     */
    public void registerPublishAfterFailureTransaction(List<SObject> records)
    {
        for (SObject record : records){
            this.registerPublishAfterFailureTransaction(record);
        }
    }

    /**
     * @description registers email to go out post transaction
     * @param email - email to register to the transaction
     */
    public void registerEmail(Messaging.Email email){
        emailWork.registerEmail(email);
    }

    /**
     * @description registers record to delete in transaction
     * @param record - record to register to the transaction
     */
    public void registerDeleted(ZD_Record record){
        if (record.Id == null){
            throw new TransactionException('New records cannot be registered for deletion');
        }
        String sObjectType = record.getObjectAPIName();

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(deletedMapByType, sObjectType);

        deletedMapByType.get(sObjectType).put(record.Id, record);
    }

    /**
     * @description registers record to delete in transaction
     * @param record - record to register to the transaction
     */
    public void registerDeleted(SObject record){
            this.registerDeleted(new ZD_Record(record));
    }

    /**
     * @description registers records to delete in transaction
     * @param records - records to register to the transaction
     */
    public void registerDeleted(List<SObject> records){
        for (SObject record : records){
            this.registerDeleted(record);
        }
    }

    /**
     * @description registers records to delete in transaction
     * @param records - records to register to the transaction
     */
    public void registerDeleted(List<ZD_Record> records){
        for (ZD_Record record : records){
            this.registerDeleted(record);
        }
    }

    @TestVisible
	private void assertForSupportedSObjectType(Map<String, Object> theMap, String sObjectType){
		if (!theMap.containsKey(sObjectType))
		{
			throw new TransactionException(
					String.format(
							'SObject type {0} is not supported by this transaction',
							new List<String> { sObjectType }
					)
			);
		}
	}

    @TestVisible
	private void assertForNonEventSObjectType(String sObjectType){
		if (sObjectType.length() > 3 && sObjectType.right(3)  == '__e')
		{
			throw new TransactionException(
					String.format(
							'SObject type {0} must use registerPublishBeforeTransaction or ' +
									'registerPublishAfterTransaction methods to be used within this transaction',
							new List<String> { sObjectType }
					)
			);
		}
	}

    @TestVisible
	private void assertForEventSObjectType(String sObjectType)
	{
		if (sObjectType.length() > 3 && sObjectType.right(3) != '__e')
		{
			throw new TransactionException(
					String.format(
							'SObject type {0} is invalid for publishing within this transaction',
							new List<String> {sObjectType}
					)
			);
		}
	}

    private void resolveEmailRelationships()
	{
		relationships.get(Messaging.SingleEmailMessage.class.getName()).resolve();
	}

    /**
     * @description models relationships
     */
    private class Relationships
    {
        private List<IRelationship> relationships = new List<IRelationship>();

        /**
         * @description links all of the relationships
         */
        public void resolve()
        {
            // Resolve relationships
            for (IRelationship relationship : relationships)
            {
                //relationship.ZD_Record.put(relationship.RelatedToField, relationship.RelatedTo.Id);
                relationship.resolve();
            }

        }

        /**
         * @description registers record relationship
         * @param record - record to relate
         * @param relatedToField - field representing the relationship
         * @param relatedTo - record related to the original record
         */
        public void add(ZD_Record record, String relatedToField, ZD_Record relatedTo)
        {
            // Relationship to resolve
            RecordRelationship relationship = new RecordRelationship();
            relationship.record = record;
            relationship.relatedToField = relatedToField;
            relationship.relatedTo = relatedTo;
            relationships.add(relationship);
        }

        /**
         * @description registers record relationship in email
         * @param email - email to send
         * @param relatedTo - record related to the original record
         */
        public void add(Messaging.SingleEmailMessage email, ZD_Record relatedTo)
        {
            EmailRelationship emailRelationship = new EmailRelationship();
            emailRelationship.email = email;
            emailRelationship.relatedTo = relatedTo;
            relationships.add(emailRelationship);
        }
    }

    /**
     * @description models relationships and allows them to be resolved on commit
     */
    private interface IRelationship
    {
        /**
         * @description how to actually relate items
         */
        void resolve();
    }

    /**
     * @description models a record relationship
     */
    private class RecordRelationship implements IRelationship
    {
        /**
         * @description original record
         */
        public ZD_Record record;
        /**
         * @description field that holds the relationship
         */
        public String relatedToField;
        /**
         * @description related record
         */
        public ZD_Record relatedTo;

        /**
         * @description sets the relationship field
         */
        public void resolve()
        {
            this.record.put( this.relatedToField, this.relatedTo.Id);
        }
    }

    private class EmailRelationship implements IRelationship
    {
        /**
         * @description email to send
         */
        public Messaging.SingleEmailMessage email;
        /**
         * @description related record to the email
         */
        public ZD_Record relatedTo;

        /**
         * @description sets the related record to the email via what id
         */
        public void resolve()
        {
            this.email.setWhatId( this.relatedTo.Id );
        }
    }

    /**
     * @description IDoWork implementation that sends emails
     */
    public virtual class SendEmailWork implements IDoWork
    {
        private List<Messaging.Email> emails;

        /**
         * @description constructor
         */
        public SendEmailWork()
        {
            this.emails = new List<Messaging.Email>();
        }

        /**
         * @description registers an email to send on commit
         * @param email - email to register to transaction
         */
        public virtual void registerEmail(Messaging.Email email)
        {
            this.emails.add(email);
        }

        /**
         * @description sends the email
         */
        public virtual void doWork()
        {
            if (emails.size() > 0){ Messaging.sendEmail(emails);}
        }
    }

    /**
     * @description exception class
     */
    public class TransactionException extends Exception {}

    /**
     * @description transaction factory that holds the transactions for various apps and access levels
     */
    public with sharing class TransactionFactory{
        @TestVisible private Map<String, Map<System.AccessLevel,ZD_Transaction>> transactionMap = new Map<String, Map<System.AccessLevel,ZD_Transaction>>();

        /**
         * @description cant instantiate outside of this class
         */
        private TransactionFactory(){
            
        }

        /**
         * @description models relationships and allows them to be resolved on commit
         * @param applicationName - name of the app 
         * @param sObjectTypes - list of objects this transaction will operate on
         * @return a transaction instance (new or existing) from the factory
         */
        public ZD_Transaction getInstance(String applicationName, List<String> sObjectTypes){
            return getInstance(applicationName, sObjectTypes, System.AccessLevel.USER_MODE, null);
        }

        /**
         * @description models relationships and allows them to be resolved on commit
         * @param applicationName - name of the app 
         * @param sObjectTypes - list of objects this transaction will operate on
         * @param type - class name of the transaction type
         * @return a transaction instance (new or existing) from the factory
         */
        public ZD_Transaction getInstance(String applicationName, List<String> sObjectTypes, String type){
            return getInstance(applicationName, sObjectTypes, System.AccessLevel.USER_MODE, type);
        }
        
        /**
         * @description models relationships and allows them to be resolved on commit
         * @param applicationName - name of the app 
         * @param sObjectTypes - list of objects this transaction will operate on
         * @param accessLevel - access level of the transaction
         * @return a transaction instance (new or existing) from the factory
         */
        public ZD_Transaction getInstance(String applicationName, List<String> sObjectTypes, System.AccessLevel accessLevel){
            return getInstance(applicationName, sObjectTypes, accessLevel, null);
        }

        /**
         * @description models relationships and allows them to be resolved on commit
         * @param applicationName - name of the app 
         * @param sObjectTypes - list of objects this transaction will operate on
         * @param accessLevel - access level of the transaction
         * @param transactionClassName - class name of the transaction type
         * @return a transaction instance (new or existing) from the factory
         */
        public ZD_Transaction getInstance(String applicationName, List<String> sObjectTypes, System.AccessLevel accessLevel, String transactionClassName){
            if(!transactionMap.containsKey(applicationName) || !transactionMap.get(applicationName).containsKey(accessLevel)){
                ZD_Transaction zdt = transactionClassName != null ? (ZD_Transaction) Type.forName(transactionClassName).newInstance() : new ZD_Transaction();
                zdt.initializeTransaction(sObjectTypes, accessLevel);
                transactionMap.put(applicationName, new Map<System.AccessLevel, ZD_Transaction>{
                    accessLevel => zdt
                });
            }
            return transactionMap.get(applicationName).get(accessLevel);
        }

    }
    
}