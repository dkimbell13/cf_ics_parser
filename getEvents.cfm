<cfobject component="Parse" name="parse">
<cffile action="read" file="#ExpandPath('.')&'/2445AllExamples.ics'#" variable="data">
<cfoutput>#Parse.init(data)#</cfoutput>