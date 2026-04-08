/**
 * @description Invocable action to create follow-up tasks for Sales Guru Agent
 */
public with sharing class SalesGuruCreateTask {
    
    public class TaskRequest {
        @InvocableVariable(required=true description='Subject or title of the task')
        public String subject;
        
        @InvocableVariable(description='Related record ID (Lead, Contact, Account, or Opportunity)')
        public String relatedToId;
        
        @InvocableVariable(description='Due date for the task (YYYY-MM-DD format)')
        public Date dueDate;
        
        @InvocableVariable(description='Priority: High, Normal, or Low (default: Normal)')
        public String priority;
        
        @InvocableVariable(description='Description or notes for the task')
        public String description;
        
        @InvocableVariable(description='Task type: Call, Email, Meeting, Other')
        public String taskType;
    }
    
    public class TaskResponse {
        @InvocableVariable(description='The result message')
        public String message;
        
        @InvocableVariable(description='Whether the task was created successfully')
        public Boolean success;
        
        @InvocableVariable(description='The new Task ID')
        public String taskId;
    }
    
    @InvocableMethod(label='Create Follow-up Task' 
                     description='Creates a follow-up task for a lead, contact, account, or opportunity'
                     category='Sales Guru')
    public static List<TaskResponse> createTask(List<TaskRequest> requests) {
        List<TaskResponse> responses = new List<TaskResponse>();
        
        for (TaskRequest req : requests) {
            TaskResponse res = new TaskResponse();
            
            try {
                Task newTask = new Task();
                newTask.Subject = req.subject;
                newTask.OwnerId = UserInfo.getUserId();
                newTask.Status = 'Not Started';
                
                // Set due date (default to tomorrow if not specified)
                newTask.ActivityDate = req.dueDate != null ? req.dueDate : Date.today().addDays(1);
                
                // Set priority
                if (String.isNotBlank(req.priority)) {
                    if (req.priority.equalsIgnoreCase('High')) {
                        newTask.Priority = 'High';
                    } else if (req.priority.equalsIgnoreCase('Low')) {
                        newTask.Priority = 'Low';
                    } else {
                        newTask.Priority = 'Normal';
                    }
                } else {
                    newTask.Priority = 'Normal';
                }
                
                // Set description
                if (String.isNotBlank(req.description)) {
                    newTask.Description = req.description;
                }
                
                // Set task type
                if (String.isNotBlank(req.taskType)) {
                    newTask.Type = req.taskType;
                }
                
                // Link to related record
                if (String.isNotBlank(req.relatedToId)) {
                    String prefix = req.relatedToId.substring(0, 3);
                    
                    // Determine if it's a WhoId (Lead/Contact) or WhatId (Account/Opportunity)
                    if (prefix == '00Q') {
                        // Lead
                        newTask.WhoId = req.relatedToId;
                    } else if (prefix == '003') {
                        // Contact
                        newTask.WhoId = req.relatedToId;
                    } else if (prefix == '001') {
                        // Account
                        newTask.WhatId = req.relatedToId;
                    } else if (prefix == '006') {
                        // Opportunity
                        newTask.WhatId = req.relatedToId;
                    } else {
                        // Try as WhatId for other objects
                        newTask.WhatId = req.relatedToId;
                    }
                }
                
                insert newTask;
                
                res.success = true;
                res.taskId = newTask.Id;
                res.message = 'Successfully created task: "' + newTask.Subject + '"\n';
                res.message += '- **Due Date:** ' + newTask.ActivityDate.format() + '\n';
                res.message += '- **Priority:** ' + newTask.Priority + '\n';
                res.message += '- **Task ID:** ' + newTask.Id;
                
            } catch (Exception e) {
                res.success = false;
                res.message = 'Error creating task: ' + e.getMessage();
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}
