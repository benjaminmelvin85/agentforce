/**
 * @description Invocable action to get lead details for Sales Guru Agent
 */
public with sharing class SalesGuruGetLeadDetails {
    
    public class LeadRequest {
        @InvocableVariable(required=true description='The Lead ID or Lead Name to search for')
        public String leadIdentifier;
    }
    
    public class LeadResponse {
        @InvocableVariable(description='The formatted lead details')
        public String leadDetails;
        
        @InvocableVariable(description='Whether the lead was found')
        public Boolean success;
        
        @InvocableVariable(description='Error message if any')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Get Lead Details' 
                     description='Retrieves detailed information about a lead including contact info, company, status, and recent activities'
                     category='Sales Guru')
    public static List<LeadResponse> getLeadDetails(List<LeadRequest> requests) {
        List<LeadResponse> responses = new List<LeadResponse>();
        
        for (LeadRequest req : requests) {
            LeadResponse res = new LeadResponse();
            
            try {
                List<Lead> leads = [
                    SELECT Id, Name, FirstName, LastName, Title, Company, Email, Phone, 
                           MobilePhone, Status, LeadSource, Rating, Industry, 
                           AnnualRevenue, NumberOfEmployees, Description, 
                           Street, City, State, PostalCode, Country,
                           IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId,
                           CreatedDate, LastModifiedDate, OwnerId, Owner.Name
                    FROM Lead 
                    WHERE Id = :req.leadIdentifier 
                       OR Name LIKE :('%' + req.leadIdentifier + '%')
                    LIMIT 1
                ];
                
                if (leads.isEmpty()) {
                    res.success = false;
                    res.errorMessage = 'No lead found matching: ' + req.leadIdentifier;
                    res.leadDetails = '';
                } else {
                    Lead l = leads[0];
                    res.success = true;
                    res.leadDetails = formatLeadDetails(l);
                }
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error retrieving lead: ' + e.getMessage();
                res.leadDetails = '';
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    private static String formatLeadDetails(Lead l) {
        String details = '**Lead: ' + l.Name + '**\n';
        details += '- **Status:** ' + (l.Status != null ? l.Status : 'Not set') + '\n';
        details += '- **Company:** ' + (l.Company != null ? l.Company : 'Not specified') + '\n';
        details += '- **Title:** ' + (l.Title != null ? l.Title : 'Not specified') + '\n';
        details += '- **Email:** ' + (l.Email != null ? l.Email : 'Not provided') + '\n';
        details += '- **Phone:** ' + (l.Phone != null ? l.Phone : 'Not provided') + '\n';
        details += '- **Lead Source:** ' + (l.LeadSource != null ? l.LeadSource : 'Unknown') + '\n';
        details += '- **Rating:** ' + (l.Rating != null ? l.Rating : 'Not rated') + '\n';
        details += '- **Industry:** ' + (l.Industry != null ? l.Industry : 'Not specified') + '\n';
        details += '- **Owner:** ' + (l.Owner.Name != null ? l.Owner.Name : 'Unassigned') + '\n';
        
        if (l.IsConverted) {
            details += '- **Converted:** Yes (Account ID: ' + l.ConvertedAccountId + ')\n';
        }
        
        if (l.Description != null) {
            details += '- **Notes:** ' + l.Description.abbreviate(200) + '\n';
        }
        
        return details;
    }
}
