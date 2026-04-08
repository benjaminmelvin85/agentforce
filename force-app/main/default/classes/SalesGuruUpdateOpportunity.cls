/**
 * @description Invocable action to update opportunity stage for Sales Guru Agent
 */
public with sharing class SalesGuruUpdateOpportunity {
    
    public class UpdateRequest {
        @InvocableVariable(required=true description='The Opportunity ID or Name to update')
        public String opportunityIdentifier;
        
        @InvocableVariable(description='New stage name')
        public String newStage;
        
        @InvocableVariable(description='New close date (YYYY-MM-DD format)')
        public Date newCloseDate;
        
        @InvocableVariable(description='New amount')
        public Decimal newAmount;
        
        @InvocableVariable(description='Next step notes')
        public String nextStep;
    }
    
    public class UpdateResponse {
        @InvocableVariable(description='The result message')
        public String message;
        
        @InvocableVariable(description='Whether the update was successful')
        public Boolean success;
        
        @InvocableVariable(description='The updated opportunity details')
        public String opportunityDetails;
    }
    
    @InvocableMethod(label='Update Opportunity' 
                     description='Updates an opportunity stage, close date, amount, or next steps'
                     category='Sales Guru')
    public static List<UpdateResponse> updateOpportunity(List<UpdateRequest> requests) {
        List<UpdateResponse> responses = new List<UpdateResponse>();
        
        for (UpdateRequest req : requests) {
            UpdateResponse res = new UpdateResponse();
            
            try {
                // Find the opportunity
                List<Opportunity> opps = [
                    SELECT Id, Name, StageName, Amount, CloseDate, NextStep, 
                           Account.Name, Probability, IsClosed, IsWon
                    FROM Opportunity 
                    WHERE Id = :req.opportunityIdentifier 
                       OR Name LIKE :('%' + req.opportunityIdentifier + '%')
                    LIMIT 1
                ];
                
                if (opps.isEmpty()) {
                    res.success = false;
                    res.message = 'No opportunity found matching: ' + req.opportunityIdentifier;
                    responses.add(res);
                    continue;
                }
                
                Opportunity opp = opps[0];
                List<String> changes = new List<String>();
                
                // Apply updates
                if (String.isNotBlank(req.newStage)) {
                    // Validate stage exists
                    List<OpportunityStage> stages = [
                        SELECT MasterLabel FROM OpportunityStage 
                        WHERE MasterLabel = :req.newStage OR ApiName = :req.newStage
                        LIMIT 1
                    ];
                    
                    if (stages.isEmpty()) {
                        res.success = false;
                        res.message = 'Invalid stage: ' + req.newStage + '. Please use a valid stage name.';
                        responses.add(res);
                        continue;
                    }
                    
                    String oldStage = opp.StageName;
                    opp.StageName = stages[0].MasterLabel;
                    changes.add('Stage: ' + oldStage + ' → ' + opp.StageName);
                }
                
                if (req.newCloseDate != null) {
                    Date oldDate = opp.CloseDate;
                    opp.CloseDate = req.newCloseDate;
                    changes.add('Close Date: ' + (oldDate != null ? oldDate.format() : 'None') + ' → ' + opp.CloseDate.format());
                }
                
                if (req.newAmount != null) {
                    Decimal oldAmount = opp.Amount;
                    opp.Amount = req.newAmount;
                    changes.add('Amount: $' + (oldAmount != null ? oldAmount.format() : '0') + ' → $' + opp.Amount.format());
                }
                
                if (String.isNotBlank(req.nextStep)) {
                    opp.NextStep = req.nextStep;
                    changes.add('Next Step updated');
                }
                
                if (changes.isEmpty()) {
                    res.success = false;
                    res.message = 'No updates specified. Please provide at least one field to update.';
                    responses.add(res);
                    continue;
                }
                
                // Save the opportunity
                update opp;
                
                // Refresh to get updated values
                opp = [
                    SELECT Id, Name, StageName, Amount, CloseDate, NextStep, 
                           Account.Name, Probability, IsClosed, IsWon
                    FROM Opportunity WHERE Id = :opp.Id
                ];
                
                res.success = true;
                res.message = 'Successfully updated opportunity "' + opp.Name + '"!\n\n**Changes:**\n- ' + String.join(changes, '\n- ');
                res.opportunityDetails = formatOpportunityDetails(opp);
                
            } catch (Exception e) {
                res.success = false;
                res.message = 'Error updating opportunity: ' + e.getMessage();
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    private static String formatOpportunityDetails(Opportunity opp) {
        String details = '\n\n**Current State:**\n';
        details += '- Stage: ' + opp.StageName + '\n';
        details += '- Amount: $' + (opp.Amount != null ? opp.Amount.format() : '0') + '\n';
        details += '- Close Date: ' + (opp.CloseDate != null ? opp.CloseDate.format() : 'Not set') + '\n';
        details += '- Probability: ' + opp.Probability + '%\n';
        details += '- Next Step: ' + (opp.NextStep != null ? opp.NextStep : 'Not defined');
        return details;
    }
}
