/**
 * @description Invocable action to get account intelligence for Sales Guru Agent
 */
public with sharing class SalesGuruGetAccountInfo {
    
    public class AccountRequest {
        @InvocableVariable(required=true description='The Account ID or Account Name to search for')
        public String accountIdentifier;
        
        @InvocableVariable(description='Include related opportunities (default: true)')
        public Boolean includeOpportunities;
        
        @InvocableVariable(description='Include related contacts (default: true)')
        public Boolean includeContacts;
    }
    
    public class AccountResponse {
        @InvocableVariable(description='The formatted account details')
        public String accountDetails;
        
        @InvocableVariable(description='Whether the account was found')
        public Boolean success;
        
        @InvocableVariable(description='Error message if any')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Get Account Info' 
                     description='Retrieves comprehensive account information including contacts, opportunities, and engagement history'
                     category='Sales Guru')
    public static List<AccountResponse> getAccountInfo(List<AccountRequest> requests) {
        List<AccountResponse> responses = new List<AccountResponse>();
        
        for (AccountRequest req : requests) {
            AccountResponse res = new AccountResponse();
            
            try {
                Boolean includeOpps = req.includeOpportunities != false;
                Boolean includeContacts = req.includeContacts != false;
                
                List<Account> accounts = [
                    SELECT Id, Name, Type, Industry, AnnualRevenue, NumberOfEmployees,
                           Phone, Website, BillingCity, BillingState, BillingCountry,
                           Description, OwnerId, Owner.Name, Rating,
                           CreatedDate, LastModifiedDate,
                           (SELECT Id, Name, Title, Email, Phone FROM Contacts LIMIT 5),
                           (SELECT Id, Name, StageName, Amount, CloseDate, IsClosed, IsWon 
                            FROM Opportunities ORDER BY CloseDate DESC LIMIT 5)
                    FROM Account 
                    WHERE Id = :req.accountIdentifier 
                       OR Name LIKE :('%' + req.accountIdentifier + '%')
                    LIMIT 1
                ];
                
                if (accounts.isEmpty()) {
                    res.success = false;
                    res.errorMessage = 'No account found matching: ' + req.accountIdentifier;
                    res.accountDetails = '';
                } else {
                    Account acc = accounts[0];
                    res.success = true;
                    res.accountDetails = formatAccountDetails(acc, includeOpps, includeContacts);
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error retrieving account: ' + e.getMessage();
                res.accountDetails = '';
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    private static String formatAccountDetails(Account acc, Boolean includeOpps, Boolean includeContacts) {
        String details = '## Account: ' + acc.Name + '\n\n';
        
        // Basic Info
        details += '### Company Information\n';
        details += '- **Type:** ' + (acc.Type != null ? acc.Type : 'Not specified') + '\n';
        details += '- **Industry:** ' + (acc.Industry != null ? acc.Industry : 'Not specified') + '\n';
        details += '- **Annual Revenue:** ' + (acc.AnnualRevenue != null ? '$' + acc.AnnualRevenue.format() : 'Not specified') + '\n';
        details += '- **Employees:** ' + (acc.NumberOfEmployees != null ? String.valueOf(acc.NumberOfEmployees) : 'Not specified') + '\n';
        details += '- **Phone:** ' + (acc.Phone != null ? acc.Phone : 'Not provided') + '\n';
        details += '- **Website:** ' + (acc.Website != null ? acc.Website : 'Not provided') + '\n';
        details += '- **Location:** ' + formatLocation(acc) + '\n';
        details += '- **Owner:** ' + (acc.Owner.Name != null ? acc.Owner.Name : 'Unassigned') + '\n';
        details += '- **Rating:** ' + (acc.Rating != null ? acc.Rating : 'Not rated') + '\n';
        
        // Contacts
        if (includeContacts && !acc.Contacts.isEmpty()) {
            details += '\n### Key Contacts\n';
            for (Contact c : acc.Contacts) {
                details += '- **' + c.Name + '**';
                if (c.Title != null) details += ' (' + c.Title + ')';
                if (c.Email != null) details += ' - ' + c.Email;
                details += '\n';
            }
        }
        
        // Opportunities
        if (includeOpps && !acc.Opportunities.isEmpty()) {
            details += '\n### Recent Opportunities\n';
            Decimal totalOpen = 0;
            Decimal totalWon = 0;
            
            for (Opportunity opp : acc.Opportunities) {
                String status = opp.IsClosed ? (opp.IsWon ? '✓ Won' : '✗ Lost') : '○ Open';
                details += '- ' + status + ': **' + opp.Name + '** - $' + (opp.Amount != null ? opp.Amount.format() : '0');
                details += ' (' + opp.StageName + ')\n';
                
                if (!opp.IsClosed && opp.Amount != null) totalOpen += opp.Amount;
                if (opp.IsWon && opp.Amount != null) totalWon += opp.Amount;
            }
            
            details += '\n**Open Pipeline:** $' + totalOpen.format() + ' | **Won Revenue:** $' + totalWon.format();
        }
        
        return details;
    }
    
    private static String formatLocation(Account acc) {
        List<String> parts = new List<String>();
        if (acc.BillingCity != null) parts.add(acc.BillingCity);
        if (acc.BillingState != null) parts.add(acc.BillingState);
        if (acc.BillingCountry != null) parts.add(acc.BillingCountry);
        return parts.isEmpty() ? 'Not specified' : String.join(parts, ', ');
    }
}
