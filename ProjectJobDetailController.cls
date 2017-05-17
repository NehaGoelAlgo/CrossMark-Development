/*******************************************************************************************************************
** Module Name   : ProjectJobDetailController
** Description   : This class is used to receive the Job Id as parameter and send Job details and its related object details.
** 
** Organization  : Crossmark
**
** Revision History:-
** Version             Date            Author                             
** 1.0                 01/24/16       PRAFULL KUMAR(Algoworks)
** 1.0                 02/06/17       NEHA GOEL(Algoworks)     
******************************************************************************************************************/
public with sharing class ProjectJobDetailController {
    
    // Define private Constant literals
    private static final String LAUNCH_DATE_PREFIX = 'Launch Date';
    private static final String COMMITTED_DATE_PREFIX = 'Committed Date';
    private static final String EXECUTED_DATE_PREFIX = 'Executed Date';
    private static final String COMPLETED_DATE_PREFIX = 'Completed Date';
    private static final String JOB_ATTEMPT_PREFIX = 'Job Attempt #';
    private static final String DATE_POSTFIX = 'Date';
    private static final String DATE_TIME_FORMAT_DD = 'MMM dd, yyyy';
    private static final String SYSTEM_DATE_TIME_FORMAT = 'MMMM dd, yyyy';
    private static final String ENTRY_TITLE_BY_USER = 'by';
    private static final Boolean TRUE_VALUE = true;
    private static final Boolean FALSE_VALUE = false;
    private static final Integer EVENT_INDEX = 4;
    private static final String SPACE = ' ';
    private static final String OPEN_STATUS = 'Open';
    private static final String ASSIGNED_STATUS = 'Assigned';
    private static final String STARTED_STATUS = 'Started';
    private static final String REPORTED_STATUS = 'Reported';
    private static final String GREEN_COLOR = 'slds-is-complete';
    private static final String BLUE_COLOR = 'slds-is-current'; 
    private static final String GREY_COLOR = 'slds-is-incomplete';
    private static final String CANCELED_STATUS = 'Canceled';
    private static final String CLOSED_STATUS = 'Closed';
    private static final String BORDER_COLOR_GREEN = 'green';
    private static final String BORDER_COLOR_RED = 'red';
     
    // Define private icons URL
    private static final String CROSS_ICON = '/assets/icons/utility-sprite/svg/symbols.svg#close';
    private static final String RIGHT_ICON = '/assets/icons/utility-sprite/svg/symbols.svg#check';
    
    
    
    /** 
    * Return JobTimelineWrapper Object based on the parameter JobId.
    * @param jobId : It contains id of Job record.
    * @return : Returns JobTimelineWrapper class instance.
    */
    @AuraEnabled
    public static JobTimelineWrapper getTimelineObject(String jobId) {  
    
        JobTimelineWrapper jobTimelineWrapper = new JobTimelineWrapper();
        List<ActivityDate> listOfJobEventDate = new List<ActivityDate>();
        List<JobTimelineEntry> jobTimelineEntryList = new List<JobTimelineEntry>();
        List<Job__c> jobList = [Select Id, 
                                       Name, 
                                       JobLaunchDate__c, 
                                       JobCommittedDate__c, 
                                       JobExecutedDate__c, 
                                       JobCompletedDate__c, 
                                       JobDateReported__c, 
                                       (Select Id,
                                               Name, 
                                               AttemptSequencePadded__c, 
                                               DateReported__c, 
                                               Isexecuted__c 
                                               From Job_Attempts__r 
                                               where Job__r.Id =: JobId
                                       ) From Job__c 
                                       where id =: JobId limit 1];
        if(jobList.size() > 0){
            for(Job__c jobObj : jobList){
                Integer eventIndexInt = EVENT_INDEX;
                
                if(jobObj.JobCompletedDate__c != null){
                    eventIndexInt = eventIndexInt - 1;
                    createJobTimelineEntry(listOfJobEventDate, jobObj.JobCompletedDate__c, COMPLETED_DATE_PREFIX, TRUE_VALUE, RIGHT_ICON, eventIndexInt, FALSE_VALUE, BORDER_COLOR_GREEN);
                }
                
                if(jobObj.JobExecutedDate__c != null){
                    eventIndexInt = eventIndexInt - 1;
                    createJobTimelineEntry(listOfJobEventDate, jobObj.JobExecutedDate__c, EXECUTED_DATE_PREFIX, TRUE_VALUE, RIGHT_ICON, eventIndexInt, FALSE_VALUE, BORDER_COLOR_GREEN);
                }
                
                
                for(JobAttempt__c jobAttemptObj : jobObj.Job_Attempts__r){
                    eventIndexInt = eventIndexInt - 1;
                    DateTime dateReported = jobAttemptObj.DateReported__c;
                    String jobTitle = JOB_ATTEMPT_PREFIX + jobAttemptObj.AttemptSequencePadded__c + ' ' + DATE_POSTFIX;
                    if(dateReported != null){
                        String icon = '';
                        Boolean isCrossIcon = false;
                        if(jobAttemptObj.Isexecuted__c){
                            icon = RIGHT_ICON;
                            isCrossIcon = false;
                            createJobTimelineEntry(listOfJobEventDate, Date.newInstance(dateReported.year(), dateReported.month(), dateReported.day()), jobTitle, TRUE_VALUE, icon, eventIndexInt, isCrossIcon, BORDER_COLOR_GREEN);
                        }
                        else{
                            icon = CROSS_ICON;
                            isCrossIcon = true;
                            createJobTimelineEntry(listOfJobEventDate, Date.newInstance(dateReported.year(), dateReported.month(), dateReported.day()), jobTitle, TRUE_VALUE, icon, eventIndexInt, isCrossIcon, BORDER_COLOR_RED);
                        }
                        
                    }
                }
                
                if(jobObj.JobCommittedDate__c != null){
                    eventIndexInt = eventIndexInt - 1;
                    DateTime jobCommittedDate = jobObj.JobCommittedDate__c ;
                    if(jobCommittedDate != null){
                        createJobTimelineEntry(listOfJobEventDate, jobObj.JobCommittedDate__c, COMMITTED_DATE_PREFIX, TRUE_VALUE, RIGHT_ICON, eventIndexInt, FALSE_VALUE, BORDER_COLOR_GREEN);
                    }                 
                }
                
                
                if(jobObj.JobLaunchDate__c != null){
                    createJobTimelineEntry(listOfJobEventDate, jobObj.JobLaunchDate__c, LAUNCH_DATE_PREFIX, TRUE_VALUE, RIGHT_ICON, eventIndexInt, FALSE_VALUE, BORDER_COLOR_GREEN);
                }
                
                listOfJobEventDate.sort();
                
                for (Integer i = 0; i <= (listOfJobEventDate.size() - 1); i++){
                    jobTimelineEntryList.add(((ActivityDate)listOfJobEventDate.get(i)).getTimelineEntry());
                }
                
                jobTimelineWrapper.jobTimelineEntryList = jobTimelineEntryList;
            }
        }
         
        return jobTimelineWrapper;
    }
    
    /**
    * Creates a new JobTimelineEntry object based on the parameters passed, and adds to the list.
    * @param listOfJobEventDate : It contains list of ActivityDate class instance.
    * @param dateTimeObj : It contains date type variable.
    * @param timelineEntryTitlePrefix : It contains prefix of title of job timeline as a string type.
    * @param isEventIcon : It indicates event icon is available or not.
    * @param eventIconName : It describes event icon name as a string type.
    * @param eventIndexInt : It uses as a indexes of events to display.
    * @param isCrossIcon : It contains boolean value for Cross icon.
    * @param borderColor : It contains string value for border color of job timeline entry.
    */
    private static void createJobTimelineEntry(List<ActivityDate> listOfJobEventDate, Date dateTimeObj, String timelineEntryTitlePrefix, Boolean isEventIcon, String eventIconName, Integer eventIndexInt, Boolean isCrossIcon, String borderColor) {
        Boolean isTitleSet = false;
        
        if(dateTimeObj != null){
            JobTimelineEntry jobTimelineEntry = new JobTimelineEntry();
            String dateTimeStr =  DateTime.newInstance(dateTimeObj.year(),dateTimeObj.month(),dateTimeObj.day()).format(DATE_TIME_FORMAT_DD); // Conversion datetime to required format 
            jobTimelineEntry.timelineEntryDate = dateTimeStr;
            jobTimelineEntry.eventIconName = eventIconName;
            jobTimelineEntry.isEventIcon = TRUE_VALUE;
            jobTimelineEntry.timelineEntryTitle = timelineEntryTitlePrefix;
            jobTimelineEntry.isCrossIcon = isCrossIcon;
            jobTimelineEntry.borderColor = borderColor;
            
            ActivityDate activityDate = new ActivityDate(dateTimeObj, eventIndexInt, jobTimelineEntry);
            listOfJobEventDate.add(activityDate);
        }
    }
    
    /** 
    * Return header List based on the parameter jobId. 
    * @param jobId : It contains id of Job record.
    * @return : Returns List of string for job project's information.
    */
    @AuraEnabled
    public static List<String> getJobProjectDetails(String jobId) { 
        List<String> headerList = new List<String>();
   
        List<Job__c> jobList = [Select Id, 
                                       Name, 
                                       Project__r.Name 
                                       From Job__c where id =: JobId limit 1];
                                       
        if(jobList != null && jobList.size() > 0){
            headerList.add(jobList.get(0).Project__r.Name);
        }
        return headerList;     
    }
    
    /** 
    * Return job details List based on the parameter jobId.
    * @param jobId : It contains id of Job record.
    * @return : Returns Job object record.
    */
    @AuraEnabled
    public static Job__c getJobDetails(String jobId) { 
        List<Job__c> jobDetailsList = new List<Job__c>();
        
        jobDetailsList = [ Select  Id, 
                                   Name, 
                                   HasException__c, 
                                   ExceptionName__c, 
                                   JobStatus__c, 
                                   IsExecuted__c, 
                                   JobExecutedDate__c, 
                                   CompletionStatus__c,
                                   JobCompletedDate__c, 
                                   MaterialCount__c, 
                                   NumberOfWorkers__c, 
                                   PurchaseAmount__c, 
                                   EstimatedMinutes__c, 
                                   ActiveJobAttemptTimeReported__c, 
                                   TimeReported__c, 
                                   StartTime__c, 
                                   JobManualUrl__c, 
                                   AccountableExecutionCompany__r.Name, 
                                   AccountableExecutionCompany__r.Logo__c, 
                                   Location__r.LocationNumber__c, 
                                   Location__r.Name, 
                                   Location__r.Address__c, 
                                   Location__r.City__c, 
                                   Location__r.State__c, 
                                   Location__r.Country__c, 
                                   Location__r.PostalCodeName__c, 
                                   Location__r.Logo__c
                                   From Job__c where id =: JobId limit 1];
        
        if(jobDetailsList != null && jobDetailsList.size() > 0){
            return jobDetailsList.get(0);
        }                           
        return null;
    }
    
    /** 
    * Return job Attempt List based on the parameter jobId.
    * @param jobId : It contains id of Job record.
    * @return : Returns JobAttemptListWrapper class instance.
    */
    @AuraEnabled
    public static JobAttemptListWrapper getJobAttemptList(String jobId) { 
        JobAttemptListWrapper jobAttemptListWrapperObj = new JobAttemptListWrapper();
        
        List<JobAttemptEntryWrapper> jobAttemptEntryWrapperList = new List<JobAttemptEntryWrapper>();
        
        
        List<Job__c> jobList = [Select Id, 
                                       Name, 
                                       ActiveJobAttempt__c,  
                                       (Select Id, 
                                                Name, 
                                                AttemptSequencePadded__c, 
                                                AttemptScheduleDate__c, 
                                                AttemptResponsibleExecutionCompany__c, 
                                                AttemptResponsibleExecutionCompanyLogo__c, 
                                                DateReported__c, 
                                                Isexecuted__c, 
                                                CreatedDate, 
                                                AttemptStatus__c, 
                                                DateAssigned__c, 
                                                DateStarted__c, 
                                                AssignedContactTitle__c, 
                                                ReportedContactTitle__c, 
                                                ExceptionCode__c, 
                                                Exception__r.Name                 
                                                From Job_Attempts__r where Job__r.Id =: JobId order by AttemptSequencePadded__c DESC)
                                       From Job__c where id =: JobId limit 1];
       if(jobList != null && jobList.size() > 0){
             for(Job__c jobObj : jobList){
                jobAttemptListWrapperObj.jobObj = jobObj;
                for(JobAttempt__c jobAttemptObj : jobObj.Job_Attempts__r){
                    JobAttemptEntryWrapper jobAttemptEntryWrapperObj = new JobAttemptEntryWrapper();
                    List<JobChevronTimelineWrapper> jobChevronTimelineWrapperList = new List<JobChevronTimelineWrapper>();
                    jobAttemptEntryWrapperObj.jobAttemptEntry = jobAttemptObj;
                    
                    if(jobAttemptObj.id == jobObj.ActiveJobAttempt__c){ 
                        jobAttemptEntryWrapperObj.isActiveAttempt = TRUE_VALUE;
                    }
                    
                    if(jobAttemptObj.AttemptStatus__c == OPEN_STATUS){
                        jobChevronTimelineWrapperList.add(createChevronTimeline(OPEN_STATUS, BLUE_COLOR, jobAttemptObj.CreatedDate));
                    }
                    else{
                        jobChevronTimelineWrapperList.add(createChevronTimeline(OPEN_STATUS, GREEN_COLOR, jobAttemptObj.CreatedDate));
                    }
                    
                    if(jobAttemptObj.AttemptStatus__c == OPEN_STATUS){
                        jobChevronTimelineWrapperList.add(createChevronTimeline(ASSIGNED_STATUS, GREY_COLOR, jobAttemptObj.DateAssigned__c));
                    }
                    else if(jobAttemptObj.AttemptStatus__c == ASSIGNED_STATUS){
                        jobChevronTimelineWrapperList.add(createChevronTimeline(ASSIGNED_STATUS, BLUE_COLOR, jobAttemptObj.DateAssigned__c));
                    }
                    else {
                        jobChevronTimelineWrapperList.add(createChevronTimeline(ASSIGNED_STATUS, GREEN_COLOR, jobAttemptObj.DateAssigned__c));
                    }
                    
                    if(jobAttemptObj.AttemptStatus__c == ASSIGNED_STATUS || jobAttemptObj.AttemptStatus__c == OPEN_STATUS){
                        jobChevronTimelineWrapperList.add(createChevronTimeline(STARTED_STATUS, GREY_COLOR, jobAttemptObj.DateStarted__c));
                    }
                    else if(jobAttemptObj.AttemptStatus__c == STARTED_STATUS){
                        jobChevronTimelineWrapperList.add(createChevronTimeline(STARTED_STATUS, BLUE_COLOR, jobAttemptObj.DateStarted__c));
                    }
                    else {
                        jobChevronTimelineWrapperList.add(createChevronTimeline(STARTED_STATUS, GREEN_COLOR, jobAttemptObj.DateStarted__c));
                    }
                    
                    if(jobAttemptObj.AttemptStatus__c == ASSIGNED_STATUS || jobAttemptObj.AttemptStatus__c == OPEN_STATUS || jobAttemptObj.AttemptStatus__c == STARTED_STATUS){
                        jobChevronTimelineWrapperList.add(createChevronTimeline(REPORTED_STATUS, GREY_COLOR, jobAttemptObj.DateReported__c));
                    }
                    else if(jobAttemptObj.AttemptStatus__c == REPORTED_STATUS){
                        jobChevronTimelineWrapperList.add(createChevronTimeline(REPORTED_STATUS, BLUE_COLOR, jobAttemptObj.DateReported__c));
                    }
                    else {
                        jobChevronTimelineWrapperList.add(createChevronTimeline(REPORTED_STATUS, GREEN_COLOR, jobAttemptObj.DateReported__c));
                    }
                    
                    jobAttemptEntryWrapperObj.jobChevronTimelineWrapperList = jobChevronTimelineWrapperList;
                    
                    if(jobAttemptEntryWrapperObj.isActiveAttempt == TRUE_VALUE && jobAttemptEntryWrapperList != null && jobAttemptEntryWrapperList.size()>0){        
                        jobAttemptEntryWrapperList.add(0,jobAttemptEntryWrapperObj);
                    }
                    else{
                        jobAttemptEntryWrapperList.add(jobAttemptEntryWrapperObj);
                    } 
                }
                jobAttemptListWrapperObj.jobAttemptEntryWrapperList = jobAttemptEntryWrapperList;
             }
       }
       return jobAttemptListWrapperObj;   
    }
    
    /** 
    * Return JSON data based on the parameter jobId.
    * @param jobLocation : It contains Location object record.
    * @return : Returns string which contains address information in json format.
    */
    @AuraEnabled
    public static String getJsonForAddressLatLongValue(Location__c jobLocation){
        String address = '';
        if(jobLocation.Address__c != null){
            address += jobLocation.Address__c.replaceAll(' ', '%20') +',';
        }

        if(jobLocation.City__c != null){
            address += jobLocation.City__c.replaceAll(' ', '%20') +',';
        }

        if(jobLocation.State__c != null){
            address += jobLocation.State__c.replaceAll(' ', '%20') +',';
        }

        if(jobLocation.Country__c != null){
            address += jobLocation.Country__c.replaceAll(' ', '%20') +',';
        }

        if(jobLocation.PostalCodeName__c != null){
            address += jobLocation.PostalCodeName__c.replaceAll(' ', '%20');
        }
        
        String url = 'http://nominatim.openstreetmap.org/search/' + address + '?format=json&polygon=1&addressdetails=1';
        Http httpObj = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(url );
        req.setMethod('GET');
        HttpResponse res;
        res = httpObj.send(req);
        String responseAfterCall = res.getBody();
        return responseAfterCall;
    }
    
    /** 
    * Return Job Chevron Timeline based on the parameter title, color and timelineDate.
    * @param title : It contains job Chevron timeline title as a string type.
    * @param color : It contains job Chevron timeline color as a string type.
    * @param timelineDate : It contains job Chevron timeline date as a datetime type.
    * @return : Returns JobChevronTimelineWrapper instance.
    */
    private static JobChevronTimelineWrapper createChevronTimeline(String title, String color, Datetime timelineDate) {
        JobChevronTimelineWrapper jobChevronTimelineWrapperObj = new JobChevronTimelineWrapper();
        jobChevronTimelineWrapperObj.title = title;
        jobChevronTimelineWrapperObj.color = color;
        jobChevronTimelineWrapperObj.timelineDate = timelineDate;
        
        return jobChevronTimelineWrapperObj;
     }
     
     /** 
    * Return job materials List based on the parameter jobId.
    * @param jobId : It contains id of Job record.
    * @return : Returns List of JobMaterial records.
    */
    @AuraEnabled
    public static List<JobMaterial__c> getJobMaterialList(String jobId) { 
        List<JobMaterial__c> jobMaterialList = new List<JobMaterial__c>();
        
        jobMaterialList = [Select  Id, 
                                   Name, 
                                   MaterialName__c, 
                                   MaterialQuantity__c
                                   From JobMaterial__c where Job__c =: jobId limit 50000];
        
        if(jobMaterialList != null && jobMaterialList.size() > 0){
            return jobMaterialList;
        }                           
        return null;
    }
}