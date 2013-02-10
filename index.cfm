<html>
<head>
<link rel="stylesheet" type="text/css" href="fullcalendar.css"/>
<script language="javascript" src="jquery-1.8.1.min.js"></script>
<script language="javascript" src="jquery-ui-1.8.23.custom.min.js"></script>
<script language="javascript" src="jquery.icalendar.js"></script>
<script language="javascript" src="fullcalendar.js"></script>
<script language="javascript" src="json2.js"></script>
<script language="javascript" src="date.js"></script>

<script language="javascript">
$(document).ready(function(){
/* 	$.ajax({
			url:'2445AllExamples1.ics',
			type:'post',
			dataType:'html',
			cache:false,
			success: function(data){
				var ics = $.icalendar.parse(data);
				$("#calendar").text(JSON.stringify(ics));
			},
			error: function(xhr){
				$("body").html(xhr.responseText);
			}		
		}); */
	$("#calendar").fullCalendar({
		/* events: function(start, end, callback) {
			$.ajax({
				url:'2445AllExamples1.ics',
				type:'post',
				dataType:'html',
				cache:false,
				success: function(data){
					var ics = $.icalendar.parse(data);
					var events = [], e = ics.vevent;
					if($.isArray(e)){
						for(var i=0; i < e.length; i++){
	                		events.push({
	                			title: e.summary,
	                			start: e.dtstart._value            
	               			 });
	               		}
					}else{
						events.push({
	                		title: e.summary,
	                		start: e.dtstart._value
	               		 });
					}
	                callback(events);
				},
				error: function(xhr){
					$("body").html(xhr.responseText);
				}		
			});
	    } */
	    events: 'getEvents.cfm'
	});	 
	
});
</script>
</head>
<body>
<div id="calendar">
</body>
</html>


<!--- <cfdump var="#Parse.unfoldLines(data)#" /> --->
