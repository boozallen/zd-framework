public inherited sharing virtual class ZD_Transaction {
    
    @TestVisible private System.AccessLevel accessLevel;

    protected List<String> m_sObjectTypes = new List<String>();

    @TestVisible protected Map<String, List<ZD_Record>> m_newListByType = new Map<String, List<ZD_Record>>();

    protected Map<String, Map<Id, ZD_Record>> m_dirtyMapByType = new Map<String, Map<Id, ZD_Record>>();

    protected Map<String, Map<Id, ZD_Record>> m_deletedMapByType = new Map<String, Map<Id, ZD_Record>>();
    protected Map<String, Map<Id, ZD_Record>> m_emptyRecycleBinMapByType = new Map<String, Map<Id, ZD_Record>>();

    protected Map<String, Relationships> m_relationships = new Map<String, Relationships>();

    protected Map<String, List<ZD_Record>> m_publishBeforeListByType = new Map<String, List<ZD_Record>>();
    protected Map<String, List<ZD_Record>> m_publishAfterSuccessListByType = new Map<String, List<ZD_Record>>();
    protected Map<String, List<ZD_Record>> m_publishAfterFailureListByType = new Map<String, List<ZD_Record>>();

    @TestVisible
    protected SendEmailWork m_emailWork = new SendEmailWork();

    protected List<IDoWork> m_workList = new List<IDoWork>();

    public static TransactionFactory factory{
        get{
            if(factory == null){
                factory = new TransactionFactory();
            }
            return factory;
        }
        private set;
    }

    public interface IDoWork{
        void doWork();
    }
    
    public void registerWork(IDoWork work){
        m_workList.add(work);
    }

    public ZD_Transaction(List<String> sObjectTypes){
        this(sObjectTypes, System.AccessLevel.USER_MODE);
    }

    protected ZD_Transaction(){

    }
    
    @TestVisible
    private ZD_Transaction(List<String> sObjectTypes, System.AccessLevel accessLevel){
        this.initializeTransaction(sObjectTypes, accessLevel);
    }

    private void initializeTransaction(List<String> sObjectTypes, System.AccessLevel accessLevel){
        this.accessLevel = accessLevel;
        this.m_sObjectTypes = sObjectTypes.clone();
        for (String sObjectType : m_sObjectTypes){
            // register the type
            handleRegisterType(sObjectType);
        }

		m_relationships.put(Messaging.SingleEmailMessage.class.getName(), new Relationships());
    }
    
    private void handleRegisterType(String sObjectName){
        m_newListByType.put(sObjectName, new List<ZD_Record>());
        m_dirtyMapByType.put(sObjectName, new Map<Id, ZD_Record>());
        m_deletedMapByType.put(sObjectName, new Map<Id, ZD_Record>());
	    m_emptyRecycleBinMapByType.put(sObjectName, new Map<Id, ZD_Record>());
        m_relationships.put(sObjectName, new Relationships());

        m_publishBeforeListByType.put(sObjectName, new List<ZD_Record>());
        m_publishAfterSuccessListByType.put(sObjectName, new List<ZD_Record>());
        m_publishAfterFailureListByType.put(sObjectName, new List<ZD_Record>());
    }

    public virtual void onCommitStart() {
        //set the transaction system mode
        ZD_DatabaseService.setAccessLevel(this.accessLevel);
    }
    public virtual void onCommitFinish(Boolean wasSuccessful, Exception caughtException) {
        //restore usermode
        ZD_DatabaseService.setAccessLevel(System.AccessLevel.USER_MODE);
    }

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

    private void doCommit(){
		onCommitStart();
		publishEventsBeforeDML();

		insertDmlByType();
		updateDmlByType();
		deleteDmlByType();
		resolveEmailRelationships();

		doWork();
	}

    private void doWork()
	{
		m_workList.add(m_emailWork);
		for (IDoWork work : m_workList)
		{
			work.doWork();
		}
	}

    private void publishEventsBeforeDML()
	{
		for (String sObjectType : m_sObjectTypes)
		{
			ZD_DatabaseService.eventPublish(m_publishBeforeListByType.get(sObjectType));
		}
	}

    private void insertDmlByType()
	{
		for (String sObjectType : m_sObjectTypes)
		{
			m_relationships.get(sObjectType).resolve();
			ZD_DatabaseService.doInsert(m_newListByType.get(sObjectType));
		}
	}

    private void updateDmlByType()
	{
		for (String sObjectType : m_sObjectTypes)
		{
			ZD_DatabaseService.doUpdate(m_dirtyMapByType.get(sObjectType).values());
		}
	}

    private void deleteDmlByType()
	{
        for (String sObjectType : m_sObjectTypes)
		{
			ZD_DatabaseService.doDelete(m_deletedMapByType.get(sObjectType).values());
		}
	}

    private void publishAfterSuccessEvents()
	{
		for (String sObjectType : m_sObjectTypes)
		{
			ZD_DatabaseService.eventPublish(m_publishAfterSuccessListByType.get(sObjectType));
		}
	}

    private void publishAfterFailureEvents()
	{
		for (String sObjectType : m_sObjectTypes)
		{
			ZD_DatabaseService.eventPublish(m_publishAfterFailureListByType.get(sObjectType));
		}
	}

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

    public void registerNew(SObject record){
        registerNew(new ZD_Record(record), null, null);
    }

    public void registerNew(ZD_Record record){
        registerNew(record, null, null);
    }

    public void registerNew(List<SObject> records){
        for (SObject record : records){
            registerNew(record, null, null);
        }
    }
    
    public void registerNew(List<ZD_Record> records){
        for (ZD_Record record : records){
            registerNew(record, null, null);
        }
    }

    public void registerNew(SObject record, String relatedToParentField, SObject relatedToParentZD_Record){
        registerNew(new ZD_Record(record), relatedToParentField, new ZD_Record(relatedToParentZD_Record));
    }

    public void registerNew(ZD_Record record, String relatedToParentField, ZD_Record relatedToParentZD_Record){
        if (record.Id != null)
            throw new TransactionException('Only new records can be registered as new');
        String sObjectType = record.getObjectAPIName();

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_newListByType, sObjectType);

        m_newListByType.get(sObjectType).add(record);
        if (relatedToParentZD_Record!=null && relatedToParentField!=null)
            registerRelationship(record, relatedToParentField, relatedToParentZD_Record);
    }

    public void registerRelationship(ZD_Record record, String relatedToField, ZD_Record relatedTo){
        String sObjectType = record.getObjectAPIName();

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_newListByType, sObjectType);

        m_relationships.get(sObjectType).add(record, relatedToField, relatedTo);
    }
    
    public void registerRelationship( Messaging.SingleEmailMessage email, SObject relatedTo ){
        registerRelationship(email, new ZD_Record(relatedTo));
    }
    
    public void registerRelationship( Messaging.SingleEmailMessage email, ZD_Record relatedTo ){
        m_relationships.get( Messaging.SingleEmailMessage.class.getName()).add(email, relatedTo);
    }

    public void registerRelationship(SObject record, String relatedToField, SObject relatedTo){
        registerRelationship(new ZD_Record(record), relatedToField, new ZD_Record(relatedTo));
    }

    public void registerDirty(SObject record){
        registerDirty(new ZD_Record(record), new List<String>());
    }

    public void registerDirty(SObject record, List<String> dirtyFields){
        registerDirty(new ZD_Record(record), dirtyFields);
    }

    public void registerDirty(ZD_Record record){
        registerDirty(record, new List<String>());
    }

    public void registerDirty(List<SObject> records, List<String> dirtyFields){
	    for (SObject record : records){
		    registerDirty(record, dirtyFields);
	    }
    }

    public void registerDirty(List<ZD_Record> records, List<String> dirtyFields){
	    for (ZD_Record record : records){
		    registerDirty(record, dirtyFields);
	    }
    }

    public void registerDirty(ZD_Record record, List<String> dirtyFields){
        if (record.Id == null)
            throw new TransactionException('New records cannot be registered as dirty');
        String sObjectType = record.getObjectAPIName();

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_dirtyMapByType, sObjectType);

        // If record isn't registered as dirty, or no dirty fields to drive a merge
        if (!m_dirtyMapByType.get(sObjectType).containsKey(record.Id) || (dirtyFields?.isEmpty() != false)){
            // Register the record as dirty
            m_dirtyMapByType.get(sObjectType).put(record.Id, record);
        }
        else{
            // Update the registered record's fields
            ZD_Record registeredRecord = m_dirtyMapByType.get(sObjectType).get(record.Id);

            for (String dirtyField : dirtyFields) {
                registeredRecord.put(dirtyField, record.get(dirtyField));
            }
            m_dirtyMapByType.get(sObjectType).put(record.Id, registeredRecord);
        }
    }

    public void registerDirty(List<SObject> records){
        for (SObject record : records){
            this.registerDirty(record);
        }
    }

    public void registerUpsert(ZD_Record record)
    {
        if (record.Id == null) {
            registerNew(record, null, null);
        }else{
            registerDirty(record, new List<String>());
        }
    }

    public void registerUpsert(List<ZD_Record> records){
        for (ZD_Record record : records){
            this.registerUpsert(record);
        }
    }

    public void registerUpsert(SObject record)
    {
        if (record.Id == null) {
            registerNew(record, null, null);
        }else{
            registerDirty(record, new List<String>());
        }
    }

    public void registerUpsert(List<SObject> records){
        for (SObject record : records){
            this.registerUpsert(record);
        }
    }

    public void registerPublishBeforeTransaction(ZD_Record record){
        String sObjectType = record.getObjectAPIName();

		assertForEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_publishBeforeListByType, sObjectType);

        m_publishBeforeListByType.get(sObjectType).add(record);
    }

    public void registerPublishBeforeTransaction(List<ZD_Record> records){
        for (ZD_Record record : records){
            this.registerPublishBeforeTransaction(record);
        }
    }

    public void registerPublishBeforeTransaction(SObject record){
        this.registerPublishBeforeTransaction(new ZD_Record(record));
    }

    public void registerPublishBeforeTransaction(List<SObject> records)
    {
        for (SObject record : records){
            this.registerPublishBeforeTransaction(record);
        }
    }

    public void registerPublishAfterSuccessTransaction(ZD_Record record){
        String sObjectType = record.getObjectAPIName();

		assertForEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_publishBeforeListByType, sObjectType);

        m_publishAfterSuccessListByType.get(sObjectType).add(record);
    }

    public void registerPublishAfterSuccessTransaction(List<ZD_Record> records){
        for (ZD_Record record : records){
            this.registerPublishAfterSuccessTransaction(record);
        }
    }

    public void registerPublishAfterSuccessTransaction(SObject record){
        this.registerPublishAfterSuccessTransaction(new ZD_Record(record));
    }

    public void registerPublishAfterSuccessTransaction(List<SObject> records)
    {
        for (SObject record : records){
            this.registerPublishAfterSuccessTransaction(record);
        }
    }

    public void registerPublishAfterFailureTransaction(ZD_Record record){
        String sObjectType = record.getObjectAPIName();

		assertForEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_publishBeforeListByType, sObjectType);

        m_publishAfterFailureListByType.get(sObjectType).add(record);
    }

    public void registerPublishAfterFailureTransaction(List<ZD_Record> records){
        for (ZD_Record record : records){
            this.registerPublishAfterFailureTransaction(record);
        }
    }

    public void registerPublishAfterFailureTransaction(SObject record){
        this.registerPublishAfterFailureTransaction(new ZD_Record(record));
    }

    public void registerPublishAfterFailureTransaction(List<SObject> records)
    {
        for (SObject record : records){
            this.registerPublishAfterFailureTransaction(record);
        }
    }

    public void registerEmail(Messaging.Email email){
        m_emailWork.registerEmail(email);
    }

    public void registerDeleted(ZD_Record record){
        if (record.Id == null)
            throw new TransactionException('New records cannot be registered for deletion');
        String sObjectType = record.getObjectAPIName();

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_deletedMapByType, sObjectType);

        m_deletedMapByType.get(sObjectType).put(record.Id, record);
    }

    public void registerDeleted(SObject record){
            this.registerDeleted(new ZD_Record(record));
    }


    public void registerDeleted(List<SObject> records){
        for (SObject record : records){
            this.registerDeleted(record);
        }
    }

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
		m_relationships.get(Messaging.SingleEmailMessage.class.getName()).resolve();
	}

    private class Relationships
    {
        private List<IRelationship> m_relationships = new List<IRelationship>();

        public void resolve()
        {
            // Resolve relationships
            for (IRelationship relationship : m_relationships)
            {
                //relationship.ZD_Record.put(relationship.RelatedToField, relationship.RelatedTo.Id);
                relationship.resolve();
            }

        }

        public void add(ZD_Record record, String relatedToField, ZD_Record relatedTo)
        {
            // Relationship to resolve
            RecordRelationship relationship = new RecordRelationship();
            relationship.record = record;
            relationship.relatedToField = relatedToField;
            relationship.relatedTo = relatedTo;
            m_relationships.add(relationship);
        }

        public void add(Messaging.SingleEmailMessage email, ZD_Record relatedTo)
        {
            EmailRelationship emailRelationship = new EmailRelationship();
            emailRelationship.email = email;
            emailRelationship.relatedTo = relatedTo;
            m_relationships.add(emailRelationship);
        }
    }

    private interface IRelationship
    {
        void resolve();
    }

    private class RecordRelationship implements IRelationship
    {
        public ZD_Record record;
        public String relatedToField;
        public ZD_Record relatedTo;

        public void resolve()
        {
            this.record.put( this.relatedToField, this.relatedTo.Id);
        }
    }

    private class EmailRelationship implements IRelationship
    {
        public Messaging.SingleEmailMessage email;
        public ZD_Record relatedTo;

        public void resolve()
        {
            this.email.setWhatId( this.relatedTo.Id );
        }
    }

    public virtual class SendEmailWork implements IDoWork
    {
        private List<Messaging.Email> emails;

        public SendEmailWork()
        {
            this.emails = new List<Messaging.Email>();
        }

        public virtual void registerEmail(Messaging.Email email)
        {
            this.emails.add(email);
        }

        public virtual void doWork()
        {
            if (emails.size() > 0) Messaging.sendEmail(emails);
        }
    }

    public class TransactionException extends Exception {}

    public with sharing class TransactionFactory{
        @TestVisible private Map<String, Map<System.AccessLevel,ZD_Transaction>> transactionMap = new Map<String, Map<System.AccessLevel,ZD_Transaction>>();

        private TransactionFactory(){
            
        }
        public ZD_Transaction getInstance(String applicationName, List<String> sObjectTypes){
            return getInstance(applicationName, sObjectTypes, System.AccessLevel.USER_MODE, null);
        }

        public ZD_Transaction getInstance(String applicationName, List<String> sObjectTypes, String type){
            return getInstance(applicationName, sObjectTypes, System.AccessLevel.USER_MODE, type);
        }
        
        public ZD_Transaction getInstance(String applicationName, List<String> sObjectTypes, System.AccessLevel accessLevel){
            return getInstance(applicationName, sObjectTypes, accessLevel, null);
        }

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