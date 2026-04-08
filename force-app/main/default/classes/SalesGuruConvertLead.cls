/**
 * @description Invocable action to convert a lead for Sales Guru Agent
 */
public with sharing class SalesGuruConvertLead {
    
    public class ConvertRequest {
        @InvocableVariable(required=true description='The Lead ID to convert')
        public String leadId;
        
        @InvocableVariable(description='Optional: Existing Account ID to link to')
        public String existingAccountId;
        
        @InvocableVariable(description='Optional: Opportunity name (defaults to lead company name)')
        public String opportunityName;
        
        @InvocableVariable(description='Whether to create an opportunity (default: true)')
        public Boolean createOpportunity;
    }
    
    public class ConvertResponse {
        @InvocableVariable(description='The result message')
        public String message;
        
        @InvocableVariable(description='Whether the conversion was successful')
        public Boolean success;
        
        @InvocableVariable(description='The new Account ID')
        public String accountId;
        
        @InvocableVariable(description='The new Contact ID')
        public String contactId;
        
        @InvocableVariable(description='The new Opportunity ID if created')
        public String opportunityId;
    }
    
    @InvocableMethod(label='Convert Lead' 
                     description='Converts a qualified lead into an Account, Contact, and optionally an Opportunity'
                     category='Sales Guru')
    public static List<ConvertResponse> convertLead(List<ConvertRequest> requests) {
        List<ConvertResponse> responses = new List<ConvertResponse>();
        
        for (ConvertRequest req : requests) {
            ConvertResponse res = new ConvertResponse();
            
            try {
                // Validate lead exists and is not already converted
                Lead lead = [
                    SELECT Id, Name, Company, IsConverted, Status 
                    FROM Lead 
                    WHERE Id = :req.leadId 
                    LIMIT 1
                ];
                
                if (lead.IsConverted) {
                    res.success = false;
                    res.message = 'Lead "' + lead.Name + '" has already been converted.';
                    responses.add(res);
                    continue;
                }
                
                // Get converted lead status
                LeadStatus convertStatus = [
                    SELECT Id, MasterLabel 
                    FROM LeadStatus 
                    WHERE IsConverted = true 
                    LIMIT 1
                ];
                
                // Set up the conversion
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(lead.Id);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                
                // Handle existing account if provided
                if (String.isNotBlank(req.existingAccountId)) {
                    lc.setAccountId(req.existingAccountId);
                }
                
                // Handle opportunity creation
                if (req.createOpportunity == false) {
                    lc.setDoNotCreateOpportunity(true);
                } else {
                    String oppName = String.isNotBlank(req.opportunityName) 
                        ? req.opportunityName 
                        : lead.Company + ' - New Opportunity';
                    lc.setOpportunityName(oppName);
                }
                
                // Convert the lead
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                
                if (lcr.isSuccess()) {
                    res.success = true;
                    res.accountId = lcr.getAccountId();
                    res.contactId = lcr.getContactId();
                    res.opportunityId = lcr.getOpportunityId();
                    res.message = 'Successfully converted lead "' + lead.Name + '"!\n';
                    res.message += '- Account ID: ' + res.accountId + '\n';
                    res.message += '- Contact ID: ' + res.contactId + '\n';
                    if (res.opportunityId != null) {
                        res.message += '- Opportunity ID: ' + res.opportunityId;
                    }
                } else {
                    res.success = false;
                    res.message = 'Conversion failed: ' + lcr.getErrors()[0].getMessage();
                }
                
            } catch (Exception e) {
                res.success = false;
                res.message = 'Error converting lead: ' + e.getMessage();
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}
