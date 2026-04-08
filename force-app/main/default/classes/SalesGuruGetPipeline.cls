/**
 * @description Invocable action to get sales pipeline for Sales Guru Agent
 */
public with sharing class SalesGuruGetPipeline {
    
    public class PipelineRequest {
        @InvocableVariable(description='Filter by stage name (optional)')
        public String stageName;
        
        @InvocableVariable(description='Filter by owner ID (optional, defaults to current user)')
        public String ownerId;
        
        @InvocableVariable(description='Include closed opportunities (default: false)')
        public Boolean includeClosed;
        
        @InvocableVariable(description='Maximum number of opportunities to return (default: 10)')
        public Integer maxResults;
    }
    
    public class PipelineResponse {
        @InvocableVariable(description='The formatted pipeline summary')
        public String pipelineSummary;
        
        @InvocableVariable(description='Total pipeline value')
        public Decimal totalValue;
        
        @InvocableVariable(description='Number of opportunities')
        public Integer opportunityCount;
        
        @InvocableVariable(description='Whether the query was successful')
        public Boolean success;
    }
    
    @InvocableMethod(label='Get My Pipeline' 
                     description='Retrieves the current sales pipeline with opportunities, stages, values, and close dates'
                     category='Sales Guru')
    public static List<PipelineResponse> getPipeline(List<PipelineRequest> requests) {
        List<PipelineResponse> responses = new List<PipelineResponse>();
        
        for (PipelineRequest req : requests) {
            PipelineResponse res = new PipelineResponse();
            
            try {
                String ownerId = String.isNotBlank(req.ownerId) ? req.ownerId : UserInfo.getUserId();
                Integer maxResults = req.maxResults != null ? req.maxResults : 10;
                Boolean includeClosed = req.includeClosed == true;
                
                String query = 'SELECT Id, Name, StageName, Amount, Probability, CloseDate, ' +
                              'Account.Name, Type, LeadSource, NextStep, Description ' +
                              'FROM Opportunity WHERE OwnerId = :ownerId ';
                
                if (!includeClosed) {
                    query += 'AND IsClosed = false ';
                }
                
                if (String.isNotBlank(req.stageName)) {
                    String stageFilter = '%' + req.stageName + '%';
                    query += 'AND StageName LIKE :stageFilter ';
                }
                
                query += 'ORDER BY CloseDate ASC LIMIT :maxResults';
                
                List<Opportunity> opps = Database.query(query);
                
                res.success = true;
                res.opportunityCount = opps.size();
                res.totalValue = 0;
                
                if (opps.isEmpty()) {
                    res.pipelineSummary = 'No open opportunities found in your pipeline.';
                } else {
                    String summary = '## Your Sales Pipeline\n\n';
                    summary += '| Opportunity | Account | Stage | Amount | Close Date |\n';
                    summary += '|-------------|---------|-------|--------|------------|\n';
                    
                    for (Opportunity opp : opps) {
                        Decimal amt = opp.Amount != null ? opp.Amount : 0;
                        res.totalValue += amt;
                        
                        summary += '| ' + opp.Name.abbreviate(25) + ' | ';
                        summary += (opp.Account != null ? opp.Account.Name.abbreviate(20) : 'N/A') + ' | ';
                        summary += opp.StageName + ' | ';
                        summary += '$' + amt.format() + ' | ';
                        summary += (opp.CloseDate != null ? opp.CloseDate.format() : 'TBD') + ' |\n';
                    }
                    
                    summary += '\n**Total Pipeline Value:** $' + res.totalValue.format() + '\n';
                    summary += '**Number of Opportunities:** ' + res.opportunityCount;
                    
                    res.pipelineSummary = summary;
                }
                
            } catch (Exception e) {
                res.success = false;
                res.pipelineSummary = 'Error retrieving pipeline: ' + e.getMessage();
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}
