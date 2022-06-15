public without sharing class TestSecurityClass {

//public variables 
    
public boolean showTable{get;set;}
public boolean showDetail{get;set;}
public boolean showCode{get;set;}

public SelectOption[] accessibleClasses { get; set; }

public String[] selectedClasses { get; set; }

//Private variables 
public string baseURL{ get; set; }

public List<classWrapper> classlist{get;set;}

public List<methodWrapper> methodlist{get;set;}

//public methods 
public PageReference scanSelectedClasses() {
    
    if(this.selectedClasses.isEmpty()) {
        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Info, 'Please select at least one class.');
        ApexPages.addMessage(msg);
    }
    else {
        try {
        
            Map<id,apexClass> apexClassSelectedDetailsMap = new Map<Id,apexClass>([  select id,Name, ApiVersion, Status, IsValid, Body, LastModifiedBy.UserName from apexClass where name in:this.selectedClasses ]);
            
            Set<id> apexClassIdSet = apexClassSelectedDetailsMap.keyset();
            
            Map<Id,VisibilityProfileDetailsOfClass> classProfileDetails = getSetupEntityAccesses(apexClassIdSet);
            Map<Id,Record> classToolingAPIDetails = getToolingAPIResponseData(apexClassIdSet);
            Map<Id,ParsedClass> parsedClasses = getParsedClassMap(apexClassSelectedDetailsMap.values());
            
            for(Id apexClassID:apexClassIdSet){

                classlist.add(new classWrapper(classProfileDetails.get(apexClassID),classToolingAPIDetails.get(apexClassID),parsedClasses.get(apexClassID) ));
            }
        }
        catch(Exception e) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Soemthing went wrong: ' + e.getMessage());
            ApexPages.addMessage(msg);
        }
     }
     return null;
}


public class ClassWrapper{
    
    public string toolingAPIResult{get;set;}
    public string parserResult{get;set;}
    public string sOQLResult{get;set;}

    public string className{get;set;}
    public string runMode{get;set;}

    public boolean isHavingAuraEnabledMethod{get;set;}
    public List<profileDetailWithLink> communityUserProfile{get;set;}
    public List<profileDetailWithLink> guestUserProfile{get;set;}

    public boolean isInsufficientError{get;set;}
    public boolean isFLSError{get;set;}
    public boolean isXSSError{get;set;}
    public boolean isCRUDError{get;set;}
    public boolean isSOQLError{get;set;}
    public boolean isSOQLInjectionError{get;set;}
    public boolean isHardcodedError{get;set;}

    public List<methodWrapper> methodList{get;set;}
    public string severity{get;set;}
    public List<ErrorDetails> errorDetails{get;set;}

    public classWrapper(VisibilityProfileDetailsOfClass visiblity, Record toolingRecord , ParsedClass classRecord){
        //this.toolingAPIResult = ''+toolingRecord;
        //this.SOQLResult = ''+visiblity;
        //this.parserResult = ''+classRecord;

        //this.runMode = 
        this.isHavingAuraEnabledMethod=false;
    
        this.communityUserProfile = new List<profileDetailWithLink>();
        this.guestUserProfile = new List<profileDetailWithLink>();
        this.methodList = new List<methodWrapper>();
        this.errorDetails = new List<errorDetails>();

        if(visiblity!=null){
            this.communityUserProfile = visiblity.communityProfiles;
            this.guestUserProfile = visiblity.guestUserProfiles;
        }
        this.className = toolingRecord.Name;
        this.runMode = (string.isblank(classRecord.sharing)?'Not Specified':classRecord.sharing ); 

        for(ClassMember member:classRecord.members){
            for(Method methodRecord:toolingRecord.symbolTable.methods){
                if(methodRecord.name == member.name){
                    MethodWrapper methodWrapperRecord = new methodWrapper(member,methodRecord);
                    this.isHavingAuraEnabledMethod = this.isHavingAuraEnabledMethod || methodWrapperRecord.isAuraEnabledMethod;
                    if(methodWrapperRecord.errorDetails!=null){
                        this.errorDetails.addAll(methodWrapperRecord.errorDetails);
                    }
                    this.methodList.add(methodWrapperRecord);
                }
            }

        }
    }
}

 
public class MethodWrapper{

    public string dmlOperation{get;set;}
    public boolean isAuraEnabledMethod{get;set;}
    public string severity{get;set;}
    public List<ErrorDetails> errorDetails{get;set;}
    public ClassWrapper classDetails{get;set;}
    public boolean isInsufficientError{get;set;}
    public boolean isFLSError{get;set;}
    public boolean isXSSError{get;set;}
    public boolean isCRUDError{get;set;}
    public boolean isSOQLError{get;set;}
    public boolean isSOQLInjectionError{get;set;}
    public boolean isHardcodedError{get;set;}
    public string name {get;set;}
    public list<TestSecurityClass.Annotations> annotations{get;set;}
    public list<TestSecurityClass.Parameter> parameters{get;set;}


    public MethodWrapper(ClassMember member, Method methodRecord){
        Set<String> annotationsSet =new Set<String>();
        if(methodRecord!=null && methodRecord.annotations!=null){
            for(Annotations ann:methodRecord.annotations){
                annotationsSet.add(ann.name);
            }
            System.debug(annotationsSet);
            this.isAuraEnabledMethod = annotationsSet.contains('AuraEnabled');
        }
        this.name = methodRecord.name;
        this.annotations = methodRecord.annotations;
        this.parameters = methodrecord.parameters;
    }
}

public class ErrorDetails{

    public string errorDescription{get;set;}
    public integer startLineNUmber{get;set;}
    public string error{get;set;}
}

public Map<Id,ParsedClass> getParsedClassMap(List<ApexClass> apexClassList){

    Map<Id,ParsedClass> parsedClasses = new Map<id,ParsedClass>();
    
    ApexParser parser = new ApexParser();
    
    for(ApexClass originalClass : apexClassList) {
                                                            
        ParsedClass parsedClass = parser.parse(originalClass);      
        parsedClasses.put(originalClass.id, parsedClass);
    }
    return parsedClasses;
}

private Map<Id,Record> getToolingAPIResponseData(Set<Id> apexClassId){
    Map<Id,Record> toolingAPIResponseMap = new map<Id,Record>();
    String classSetInString = '(\''+String.join(new list<id>(apexClassId),'\',\'')+'\')';
    //getting Data from tooling api 
    SecurityScannerWrapper wrapperResponse= this.restGet( baseURL +
                                                                                 '/services/data/v47.0/tooling/query?'+
                                                                                 'q=Select+Id,Name,SymbolTable+From+ApexClass+where+NamespacePrefix+=\'\'+AND+ID+IN+'+classSetInString+'+ORDER+BY+Name',
                                                                                 'GET', UserInfo.getSessionId() );
    System.debug(wrapperResponse);
    
    for(Record classRecord: wrapperResponse.Records){
        toolingAPIResponseMap.put(classRecord.id , classRecord);
    }
    return toolingAPIResponseMap;
}
//public classes
public class SecurityScannerWrapper
{
    public final List<Record> records{get;set;}
}

public class Record
{
    public String Id;
    public string Name;
    public  final SymbolTable symbolTable;
}
public class SymbolTable
{
    public final list<String> modifiers{get;set;}
    public final List<Method> methods{get;set;}
}


public class Annotations {
    public String name{get;set;}
}

public class Method
{
    public final String name{get;set;}
    public final List<Parameter> parameters{get;set;}
    public final list<Annotations> annotations{get;set;}
}
public class Parameter
{
    public final String name{get;set;}
    public final String type{get;set;}
}
public static SecurityScannerWrapper parse(String json) {
    return (SecurityScannerWrapper) System.JSON.deserialize(json, SecurityScannerWrapper.class);
}



public class ProfileDetailWithLink{
    public String name{get;set;}
    public String profileId{get;set;}
           
}

//private classes 

private class Constants{
      public final SEt<String> communityUserLicence= new set<String>{'Customer Community Plus Login',
        'Customer Community', 'Partner Community', 'External Apps', 'External Identity', 'Channel Account'};
      public final SEt<String> externalUserLicence= new set<String>{'Guest User License'};
      
      public set<String> getCommunityUserLicence(){
          return communityUserLicence;
      }
}


private class VisibilityProfileDetailsOfClass{

    private List<profileDetailWithLink> communityProfiles;
    private List<profileDetailWithLink> guestUserProfiles;
    
    VisibilityProfileDetailsOfClass(){
        this.communityProfiles = new List<profileDetailWithLink>();
        this.guestUserProfiles = new List<profileDetailWithLink>();
    }
    
    public void addProfile(string name , id profileId, boolean isGuest){
        profileDetailWithLink pdwl = new profileDetailWithLink();
        pdwl.name = name;
        pdwl.profileId= profileId;
        
        if(isGuest){
            guestUserProfiles.add(pdwl);
        }
        else{
            communityProfiles.add(pdwl);
        }
    }
}

//Private methods 

public Map<Id,VisibilityProfileDetailsOfClass> getSetupEntityAccesses(Set<Id> apexClassId) {
    Map<Id,VisibilityProfileDetailsOfClass> mapClassesToBeReturned = new Map<Id,VisibilityProfileDetailsOfClass>();
    //getting information of 2 UserLicense -> Customer Community Plus Login and  Guest User License 
    for(SetupEntityAccess seAccess : [
        SELECT SetupEntityId, ParentId,Parent.ProfileId,Parent.Profile.Name  , Parent.Profile.UserLicense.name
        FROM SetupEntityAccess
        WHERE Parent.Profile.Name != null AND  (Parent.Profile.UserLicense.name in ('Customer Community Plus Login','Customer Community', 'Partner Community', 'External Apps', 'External Identity', 'Channel Account')
                                                OR Parent.Profile.UserLicense.name = 'Guest User License') AND SetupEntityId in: apexClassId 
    ]){
        
        if(!mapClassesToBeReturned.containsKey(seAccess.SetupEntityId )){
            VisibilityProfileDetailsOfClass profileList =  new VisibilityProfileDetailsOfClass();
            mapClassesToBeReturned.put(seAccess.SetupEntityId , profileList);
        }
        if(seAccess.Parent.Profile.UserLicense.name == 'Customer Community Plus Login' ||
            seAccess.Parent.Profile.UserLicense.name == 'Customer Community' ||
            seAccess.Parent.Profile.UserLicense.name == 'External Apps' ||
            seAccess.Parent.Profile.UserLicense.name == 'External Identity' ||
            seAccess.Parent.Profile.UserLicense.name == 'Channel Account'){
            mapClassesToBeReturned.get(seAccess.SetupEntityId).addProfile(seAccess.Parent.Profile.name,seAccess.Parent.ProfileId,false);
        }
        else if(seAccess.Parent.Profile.UserLicense.name == 'Guest User License'){
            mapClassesToBeReturned.get(seAccess.SetupEntityId).addProfile(seAccess.Parent.Profile.name,seAccess.Parent.ProfileId,true);
        }
        
    }
    //return map of (SetupEntityId and profile List)
    return mapClassesToBeReturned ;
}

 
private String instanceUrl() {
    String result = null;

    List<String> fragments = URL.getSalesforceBaseUrl().getHost().split('\\.');

    if(fragments.size() == 3) {
        result = fragments[0]; // Note: Apex URL: NA14.salesforce.com
    }
    else if(fragments.size() == 5) {
        result = fragments[1]; // Note: Visualforce URL: mydomain.NA14.visual.force.com
    }

    //return 'https://'+result + '.salesforce.com';
    return URL.getSalesforceBaseUrl().toExternalform();
}

private SecurityScannerWrapper restGet(String endPoint, String method, String sid) {
    Http h = new Http();
    HttpRequest hr = new HttpRequest();
    hr.setHeader('Authorization', 'Bearer ' + sid);
    hr.setTimeout(60000);
    hr.setEndpoint(endPoint);
    hr.setMethod(method);
    HttpResponse r = h.send(hr);
    return SecurityScannerWrapper.parse(r.getBody());
}

public class ApexParser {
    private final Pattern CLASSHEADER = Pattern.compile('(?i)(@isTest\\s+private|public|global)\\s*(with\\s+sharing|without\\s+sharing)*\\s*(static|virtual|abstract)*\\s*(with\\s+sharing|without\\s+sharing)*\\s*(class|interface|enum)\\s+(\\w+)(\\s+(extends|implements)\\s+(\\w+(\\s*,\\s*\\w+)*))*\\s*\\n*\\{');
    private final Pattern CLASSMEMBER = Pattern.compile('(?i)(static testmethod|@isTest\\s+private|public|global|private)\\s*\\b(static|abstract|virtual)?\\b\\s*(((?!class|interface)\\w+)(<\\b[^>]*>)*)\\s*(\\w+)(\\((.*?)\\))*\\s*\\n*\\{');
    private final String COMMENT_LITERAL = '/\\*([^*]|[\\r\\n]|\\*+(?:[^*/]|[\\r\\n]))*\\*+/|//.*|\'.*\'';
    private final String EMPTY_LINE = '\n\\s*\n';
    private final Pattern BRACES = Pattern.compile('\\{|\\}');
    
    private String cleanedSource;
    private ParsedClass parsed;
    
    public ParsedClass parse(ApexClass originalClass) {
        this.cleanedSource = getCleaned(originalClass.Body); 
        this.parsed = new ParsedClass();
        
        parseHeader();
        parseAndRemoveInnerClasses();
        parseMembers();
         
        return parsed;
    }
    

    private ParsedClass parse(String cleanedSource) {
        this.cleanedSource = cleanedSource;
        this.parsed = new ParsedClass();
        
        parseHeader();
        parseMembers();
         
        return parsed;
    }
    
    
    // PRIVATE METHODS
    
        
    private String getCleaned(String original) {
        String cleaned = original.replaceAll(COMMENT_LITERAL, '');
        cleaned = cleaned.replaceAll(EMPTY_LINE, '\n'); 
        return cleaned;
    }
    
    
    private void parseHeader() {
        Matcher classMatch = CLASSHEADER.matcher(this.cleanedSource);
   
        // Parse top class header
        if(classMatch.find()) {
            this.parsed.name = extractName(classMatch);
            this.parsed.visibility = extractClassVisibility(classMatch);
            this.parsed.scope = extractClassScope(classMatch);
            this.parsed.type = extractClassType(classMatch);
            this.parsed.sharing = extractSharing(classMatch);
            this.parsed.doesImplement = extractDoesImplement(classMatch);
            this.parsed.interfaces = extractImplementedInterfaces(classMatch);
            this.parsed.doesExtend = extractDoesExtend(classMatch);
            this.parsed.superName = extractSuperClass(classMatch);
            this.parsed.body = getBlockStartingWith(classMatch, this.cleanedSource);
        }
        else {
            throw new ParsingException();
        }
    }
    
    
    private String extractName(Matcher classMatch) {
        return classMatch.group(6);
    }
    
    
    private String extractClassVisibility(Matcher classMatch) {
        String g = classMatch.group(1);
        return (g != null) ? g : '';
    }
    
    private String extractClassScope(Matcher classMatch) {
        String g = classMatch.group(3);
        return (g != null) ? g : '';
    }
    
    private String extractSharing(Matcher classMatch) {
        String first = classMatch.group(2);
        first = (first != null) ? first : '';
        String second = classMatch.group(4);
        second = (second != null) ? second : '';
        return (first + second);
    }
      
    private String extractClassType(Matcher classMatch) {
        String g = classMatch.group(5);
        return (g != null) ? g : '';
    }
    
    private Boolean extractDoesImplement(Matcher classMatch) {
        String g = classMatch.group(8);
        return (g != null) ? g == 'implements' : false;
    }
    
    private List<String> extractImplementedInterfaces(Matcher classMatch) {
        List<String> results = new List<String>();
        String g = classMatch.group(9);
        
        if(g != null) { 
            for(String part : g.split('\\,')) {
                results.add(part.trim());
            }
        }
        
        return results;
    }
    
    private Boolean extractDoesExtend(Matcher classMatch) {
        String g = classMatch.group(8);
        return (g != null) ? g == 'extends' : false;
    }
    
    private String extractSuperClass(Matcher classMatch) {
        String g = classMatch.group(9);
        return (g != null) ? g : '';   
    } 

        
    private void parseMembers() { 
        Matcher memberMatch = CLASSMEMBER.matcher(this.cleanedSource);
        
        while(memberMatch.find()) {
            ClassMember member = new ClassMember();
            
            member.visibility = extractMemberVisibility(memberMatch);
            member.scope = extractMemberScope(memberMatch);
            member.returnType = extractReturnType(memberMatch);
            member.name = extractMemberName(memberMatch);
            member.parameters = extractParameters(memberMatch);
            member.body = getBlockStartingWith(memberMatch, this.cleanedSource);
            
            parsed.members.add(member);
        }
    }
    
    
    private void parseAndRemoveInnerClasses() { 
        Matcher innerClassHeader = CLASSHEADER.matcher(this.parsed.body);
        
        // For each matches class
        while(innerClassHeader.find()) {
            String innerClassBody = getBlockStartingWith(innerClassHeader, this.parsed.body);
            String wholeInnerClass = innerClassHeader.group() + innerClassBody.substring(1);
            
            ParsedClass innerClass = new ApexParser().parse(wholeInnerClass);
            parsed.innerClasses.add(innerClass);
                    
            // Remove innerclass source from outer class' body to not interfere with member matching
            this.cleanedSource = this.cleanedSource.remove(wholeInnerClass);
        } 
    }   
    
    
    public String extractMemberVisibility(Matcher memberMatch) {
        String g = memberMatch.group(2);
        return (g != null) ? g : '';
    }
    
    public String extractMemberScope(Matcher memberMatch) {
        String g = memberMatch.group(3);
        return (g != null) ? g : '';
    }
    
    
    private String extractReturnType(Matcher memberMatch) {
        return memberMatch.group(4);
    }
    
    
    private String extractMemberName(Matcher memberMatch) {
        return memberMatch.group(6);
    }
    
    
    private String extractParameters(Matcher memberMatch) {
        String g = memberMatch.group(7);
        return (g != null) ? g : '';
    }
    
    
    /**
     * Returns block for a given header match and a context string
     * 
     * Note: Regexp is only able to match header but not whole block. Counting braces is used to find block end
     */
    private String getBlockStartingWith(Matcher blockStartMatch, String context) {
        Integer blockStart = blockStartMatch.end()-1;
        Integer blockEnd = blockStart;
        Integer braceCounter = 0;
        
        Matcher braceMatch = BRACES.matcher(context.substring(blockStart));
        do {
            braceMatch.find();
            braceCounter = (braceMatch.group() == '{') ? braceCounter + 1 : braceCounter -1;
            blockEnd = braceMatch.end();
        } while(braceCounter > 0);
        
        return context.substring(blockStart, blockStart+blockEnd);
    }
}

    
public class ParsedClass {
    public String visibility { get; private set; }
    public String scope { get; private set; }
    public String type { get; private set; }
    public String sharing { get; private set; }
    public String name { get; private set; }
    public Boolean doesImplement { get; private set; }
    public List<String> interfaces { get; private set; }
    public Boolean doesExtend { get; private set; }
    public String superName { get; private set; }
    public String body { get; private set; }
    public List<ClassMember> members { get; private set; }
    public List<ParsedClass> innerClasses { get; private set; }
    
    ParsedClass() {
        this.members = new List<ClassMember>();
        this.innerClasses = new List<ParsedClass>();
        this.doesImplement = false;
        this.doesExtend = false;
    }
} 

public class ClassMember {
    public String visibility { get; private set; }
    public String scope { get; private set; }
    public String returnType { get; private set; }
    public String name { get; private set; }
    public String parameters { get; private set; }
    public String body { get; private set; }
    
    ClassMember() {}
}
    
public class ParsingException extends Exception {}  


//Constructor
public TestSecurityClass() {
    
    // Init sobject Multiselect list
    this.accessibleClasses = new List<SelectOption>();
    this.selectedClasses = new List<String>();

    for(ApexClass c : [SELECT Name FROM ApexClass WHERE Status = 'Active' AND NamespacePrefix = '' AND (NOT NAME LIKE '%Test') AND (NOT NAME = 'TestSecurityClass') ORDER BY NamespacePrefix, Name]) {
        this.accessibleClasses.add(new SelectOption(c.Name, c.Name));
    }
    classlist = new List<classWrapper> ();
    baseURL = this.instanceUrl();
    
}
}