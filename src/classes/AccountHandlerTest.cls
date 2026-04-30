@isTest
private class AccountHandlerTest {
    @isTest
    static void testCreateAccount() {
        String testName = 'Test Account';

        Test.startTest();
        Account acc = AccountHandler.createAccount(testName);
        Test.stopTest();

        // Verify the account was inserted
        Account inserted = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals(testName, inserted.Name);
    }

    @isTest
    static void testCreateAccountWithBlankName() {
        try {
            AccountHandler.createAccount('');
            System.assert(false, 'Expected exception for blank name');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Account name cannot be blank', e.getMessage());
        }
    }
}