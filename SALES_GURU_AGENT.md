# Sales Guru Agent

An Agentforce employee agent that assists sales reps with lead conversion, pipeline management, and daily sales tasks to close deals faster.

## Agent Overview

- **Type**: Agentforce Employee Agent (Internal Copilot)
- **Planner**: ReAct (Reasoning + Acting)
- **Org Alias**: DemoOrg

## Topics & Actions

### Lead Management
Helps sales reps manage leads effectively - getting lead details, searching for leads, and converting qualified leads.

| Action | Apex Class | Description |
|--------|-----------|-------------|
| Get Lead Details | `SalesGuruGetLeadDetails` | Retrieves lead info including contact, company, status |
| Convert Lead | `SalesGuruConvertLead` | Converts qualified lead to Account/Contact/Opportunity |
| Search Sales Records | `SalesGuruSearchRecords` | Finds leads by name or keyword |

**Instructions**: When working with leads, confirm identity before changes. Ensure BANT (Budget, Authority, Need, Timeline) is confirmed before conversion.

---

### Opportunity Management
Helps sales reps manage their pipeline and opportunities - viewing pipeline, updating stages, amounts, and close dates.

| Action | Apex Class | Description |
|--------|-----------|-------------|
| Get My Pipeline | `SalesGuruGetPipeline` | Shows open opportunities with stages, amounts, close dates |
| Update Opportunity | `SalesGuruUpdateOpportunity` | Updates stage, amount, close date, next steps |
| Search Sales Records | `SalesGuruSearchRecords` | Finds opportunities by name or keyword |

**Instructions**: Use stages BANT → Discovery → Presentation → Proposal → Negotiation → Close. Celebrate wins!

---

### Account Intelligence
Provides comprehensive account information including company details, key contacts, and opportunity history.

| Action | Apex Class | Description |
|--------|-----------|-------------|
| Get Account Info | `SalesGuruGetAccountInfo` | Gets company details, contacts, opportunity history |
| Search Sales Records | `SalesGuruSearchRecords` | Finds accounts by name or keyword |

**Instructions**: Highlight decision makers, note purchase history, suggest upsell/cross-sell opportunities.

---

### Sales Productivity
Helps sales reps stay productive with task management and performance tracking.

| Action | Apex Class | Description |
|--------|-----------|-------------|
| Create Follow-up Task | `SalesGuruCreateTask` | Creates follow-up tasks for leads, contacts, accounts, opps |
| Get Sales Metrics | `SalesGuruGetMetrics` | Shows performance metrics - revenue, pipeline, win rate |

**Instructions**: Encourage regular follow-ups. Provide context on metrics and suggest actions.

---

## Sales Process Context

The agent understands this sales process:
- **Objects**: Leads, Opportunities, Accounts, Contacts
- **Stages**: BANT → Discovery → Presentation → Proposal → Negotiation → Close
- **Lead Conversion**: When budget, decision maker, need, and timeline are confirmed
- **Goal**: Increase conversions, reduce time-to-close

## Deployment

### Deploy Apex Classes
```bash
sf project deploy start --target-org DemoOrg --source-dir force-app/main/default/classes
```

### Configure Topics & Actions (Manual)
Topics and Actions must be configured in Salesforce Setup UI:
1. Go to **Setup → Agents → Sales Guru Agent**
2. Create each Topic with its assigned Actions
3. Link Actions to the corresponding Apex invocable classes

> **Note**: GenAiPlannerBundle metadata is not fully supported by Salesforce CLI yet.

## Files Structure

```
force-app/main/default/
├── bots/Sales_Guru_Agent/
│   ├── Sales_Guru_Agent.bot-meta.xml
│   └── v1.botVersion-meta.xml
├── classes/
│   ├── SalesGuruGetLeadDetails.cls
│   ├── SalesGuruConvertLead.cls
│   ├── SalesGuruGetPipeline.cls
│   ├── SalesGuruUpdateOpportunity.cls
│   ├── SalesGuruGetAccountInfo.cls
│   ├── SalesGuruCreateTask.cls
│   ├── SalesGuruGetMetrics.cls
│   └── SalesGuruSearchRecords.cls
└── genAiPlanners/
    └── Sales_Guru_Agent.genAiPlanner-meta.xml
```

## Example Prompts

- "Show me my pipeline"
- "What's the status of the Acme lead?"
- "Convert the Johnson lead and create an opportunity"
- "Update the GlobalTech deal to Negotiation stage"
- "Tell me about the Contoso account"
- "Create a follow-up task to call Sarah next Tuesday"
- "How am I doing this month?"
