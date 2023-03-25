/**
 * This class contains unit tests for validating the Trending & Reporting classes
 */

@isTest(SeeAllData = true)
private class Test_Reporting
{
    
    static testMethod void testInitializationFunctions()
    {
        Test.startTest();
        try
        {
            List<ReportingObjects.filterObject> filters = new List<ReportingObjects.filterObject>();
            
            ReportingObjects.filterObject filter = new ReportingObjects.filterObject();
            filter.name = 'Name';
            filter.type = 'DateTime-Local';
            filter.filter = 'Case.CreatedDate';
            filters.add(filter.clone());
            
            filter.type = 'Recency';
            filter.value = '29';
            filter.filter = 'Case.CreatedDate';
            filter.entries.add(new ReportingObjects.filterEntry('0', 'Today'));
            filters.add(filter.clone());
            
            filter.type = 'Record List';
            filter.object_type = 'User';
            filter.value = 'Id';
            filter.label = 'Name';
            filter.order = 'Name';
            filter.name = 'Case Owner';
            filter.filters = new ReportingObjects.filterFilter[]{new ReportingObjects.filterFilter('Case','OwnerId','in')};
            filter.whereClause = 'IsActive = true AND Profile.Name != \'System Administrator\'';
            filters.add(filter.clone());
            
            filter.type = 'Reference';
            filter.name = 'Record Owner';
            filter.object_type = 'Case Owner';
            filter.filter = 'Case.OwnerId';
            filters.add(filter.clone());
            
            filter.type = 'Picklist';
            filter.object_type = 'Case';
            filter.field_name = 'Type';
            filter.filter = 'Case.Type';
            filters.add(filter.clone());
            
            filter.type = 'Record Type';
            filter.object_type = 'Case';
            filter.filter = 'Case.RecordTypeId';
            filters.add(filter.clone());
            
            filter.type = 'Manual';
            filter.filter = 'Case.IsClosed';
            filter.entries.add(new ReportingObjects.filterEntry('false', 'Open'));
            filter.entries.add(new ReportingObjects.filterEntry('true', 'Closed'));
            filters.add(filter.clone());
            
            filter.type = 'Toggle';
            filter.filter = 'gimmeAll';
            filters.add(filter.clone());
            
            ReportingObjects.FilterInput fI = new ReportingObjects.FilterInput();
            fI.filterList = filters;
            String tossit = Reporting.InitializeFilters(JSON.serialize(fI));
        }
        catch (System.dmlException e)
        {
            System.debug('DML Exception Executing Trending Class Tests: ' + e.getDmlMessage(0));
            throw e;
        }
        Test.stopTest();
    }
      
    static testMethod void testTrendingFunctions()
    {
        Test.startTest();
        try
        {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            Account a = createAccount();
            insert a;
            
            List<Case> cases = new List<Case>();
            Case case1 = createCase(a.Id, 'Test 1', 'New');
            cases.add(case1);
            insert cases;

            ReportingObjects.ReportInput testInputs = new ReportingObjects.ReportInput();
            testInputs.startDatestr = '2017-01-01T00:00:00Z';
            testInputs.endDatestr = '2019-01-02T23:59:59Z';
            
            testInputs.objType = 'Case';
            testInputs.whereClause = 'CreatedDate >= LAST_N_DAYS:365';
            String tossout = Reporting.OpenedVsClosed(JSON.serialize(testInputs));
            
            testInputs.objType = 'Task';
            tossout = Reporting.OpenedVsClosed(JSON.serialize(testInputs));
            
            testInputs.objType = 'EmailMessage';
            tossout = Reporting.OpenedVsClosed(JSON.serialize(testInputs));
            
            
            testInputs.objType = 'Case';
            testInputs.groupClause = 'Status';
            testInputs.whereClause = 'CreatedDate >= LAST_N_DAYS:365';
            testInputs.maxResults = 10;
            testInputs.lowerThreshold = -1;
            tossout = Reporting.FilterBy(JSON.serialize(testInputs));
            tossout = Reporting.GroupBy(JSON.serialize(testInputs));
            
            testInputs.maxResults = null;
            testInputs.lowerThreshold = null;
            testInputs.groupClause = 'AccountId';
            testInputs.forceValues = new String[]{'001c%', '001d%', '*Other'};
            testInputs.comparisonOperator = 'like';
            testInputs.aggregateField = 'x3st_reports__Age_Days__c';
            tossout = Reporting.FilterBy(JSON.serialize(testInputs));
            
            testInputs.objType = 'Task';
            testInputs.groupClause = 'WhatId';
            testInputs.comparisonOperator = '=';
            testInputs.aggregateField = '';
            testInputs.whereClause = 'CreatedDate >= LAST_N_DAYS:365';
            tossout = Reporting.FilterBy(JSON.serialize(testInputs));
            
            testInputs.xField = 'Month_Closed__c';
            testInputs.orderClause = 'x3st_reports__Month_Closed__c';
            testInputs.groupClause = 'x3st_reports__Month_Closed__c';
            testInputs.yFields = new String[]{'x3st_reports__Age_Days__c'};
            testInputs.aggregateFunction = 'AVG';
            testInputs.objType = 'Case';
            tossout = Reporting.TrendData(JSON.serialize(new ReportingObjects.ReportInput[]{testInputs}));
            
            testInputs.aggregateField = 'x3st_reports__Age_Days__c';
            testInputs.label = 'test';
            testInputs.groupClause = '';
            testInputs.orderClause = '';
            testInputs.whereClause = 'CreatedDate >= LAST_N_DAYS:365';
            List<List<ReportingObjects.ReportInput>> grid = new List<List<ReportingObjects.ReportInput>>();
            grid.add(new ReportingObjects.ReportInput[]{testInputs.clone(), testInputs.clone(), testInputs.clone(), testInputs.clone()});
            
            grid[0][0].chartType = 'label';
            grid[0][1].chartType = 'count';
            grid[0][2].chartType = '';
            grid[0][3].chartType = 'skipeverything';
            
            tossout = Reporting.GenerateGrid(JSON.serialize(grid));
            
        }
        catch (System.dmlException e)
        {
            System.debug('DML Exception Executing Trending Class Tests: ' + e.getDmlMessage(0));
            throw e;
        }
        Test.stopTest();

    }
    
    
    static testMethod void testRecordReturnFunctions()
    {

        Test.startTest();
        try
        {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            Account a = createAccount();
            insert a;
            //New//Awaiting Scope//Awaiting Development//Closed
            List<Case> cases = new List<Case>();

            Case case1 = createCase(a.Id, 'Test 1', 'Opened');
            cases.add(case1);
            Case case2 = createCase(a.Id, 'Test 1', 'Cumulative Open');
            cases.add(case2);
            Case case3 = createCase(a.Id, 'Test 1', 'New');
            cases.add(case3);
            insert cases;

            List<Task> tasks = new List<Task>();
            Task task1 = createTask('Test', 'New', '');
            task1.Status = 'Closed';
            tasks.add(task1);
            Task task2 = createTask('Test2', 'New', '');
            task2.Status = 'Deferred';
            tasks.add(task2);
            insert tasks;
            
            ReportingObjects.ReportInput testInputs = new ReportingObjects.ReportInput();
            
            testInputs.objType = 'Case';
            testInputs.selectClause = 'Status';
            testInputs.whereClause = 'CreatedDate >= LAST_N_DAYS:14';
            string tossout = Reporting.ReturnRecordList(JSON.serialize(testInputs));
            
            testInputs.objType = 'Task';
            testInputs.whereClause = 'CreatedDate >= LAST_N_DAYS:14';
            testInputs.orderClause = 'Id';
            tossout = Reporting.ReturnRecordList(JSON.serialize(testInputs));

        }
        catch (System.dmlException e)
        {
            System.debug('DML Exception Executing Trending Class Tests: ' + e.getDmlMessage(0));
            throw e;
        }
        Test.stopTest();

    }
    
    /*
     * Create a basic User sObject
     */
    public static User createUser(Profile profile) {
        return createUser(profile, 'testuser@place.com.usertest');
    }
    
    /*
     * Create a basic User sObject with a specified Username
     */
    public static User createUser(Profile profile, String username) {
        return new User(
            ProfileId = profile.Id,
            Username = username,
            IsActive = true,
            Alias = 'testuser',
            Email = 'testuser@place.com.usertest',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_CA',
            TimeZoneSidKey = 'America/New_York'
        );
    }
    
    /*
     * Create a list of basic User sObjects
     */
    public static List<User> createUserList(Integer numUsers) {
        List<User> userList = new List<User>();
        for (Integer i = 0; i < numUsers; i++) {
            String username = 'testuser' + i + '@place.com.usertest';
            userList.add(createUser(getProfile(), username));
        }
        return userList;
    }
    
    /*
     * Create a basic Account sObject
     */
    public static Account createAccount() {
        return new Account(
            AccountNumber = '12345678',
            BillingCity = 'Toronto',
            BillingCountry = 'Canada',
            //BillingCountryCode = 'CA',
            //BillingStateCode = 'ON',
            BillingPostalCode = 'M5J 2V5',
            BillingStreet = '25 York Street',
            Description = 'A test account',
            Industry = 'Technology',
            Name = 'Test Account',
            ShippingCity = 'Toronto',
            ShippingCountry = 'Canada',
            //ShippingCountryCode = 'CA',
            //ShippingStateCode = 'ON',
            ShippingPostalCode = 'M5J 2V5',
            ShippingStreet = '25 York Street'
        );
    }

    /*
     * Create a basic Lead sObject
     */
    public static Lead createLead() {
        return new Lead(
            FirstName = 'Lead',
            LastName = 'Test',
            Company = 'My Test Company',
            //Status = 'Qualified',
            Status = 'New',
            City = 'Toronto', 
            Country = 'Canada',
            //CurrencyIsoCode = 'CAD',
            Email = 'lead.test@email.com',
            PostalCode = 'M5J 2V5',
            Street = '25 York Street',
            Industry = 'Technology'
        );
    }
    
    /*
     * Create a basic Lead object with an owner.
     * @param   userId      the ID of the user to set as the owner of the Lead
     * @return              a Lead sObject
     */
    public static Lead createLead(Id userId) {
        Lead lead = createLead();
        // Set the owner of the Lead
        lead.OwnerId = userId;
        return lead;
    }
    
    /**
      * Create an opportuntiy with an owner and related to an account
      * @param userId the user who will be the opportunity owner
      * @param accountId the account that will be associated to the opportunity
      */
    public static Opportunity createOpportunity(Id userId, Id accountId) {
        return new Opportunity (
            OwnerId = userId,
            Name = 'Opp',
            AccountId = accountId,
            CloseDate = (Date.Today()).addDays(30),
            StageName = 'Qualify',
            type='New Business'
        );
    }
    
    /**
      * Create a contact with an owner and related to an account
      * @param  userId      the owner of the contact
      * @param  accountId   the account associated with this contact
      */
    public static Contact createContact(Id userId, Id accountId) {
        return new Contact(
            OwnerId = userId,
            AccountId = accountId,
            FirstName = 'Contact',
            LastName = 'Test',
            Title = 'Test Contact'
        );
    }
    
    /**
      * Create a basic Task 
      */
    public static Task createTask(String subject, String status, String description) {
        return new Task(
            Description = description,
            Status = status,
            Subject = subject
        );
    }
    
    /**
      * Create a basic Task sObject linked to an sObject via whoId (Lead, Contact, etc.) or whatId (Account, Opportunity, etc.)
      */
    public static Task createTask(Id whatId, Id whoId, String subject, String status, String description) {
        Task task = createTask(subject, status, description);
        task.WhatId = whatId;
        task.WhoId = whoId;
        return task;
    }
    
    /**
      * Create a basic Task sObject linked to an sObject via whoId (Lead, Contact, etc.) or whatId (Account, Opportunity, etc.)
      */
    public static Task createTask(Id whatId, Id whoId) {
        Task task = createTask('Test Subject', 'Not Started', 'Test Task Description');
        task.WhatId = whatId;
        task.WhoId = whoId;
        return task;
    }
    
    /**
      * Create a basic Case sObject linked to an Account
      */
    public static Case createCase(Id accountId, String subject, String status) {
        return new Case(
            AccountId = accountId,
            Status = status,
            Subject = subject
        );
    }
    
    /*
     * Get a User sObject based on Id.
     *
     * @param   userId      specify the ID of the user to retrieve
     * @return              a User sObject
     */
    public static User getUserById(Id userId) {
        System.debug('User ID: ' + userId);
        return [SELECT Id,
        ProfileId,
        Username,
        Alias,
        FirstName,
        LastName
        FROM User 
        WHERE Id = :userId];
    }   

    /*
     * Retrieve a Profile sObject
     *
     * @return      a Profile sObject
     */
    public static Profile getProfile() {
        for (Profile p : [SELECT Id, PermissionsModifyAllData, Name FROM Profile]) {
            if (p.PermissionsModifyAllData) {
                return p;
            }
        }
        
        return new Profile();
    }
    
    /*
     * Retrieve a Profile sObject based on Name
     *
     * @param   name    the name of the profile to retrieve
     * @return          a Profile sObject
     */
    public static Profile getProfile(String name) {
        return [SELECT Id, Name FROM Profile WHERE Name = :name];
    }
    
    /*
     * Retrieve an Account sObject
     *
     * @param   id  the id of the Account sObject to retrieve
     * @return      the Account sObject
     */
    public static Account getAccount(Id id) {
        return [SELECT Id, 
        OwnerId,
        AccountNumber
        FROM Account WHERE Id = :id];
    }

    /*
     * Retrieve a Map of Account sObjects
     *
     * @param   ids the list of ids of the Account sObjects to retrieve
     * @return      a Map of Account sObjects
     */
    public static Map<Id, Account> getAccountMap(List<Id> ids) {
        Map<Id, Account> accountMap = new Map<Id, Account>();
        for (Account a : [SELECT Id, 
                          OwnerId,
                          AccountNumber,
                          //CurrencyIsoCode,
                          ShippingCity,
                          ShippingCountry,
                          //ShippingCountryCode,
                          ShippingLatitude,
                          ShippingLongitude,
                          ShippingPostalCode,
                          ShippingState,
                          //ShippingStateCode,
                          ShippingStreet,
                          BillingCity,
                          BillingCountry,
                          //BillingCountryCode,
                          BillingLatitude,
                          BillingLongitude,
                          BillingPostalCode,
                          BillingState,
                          //BillingStateCode,
                          BillingStreet
                          FROM Account 
                          WHERE Id IN :ids]) {
            accountMap.put(a.Id, a);
        }
        return accountMap;
    }
        
    /*
     * Retrieve a Lead sObject
     *
     * @param   id  the id of the Lead sObject to retrieve
     * @return      the Lead sObject
     */
    public static Lead getLead(Id id) {
        List<Lead> leadList = [SELECT Id, 
                                OwnerId
                                FROM Lead WHERE Id = :id];
        if (leadList.size() > 0) {
            return leadList[0];
        } else {
            return null;
        }
    }
    
    /**
      * Retrieve an Opportunity sObject
      *
      * @param id the id of the Opportuntiy to retrive
      * @return The opportunity object
      */
    public static Opportunity getOpportunity(Id id) {
        return [SELECT Id,
                       Amount,
                       ContractId,
                       //CurrencyIsoCode,
                       Name,
                       //RecordTypeId,
                       StageName,
                       Type   
                FROM Opportunity
                WHERE Id = :id];
    }

    public static Task getTask(Id id) {
        return [SELECT  Id,
                        CreatedDate
                FROM Task
                WHERE Id = :id
                LIMIT 1];
    }

    /**
      * SF-534: Retrieve a Task by WhoId
      */
    public static Task getTaskByWhoId(Id whoId) {
        List<Task> taskList = [SELECT Id
                               FROM Task
                               WHERE WhoId = :whoId];
        if((null != taskList) && (taskList.size() == 1)) {
            return taskList[0];
        }   else {
            return null;
        }
    }

    /**
      * SF-534: Retrieve a Record Type by Developer Name and SObject
      */
    public static RecordType getRTbyDevName(String devName, String sObjName) {
        List<RecordType> rtList = [SELECT Id, Name
                                   FROM RecordType
                                   WHERE DeveloperName = :devName AND SobjectType = :sObjName];
        if((null != rtList) && (rtList.size() == 1)) {
            return rtList[0];
        }   else {
            return null;
        }
    }
    
    /**
      * SF-597: Retrieve list of Tasks by WhatId
      */
    public static List<Task> getTasksByWhatId(Id whatId) {
        List<Task> taskList = [SELECT 
                                    Id,
                                    Description,
                                    Status,
                                    Subject,
                                    WhatId
                               FROM Task
                               WHERE WhatId = :whatId];
        if (taskList.size() > 0) {
            return taskList;
        } else {
            return null;
        }
    }

    public static Task getTaskByWhatId(Id whatId) {
        List<Task> taskList = getTasksByWhatId(whatId);
        if (taskList != null) {
            return taskList[0];
        } else {
            return null;
        }
    }

    /**
      * Retrieve a Case sObject by ID.
      */
    public static Case getCase(Id caseId) {
        List<Case> caseList = getCase(new List<Id>{caseId});
        if(caseList != null && caseList.size() == 1) {
            return caseList[0];
        }   else {
            return null;
        }
    }

    /**
      * Retrieve a List of Case sObject by ID.
      */
    public static List<Case> getCase(List<Id> caseIdList) {
        List<Case> caseList = [ SELECT  Id,
                                        Status,
                                        CaseNumber
                                FROM Case
                                WHERE Id IN :caseIdList];
        return caseList;
    }
        
}