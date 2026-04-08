/**
 * @description Invocable action to get sales metrics for Sales Guru Agent
 */
public with sharing class SalesGuruGetMetrics {
    
    public class MetricsRequest {
        @InvocableVariable(description='Time period: ThisMonth, ThisQuarter, ThisYear, LastMonth, LastQuarter (default: ThisMonth)')
        public String timePeriod;
        
        @InvocableVariable(description='Owner ID for metrics (default: current user)')
        public String ownerId;
    }
    
    public class MetricsResponse {
        @InvocableVariable(description='The formatted metrics summary')
        public String metricsSummary;
        
        @InvocableVariable(description='Whether the query was successful')
        public Boolean success;
        
        @InvocableVariable(description='Total won revenue')
        public Decimal wonRevenue;
        
        @InvocableVariable(description='Total pipeline value')
        public Decimal pipelineValue;
        
        @InvocableVariable(description='Number of deals closed')
        public Integer dealsWon;
        
        @InvocableVariable(description='Number of deals lost')
        public Integer dealsLost;
    }
    
    @InvocableMethod(label='Get Sales Metrics' 
                     description='Retrieves sales performance metrics including revenue, win rate, and pipeline health'
                     category='Sales Guru')
    public static List<MetricsResponse> getMetrics(List<MetricsRequest> requests) {
        List<MetricsResponse> responses = new List<MetricsResponse>();
        
        for (MetricsRequest req : requests) {
            MetricsResponse res = new MetricsResponse();
            
            try {
                String ownerId = String.isNotBlank(req.ownerId) ? req.ownerId : UserInfo.getUserId();
                String period = String.isNotBlank(req.timePeriod) ? req.timePeriod : 'ThisMonth';
                
                Date startDate;
                Date endDate = Date.today();
                String periodLabel;
                
                // Calculate date range based on period
                if (period.equalsIgnoreCase('ThisMonth')) {
                    startDate = Date.today().toStartOfMonth();
                    periodLabel = 'This Month';
                } else if (period.equalsIgnoreCase('LastMonth')) {
                    startDate = Date.today().addMonths(-1).toStartOfMonth();
                    endDate = Date.today().toStartOfMonth().addDays(-1);
                    periodLabel = 'Last Month';
                } else if (period.equalsIgnoreCase('ThisQuarter')) {
                    Integer month = Date.today().month();
                    Integer quarterStartMonth = ((month - 1) / 3) * 3 + 1;
                    startDate = Date.newInstance(Date.today().year(), quarterStartMonth, 1);
                    periodLabel = 'This Quarter';
                } else if (period.equalsIgnoreCase('LastQuarter')) {
                    Integer month = Date.today().month();
                    Integer quarterStartMonth = ((month - 1) / 3) * 3 + 1;
                    startDate = Date.newInstance(Date.today().year(), quarterStartMonth, 1).addMonths(-3);
                    endDate = Date.newInstance(Date.today().year(), quarterStartMonth, 1).addDays(-1);
                    periodLabel = 'Last Quarter';
                } else if (period.equalsIgnoreCase('ThisYear')) {
                    startDate = Date.newInstance(Date.today().year(), 1, 1);
                    periodLabel = 'This Year';
                } else {
                    startDate = Date.today().toStartOfMonth();
                    periodLabel = 'This Month';
                }
                
                // Get closed won opportunities
                List<AggregateResult> wonResults = [
                    SELECT COUNT(Id) cnt, SUM(Amount) total
                    FROM Opportunity 
                    WHERE OwnerId = :ownerId 
                    AND IsClosed = true 
                    AND IsWon = true
                    AND CloseDate >= :startDate 
                    AND CloseDate <= :endDate
                ];
                
                // Get closed lost opportunities
                List<AggregateResult> lostResults = [
                    SELECT COUNT(Id) cnt, SUM(Amount) total
                    FROM Opportunity 
                    WHERE OwnerId = :ownerId 
                    AND IsClosed = true 
                    AND IsWon = false
                    AND CloseDate >= :startDate 
                    AND CloseDate <= :endDate
                ];
                
                // Get open pipeline
                List<AggregateResult> pipelineResults = [
                    SELECT COUNT(Id) cnt, SUM(Amount) total, AVG(Probability) avgProb
                    FROM Opportunity 
                    WHERE OwnerId = :ownerId 
                    AND IsClosed = false
                ];
                
                // Get new leads this period
                Integer newLeads = [
                    SELECT COUNT() FROM Lead 
                    WHERE OwnerId = :ownerId 
                    AND CreatedDate >= :startDate 
                    AND CreatedDate <= :endDate
                ];
                
                // Get converted leads this period
                Integer convertedLeads = [
                    SELECT COUNT() FROM Lead 
                    WHERE OwnerId = :ownerId 
                    AND IsConverted = true
                    AND ConvertedDate >= :startDate 
                    AND ConvertedDate <= :endDate
                ];
                
                // Calculate metrics
                res.dealsWon = wonResults[0].get('cnt') != null ? Integer.valueOf(wonResults[0].get('cnt')) : 0;
                res.wonRevenue = wonResults[0].get('total') != null ? (Decimal)wonResults[0].get('total') : 0;
                res.dealsLost = lostResults[0].get('cnt') != null ? Integer.valueOf(lostResults[0].get('cnt')) : 0;
                Decimal lostValue = lostResults[0].get('total') != null ? (Decimal)lostResults[0].get('total') : 0;
                
                Integer openDeals = pipelineResults[0].get('cnt') != null ? Integer.valueOf(pipelineResults[0].get('cnt')) : 0;
                res.pipelineValue = pipelineResults[0].get('total') != null ? (Decimal)pipelineResults[0].get('total') : 0;
                Decimal avgProbability = pipelineResults[0].get('avgProb') != null ? (Decimal)pipelineResults[0].get('avgProb') : 0;
                
                // Calculate win rate
                Integer totalClosed = res.dealsWon + res.dealsLost;
                Decimal winRate = totalClosed > 0 ? (Decimal.valueOf(res.dealsWon) / totalClosed * 100).setScale(1) : 0;
                
                // Build summary
                String summary = '## Sales Performance - ' + periodLabel + '\n\n';
                
                summary += '### Revenue & Deals\n';
                summary += '| Metric | Value |\n';
                summary += '|--------|-------|\n';
                summary += '| 💰 Won Revenue | $' + res.wonRevenue.format() + ' |\n';
                summary += '| ✅ Deals Won | ' + res.dealsWon + ' |\n';
                summary += '| ❌ Deals Lost | ' + res.dealsLost + ' |\n';
                summary += '| 📊 Win Rate | ' + winRate + '% |\n';
                
                summary += '\n### Pipeline Health\n';
                summary += '| Metric | Value |\n';
                summary += '|--------|-------|\n';
                summary += '| 📈 Open Pipeline | $' + res.pipelineValue.format() + ' |\n';
                summary += '| 🎯 Open Deals | ' + openDeals + ' |\n';
                summary += '| 📉 Avg Probability | ' + avgProbability.setScale(1) + '% |\n';
                summary += '| 💵 Weighted Pipeline | $' + (res.pipelineValue * avgProbability / 100).setScale(0).format() + ' |\n';
                
                summary += '\n### Lead Activity\n';
                summary += '| Metric | Value |\n';
                summary += '|--------|-------|\n';
                summary += '| 🆕 New Leads | ' + newLeads + ' |\n';
                summary += '| 🔄 Converted Leads | ' + convertedLeads + ' |\n';
                
                if (newLeads > 0) {
                    Decimal conversionRate = (Decimal.valueOf(convertedLeads) / newLeads * 100).setScale(1);
                    summary += '| 📈 Conversion Rate | ' + conversionRate + '% |\n';
                }
                
                res.success = true;
                res.metricsSummary = summary;
                
            } catch (Exception e) {
                res.success = false;
                res.metricsSummary = 'Error retrieving metrics: ' + e.getMessage();
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}
