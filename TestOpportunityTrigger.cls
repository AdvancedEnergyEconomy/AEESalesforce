//This setting allows the test to access all actual sandbox or production data.
//This makes for easier dev testing and has little downside.
@isTest(SeeAllData=true)
private class TestOpportunityTrigger {
    @isTest static void TestChangeOpportunityStage() {
        // Test data setup
        // Create an account, two contacts and then a Membership Opportunity
        // Invoice the membership opp
        // Run tests to ensure that data that we are expecting is copied from the Opp to the Account
        // Then create an PowerSuite Opp and test again to see that correct PowerSuite Opp related has been copied
        Account acct = new Account(Name='Test Account Eric',Membership_Amount__c = 0,Email_domains__c='abc123.com');
        insert acct;
        System.debug('Account Name and domain='+ acct.Name + acct.Email_domains__c);
        
        Contact c = new Contact(FirstName='Tom',
                                LastName='Smith', 
                                Email='tom@abc.com',
                                Account = acct,
                                AccountId = acct.Id,
                                LeadSource = 'PowerSuite Registration');
        insert c;
        
        Contact c2 = new Contact(FirstName='Jane',
                                LastName='Smith', 
                                Email='jane@abc.com',
                                Account = acct,
                                AccountId = acct.Id,
                                LeadSource = 'PowerSuite Registration');
        insert c2;

        
        Opportunity opp = new Opportunity();
        
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Corporate Relations').getRecordTypeId();
        opp.Name = acct.Name + ' AEE Member 2019';
        opp.StageName='Awaiting Commitment';
        opp.CloseDate=System.today().addMonths(1);
        opp.Membership_type__c = 'AEE Member 2019';
        opp.Amount = 6000;
        opp.Type = 'New';
        opp.Annual_Membership_Start_Date__c = System.today();
        opp.Membership_Expiration_Date__c = System.today().addMonths(12);
        opp.Allowed_Working_Groups_2__c = 'Policy Briefing Call';
        opp.Account = acct;
        opp.Primary_Contact__c = c.Id;
        opp.AccountId = acct.Id;
        
        insert opp;
        //List<Opportunity> myopps =[select id from Opportunity where accountid=: acct.id];
		//System.debug('Check number of opps on account ='+ myopps.size());
        opp.StageName = 'Invoiced';

        // Perform test
        Test.startTest();
        update opp;

        // Verify by querying the temporary Salesforce database. This is the only "true" way to check if insert/updates worked.
        Account accRes = [SELECT Id, 
                          Name,
                          Membership_Amount__c, 
                          Membership_Type__c, 
                          Allowed_Working_Groups__c,
                          Annual_Membership_Start_Date__c,
                          Most_Recent_Expiration__c, 
                          PowerSuite_Max_Allowed_Users__c,
                          PowerSuite_Subscription_Amount__c,
                          Primary_Membership_Contact__c
                          from Account Where name = 'Test Account Eric' limit 1];
        
        //Testing that after the first opportunity was invoiced that values are as expected
        System.assertEquals(accRes.Membership_Amount__c, opp.Amount);
        System.assertEquals(accRes.Membership_Type__c, opp.Membership_Type__c);
        System.assertEquals(accRes.Most_Recent_Expiration__c, opp.Membership_Expiration_Date__c);
        System.assertEquals(accRes.Annual_Membership_Start_Date__c, opp.Annual_Membership_Start_Date__c);
        System.assertEquals(accRes.Allowed_Working_Groups__c, opp.Allowed_Working_Groups_2__c);
        
        //Now test by creating a PowerSuite opp and invoicing
        Opportunity poweropp = new Opportunity();
        
        poweropp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Software Subscription').getRecordTypeId();
        poweropp.Name = acct.Name + ' PowerSuite 2019';
        poweropp.StageName='Awaiting Commitment';
        poweropp.CloseDate=System.today().addMonths(1);
        poweropp.Membership_type__c = 'PowerSuite Essential';
        poweropp.Amount = 10000;
        poweropp.Number_of_PowerSuite_Users__c = 5;
        poweropp.Type = 'Upgrade';
        poweropp.Annual_Membership_Start_Date__c = System.today();
        poweropp.Membership_Expiration_Date__c = System.today().addMonths(12);
        poweropp.Account = acct;
        poweropp.Primary_Contact__c = c2.Id;
        poweropp.AccountId = acct.Id;
        
        insert poweropp;
        
        poweropp.StageName = 'Invoiced';

        update poweropp;
        
        Test.stopTest();

        
        // Verify by querying database for account record that should have been changed
        Account accResult = [SELECT Id, 
                             Name,
                             Membership_Amount__c, 
                             Membership_Type__c, 
                             Allowed_Working_Groups__c,
                             Annual_Membership_Start_Date__c,
                             Most_Recent_Expiration__c, 
                             PowerSuite_Max_Allowed_Users__c,
                             PowerSuite_Subscription_Amount__c,
                             Primary_Membership_Contact__c
                             from Account Where name = 'Test Account Eric' limit 1];
        
        //Check shared account fields that are used by all opps. Expecting values from PowerSuite opp 
        //because it was the most recently modifed and is designed to overwrite an values from another opp. 
        
        System.assertEquals(accResult.Annual_Membership_Start_Date__c, poweropp.Annual_Membership_Start_Date__c); 
        System.assertEquals(accResult.Most_Recent_Expiration__c, poweropp.Membership_Expiration_Date__c);
        System.assertEquals(accResult.Primary_Membership_Contact__c, poweropp.Primary_Contact__c);
        
        //Check membership related fields to ensure they were copied and/or not overwritten by accident.
        System.assertEquals(accResult.Membership_Amount__c, opp.Amount);
        System.assertEquals(accResult.Membership_Type__c, opp.Membership_Type__c);
        System.assertEquals(accResult.Allowed_Working_Groups__c, opp.Allowed_Working_Groups_2__c);
        
        //Check PowerSuite related fields to ensure they were copied and/or not overwritten by accident
        System.debug('PowerSuite Subscription Amount ='+ accResult.PowerSuite_Subscription_Amount__c);
        System.assertEquals(accResult.PowerSuite_Subscription_Amount__c, poweropp.Amount);
        System.assertEquals(accResult.PowerSuite_Max_Allowed_Users__c, poweropp.Number_of_PowerSuite_Users__c);

        
        
        
    }
    
}
