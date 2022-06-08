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

Integer rollnumber1 = 100000098;
Integer rollnumber2 = 100000097;
Integer rollnumber3 = 100000096;
System.debug('This is print1: '+rollnumber1+'\tThis is print2: '+ rollnumber2+'\tThis is print3: '+ rollnumber3);
// Ordered Collection 
List<Integer> listrollNumber2 = new List<Integer> {89,90,55};
System.debug(listrollNumber2);

List<Integer> listrollNumber3 = new List<Integer> ();
listrollNumber3.add(25);
listrollNumber3.add(1);
listrollNumber3.add(3);
listrollNumber3.add(6);
System.debug(listrollNumber3);


System.debug(listrollNumber3.get(1));
System.debug(listrollNumber3.get(0));
System.debug(listrollNumber3.get(2));



// add item at a position and shift the items

listrollNumber3.add(0, 44);
System.debug(listrollNumber3);

//remove an item from the list

listrollNumber3.remove(2);
System.debug(listrollNumber3);
System.debug(listrollNumber3.size());



//update an item in the list

listrollNumber3.set(2, 99);

System.debug(listrollNumber3.size());
System.debug(listrollNumber3);

//Clear a list

listrollNumber3.clear();
System.debug(listrollNumber3.size());
System.debug(listrollNumber3);
