// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

string tempvar = 'Enter_your_name_here';
System.debug('Hello World!');
System.debug('My name is ' + tempvar);


String greeting = 'Hello Warald';
System.debug(greeting);

Boolean isawake = true;
System.debug(isawake);

Integer rollNumber = 44;
System.debug(rollNumber);

Long LongNumber = 444444444L;
System.debug(LongNumber);

Decimal Devc = 10.2;
System.debug(Devc);

Double lightspeed = 874/953;
System.debug(lightspeed);

Date tday = Date.newInstance(2022, 05, 31);
System.debug(tday);

Time ctime = Time.newInstance(00, 32, 0, 0);
System.debug(ctime);

Datetime cudTime= Datetime.newInstance(2022, 05, 31, 00, 32, 0);
System.debug(cudTime);

String strnonCap = 'jissy is awesome';
System.debug('Actual string: '+strnonCap + '\nCapitalized String: '+ 
strnonCap.capitalize()+' Does it contain awesome? '+strnonCap.contains('awesome')+'\nCompletely Captialize: '
+strnonCap.toUpperCase()+'\nLets lowernow: '+strnonCap.toLowerCase()
);


