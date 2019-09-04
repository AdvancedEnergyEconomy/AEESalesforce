@isTest(SeeAllData=true)
private class TestOpportunityTrigger {
    @isTest static void TestDeleteAccountWithOneOpportunity() {
        // Test data setup
        // Create an account with an opportunity, and then try to delete it
        Account acct = new Account(Name='Test Account Eric',Membership_Amount__c = 0,Email_domains__c='abc123.com');
        insert acct;
        //System.debug('Account Name ='+ acct.Name + acct.Email_domains__c);
        
        Contact c = new Contact(FirstName='Tom',
                                LastName='Smith', 
                                Email='tom@abc.com',
                                Account = acct,
                                AccountId = acct.Id,
                                LeadSource = 'PowerSuite Registration');
        insert c;
        //System.debug('Contact Id ='+ c.Id);
        
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
        opp.Allowed_Working_Groups_2__c = 'Briefing Call';
        opp.Account = acct;
        opp.Primary_Contact__c = c.Id;
        opp.AccountId = acct.Id;
       
        //System.debug('Opportunity Amount ='+ opp.Amount);
        //System.debug('Record Type ='+ opp.RecordTypeId);
        //System.debug('Opp Name ='+ opp.Name);
        
        insert opp;
        List<Opportunity> myopps =[select id from Opportunity where accountid=: acct.id];
		//System.debug('Check number of opps on account ='+ myopps.size());
        opp.StageName = 'Invoiced';

        // Perform test
        Test.startTest();
        update opp;
        Test.stopTest();

        
        // Verify by querying database
        Account accRes = [SELECT Id, Name,Membership_Amount__c, Membership_Type__c,Allowed_Working_Groups__c from Account Where name = 'Test Account Eric' limit 1];
        System.debug('Account Amount ='+ accRes.Membership_Amount__c);
        System.assertEquals(accRes.Membership_Amount__c, opp.Amount);
        System.assertEquals(accRes.Membership_Type__c, opp.Membership_Type__c);
        System.assertEquals(accRes.Allowed_Working_Groups__c, opp.Allowed_Working_Groups_2__c);
        
        
        
    }
    
}
