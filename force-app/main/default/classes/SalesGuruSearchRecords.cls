/**
 * @description Invocable action to search across sales records for Sales Guru Agent
 */
public with sharing class SalesGuruSearchRecords {
    
    public class SearchRequest {
        @InvocableVariable(required=true description='Search term to look for')
        public String searchTerm;
        
        @InvocableVariable(description='Object types to search: Lead, Contact, Account, Opportunity, or All (default: All)')
        public String objectType;
        
        @InvocableVariable(description='Maximum results per object (default: 5)')
        public Integer maxResults;
    }
    
    public class SearchResponse {
        @InvocableVariable(description='The formatted search results')
        public String searchResults;
        
        @InvocableVariable(description='Whether the search was successful')
        public Boolean success;
        
        @InvocableVariable(description='Total number of results found')
        public Integer totalResults;
    }
    
    @InvocableMethod(label='Search Sales Records' 
                     description='Searches across leads, contacts, accounts, and opportunities to find matching records'
                     category='Sales Guru')
    public static List<SearchResponse> searchRecords(List<SearchRequest> requests) {
        List<SearchResponse> responses = new List<SearchResponse>();
        
        for (SearchRequest req : requests) {
            SearchResponse res = new SearchResponse();
            
            try {
                String objType = String.isNotBlank(req.objectType) ? req.objectType.toLowerCase() : 'all';
                Integer maxResults = req.maxResults != null ? req.maxResults : 5;
                String searchPattern = '%' + req.searchTerm + '%';
                
                String results = '## Search Results for "' + req.searchTerm + '"\n\n';
                Integer totalCount = 0;
                
                // Search Leads
                if (objType == 'all' || objType == 'lead') {
                    List<Lead> leads = [
                        SELECT Id, Name, Company, Email, Status, OwnerId, Owner.Name
                        FROM Lead 
                        WHERE Name LIKE :searchPattern 
                           OR Company LIKE :searchPattern 
                           OR Email LIKE :searchPattern
                        LIMIT :maxResults
                    ];
                    
                    if (!leads.isEmpty()) {
                        results += '### Leads (' + leads.size() + ')\n';
                        for (Lead l : leads) {
                            results += '- **' + l.Name + '** (' + l.Company + ') - ' + l.Status + '\n';
                            results += '  ID: `' + l.Id + '`\n';
                        }
                        results += '\n';
                        totalCount += leads.size();
                    }
                }
                
                // Search Contacts
                if (objType == 'all' || objType == 'contact') {
                    List<Contact> contacts = [
                        SELECT Id, Name, Email, Title, Account.Name, Phone
                        FROM Contact 
                        WHERE Name LIKE :searchPattern 
                           OR Email LIKE :searchPattern
                           OR Account.Name LIKE :searchPattern
                        LIMIT :maxResults
                    ];
                    
                    if (!contacts.isEmpty()) {
                        results += '### Contacts (' + contacts.size() + ')\n';
                        for (Contact c : contacts) {
                            results += '- **' + c.Name + '**';
                            if (c.Title != null) results += ' (' + c.Title + ')';
                            if (c.Account != null) results += ' at ' + c.Account.Name;
                            results += '\n';
                            results += '  ID: `' + c.Id + '`\n';
                        }
                        results += '\n';
                        totalCount += contacts.size();
                    }
                }
                
                // Search Accounts
                if (objType == 'all' || objType == 'account') {
                    List<Account> accounts = [
                        SELECT Id, Name, Type, Industry, Phone, BillingCity, BillingState
                        FROM Account 
                        WHERE Name LIKE :searchPattern 
                           OR Industry LIKE :searchPattern
                        LIMIT :maxResults
                    ];
                    
                    if (!accounts.isEmpty()) {
                        results += '### Accounts (' + accounts.size() + ')\n';
                        for (Account a : accounts) {
                            results += '- **' + a.Name + '**';
                            if (a.Industry != null) results += ' (' + a.Industry + ')';
                            if (a.BillingCity != null) results += ' - ' + a.BillingCity;
                            if (a.BillingState != null) results += ', ' + a.BillingState;
                            results += '\n';
                            results += '  ID: `' + a.Id + '`\n';
                        }
                        results += '\n';
                        totalCount += accounts.size();
                    }
                }
                
                // Search Opportunities
                if (objType == 'all' || objType == 'opportunity') {
                    List<Opportunity> opps = [
                        SELECT Id, Name, StageName, Amount, CloseDate, Account.Name, IsClosed
                        FROM Opportunity 
                        WHERE Name LIKE :searchPattern 
                           OR Account.Name LIKE :searchPattern
                        LIMIT :maxResults
                    ];
                    
                    if (!opps.isEmpty()) {
                        results += '### Opportunities (' + opps.size() + ')\n';
                        for (Opportunity o : opps) {
                            String status = o.IsClosed ? '(Closed)' : '(Open)';
                            results += '- **' + o.Name + '** ' + status + '\n';
                            results += '  Stage: ' + o.StageName;
                            if (o.Amount != null) results += ' | Amount: $' + o.Amount.format();
                            results += '\n';
                            results += '  ID: `' + o.Id + '`\n';
                        }
                        results += '\n';
                        totalCount += opps.size();
                    }
                }
                
                if (totalCount == 0) {
                    results += '*No results found for "' + req.searchTerm + '"*\n';
                    results += '\nTry:\n- Using partial names\n- Checking spelling\n- Searching a different object type';
                } else {
                    results += '---\n**Total Results:** ' + totalCount;
                }
                
                res.success = true;
                res.searchResults = results;
                res.totalResults = totalCount;
                
            } catch (Exception e) {
                res.success = false;
                res.searchResults = 'Error searching records: ' + e.getMessage();
                res.totalResults = 0;
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}
