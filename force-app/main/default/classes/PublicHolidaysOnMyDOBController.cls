/*  @description: The class serves as a controller to handle the functionality of saving and retrieving ID information along with public holidays 
* data for a given ID number. It interacts with an external API to obtain holiday information and stores the relevant details in Salesforce 
* custom objects.
* @author: Hishmat - 07th June,2023
*/ 

public  without sharing class PublicHolidaysOnMyDOBController {
    
    /*The method saveIDInformation receives an ID number as input and extracts its date of birth, gender, and citizenship information.
*  It then retrieves an existing history record for the ID number, increments the search counter, and creates or updates a new record with
*  the extracted details.
*  */
    @AuraEnabled
    public static  List<Map<String, Object>> getHolidays(String saIdNumber) {
        
        try{
            
            //        Date dateOfBirth = date.parse(idNumber.substring(2, 4)+'/'+ idNumber.substring(4, 6)+'/19'+idNumber.substring(0, 2));

            
            // Extracting the year (first two digits), month (next two digits), and day (last two digits) from the 'saIdNumber'.
            
            String monthDigits = saIdNumber.substring(2, 4);
            String dayDigits = saIdNumber.substring(4, 6);
            String yearDigits = saIdNumber.substring(0, 2);
            
            // Concatenating the extracted year, month, and day along with '19' to create the complete date in the format 'YYYY/MM/DD'.
            // Note: This assumes all dates are in the 1900s. For dates in the 2000s, use '20' instead of '19'.
            String completeDate = monthDigits + '/' + dayDigits + '/19' + yearDigits;
            
            // Parsing the 'completeDate' into a Date object.
            Date dateOfBirth = Date.parse(completeDate);
            
            //Extract the  gender
            String gender = integer.valueof(saIdNumber.substring(6, 10)) < 5000 ? 'Female' : 'Male';
            //Extract the citzenship
            Boolean isCitizen = integer.valueof(saIdNumber.substring(10, 11)) == 0 ? true : false;
            
            list<ID_Search_Log__c> lstIDSearch=[select Id, SA_ID_Number__c,Search_Count__c  from ID_Search_Log__c where SA_ID_Number__c =:saIdNumber ];
            Decimal Counter=0;
            ID_Search_Log__c rcdIDSL = new ID_Search_Log__c ();
            
            if(lstIDSearch.size()>0){
                Counter=lstIDSearch[0].Search_Count__c;
                rcdIDSL.Id = lstIDSearch[0].Id;
            }
            
            //Increment the counter
            Counter++; 
            
            rcdIDSL.SA_ID_Number__c = saIdNumber;
            rcdIDSL.SA_Citizen__c = isCitizen;
            rcdIDSL.Date_of_Birth__c  = dateOfBirth;
            rcdIDSL.Gender__c  = gender;
            rcdIDSL.Search_Count__c = Counter;
            rcdIDSL.Search_Date_Time__c = datetime.now();
            
            
            List<Map<String, Object>> response = hitAPI(String.valueOf(dateOfBirth.year())) ;
            upsert rcdIDSL ;
            return response;
        }
        catch(exception ex){
            system.debug(ex.getCause());
            system.debug(ex.getMessage()+' - '+ex.getStackTraceString());

            return  null;//ex.getMessage()+''+ex.getStackTraceString();
        }
    }
    
    //Getting data from API
    public static List<Map<String, Object>> hitAPI(String year) {
        try{
            List<Map<String, Object>> publicHolidays = new List<Map<String, Object>>();
            
            // Get the base url and endpoint from metadata and make sure we have to this in remote setting
            
            String endPoint = '';
            
            //Query for endpoint from metadata
            List<Calendarific__mdt> configRecords = [SELECT API_Key__c, Base_URL__c FROM Calendarific__mdt	];
                        
            // Assuming you have only one custom metadata record, you can access:
            if (!configRecords.isEmpty()) {
                Calendarific__mdt config = configRecords[0];
                
                String baseUrl = config.Base_URL__c;
                String apiKey = config.API_Key__c;
                
                endPoint = baseUrl+'api_key='+apiKey+'&country=ZA&year='+year;
                
            }
            
            system.debug('endPoint>'+endPoint);
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endPoint);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
         
            system.debug(response.getBody());
            
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                Map<String, Object> responseMap = (Map<String, Object>) result.get('response');
                
                List<Object> holidaysList = (List<Object>) responseMap.get('holidays');
                
                for (Object holidayObj : holidaysList) {
                    Map<String, Object> holidayMap = (Map<String, Object>) holidayObj;
                    
                    if(holidayMap.get('primary_type') == 'Public Holiday'){
                        
                        Map<String, Object> dateMap = (Map<String, Object>) holidayMap.get('date');
                        Map<String, Object> datetimeMap = (Map<String, Object>) dateMap.get('datetime');
                        Map<String, Object> publicHoliday = new Map<String, Object>();
                        
                        
                        publicHoliday.put('name', holidayMap.get('name'));
                        publicHoliday.put('description', holidayMap.get('description'));
                        publicHoliday.put('date', dateMap.get('iso')); 
                        
                        publicHoliday.put('primary_type', holidayMap.get('primary_type'));
                        publicHolidays.add(publicHoliday);
                    }
                } 
            }   
            return publicHolidays;
        }
        catch(exception ex){
            system.debug(ex.getCause());
            system.debug(ex.getMessage());
            return null;
        }
    }
    
    
}