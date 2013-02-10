<cfscript>
component output=false{
	property name='timezones';
	property name='events';
	
	function init(content){
		events = [];
		timezones = {};
		var lines = unfoldLines(content);
		return parseLines(1,lines);
	}
	
	function unfoldLines(content) {

		var lines = ListToArray(REReplace(content,"#chr(13)##chr(10)#","#chr(10)#","all"),"#chr(10)#",false);
		for (var i = ArrayLen(lines) - 1; i > 0; i--) {
			var matches = REFind("^\s(.*)$",lines[i],1,true);
		 	if (matches.pos[1] GT 0) {
				lines[i - 1] &= Mid(lines[i],matches.pos[1],matches.len[1]);
				lines[i] = '';
			} 
		}		
		return lines;
	}
	
	function parseLines(index, lines){
			
		var inEvent = false;
		var inTimezone = false;
		var event = [];
		var timezone = [];

		for(var i=index; i<=ArrayLen(lines); i++){
			//if(REFind("END",lines[i]) GT 0) writedump("END: "&REFind("END",lines[i]));
			if(ReFind("END",lines[i]) EQ 1){
				var action = ListToArray(lines[i],':');
				switch("#Trim(action[2])#"){
					case "VEVENT":
						inEvent = false;
						processEvent(event);
						event = [];
						break;
					case "VTIMEZONE":
						inTimezone = false;
						processTimezone(timezone);
						timezone=[];
						break;
					default:break;
				}
			}
			//if(REFind("START",lines[i]) GT 0) writedump("START: "&REFind("START",lines[i]));
			if(ReFind("BEGIN",lines[i]) EQ 1){
				var action = ListToArray(lines[i],':');
				switch("#Trim(action[2])#"){
					case "VEVENT":
						inEvent = true;
						continue;
						break;
					case "VTIMEZONE":
						inTimezone = true;
						continue;
						break;
					default:break;
				}
			}
			
			if(inEvent){
				ArrayAppend(event, lines[i]);
			}
			
			if(inTimezone){
				ArrayAppend(timezone, lines[i]);
			}
		}
		
		return fullcalendar(events);
	}
	
	function fullcalendar(events){
		var fcevents = [];
		for(var i=1;i<=ArrayLen(events);i++){
			if(StructKeyExists(events[i],'rrule')){
				var count = 0;
				var dateAddValue = 1;
				var dateAddPart = 'd';
				for(var key in events[i].rrule){
					switch('#key#'){
						case "freq":
							switch('#events[i].rrule[key]#'){
								case "DAILY":
									count = 365;
									dateAddPart = 'd';
									break;
								case "WEEKLY":
									count = 52;
									dateAddPart = 'ww';
									break;
								case "MONTLY":
									count = 12;
									dateAddPart = 'm';
									break;
								case "YEARLY":
									count = 10;
									dateAddPart = 'yyyy';
									break;
								default:break;
							}
							break;
						case "interval":
							dateAddValue = events[i].rrule[key];
							break;
						case "count":
							count = events[i].rrule[key];
							break;
						default:break;
					}
				}
				if(StructKeyExists(events[i].rrule,'count')){
					count = events[i].rrule.count;	
				}else count = Round(count/dateAddValue) + 1;
				
				var dt = events[i].dtstart._value;
				for(var j=1; j<=count;j++){
					var event = {
						"title" = events[i].summary,
                		"start" = dt
					};
					
					ArrayAppend(fcevents,event);
					if(count > 1) dt = DateAdd(dateAddPart,dateAddValue,dt);
				}
			}
		}	
/* 		writedump(local);
		writedump(fcevents); abort; */
		return SerializeJSON(fcevents,true);
	}
	
	function processEvent(lines){
		var event = {};
		for(var i=1; i<=ArrayLen(lines); i++){
			if((Find("DTSTART",lines[i]) GT 0) OR (Find("DTEND", lines[i]) GT 0)){
				var dtinfo = {};
				element = ListToArray(lines[i],';',false);
				var dts = ListToArray(element[2],':',false);
				dtinfo['timezone'] = ListToArray(dts[1],'=',false)[2];
				dtinfo['_value'] = checkDate(dts[2],dtinfo.timezone);
				element[2] = dtinfo;
			}else{
				element = ListToArray(lines[i],':',false);
			}
			if(ArrayLen(element) GT 0){ 
				if(element[1] EQ "RRULE"){
					var rules = {};
					var rule = ListToArray(element[2],';',false);
					for(var j=1;j<=ArrayLen(rule);j++){
						var value = ListToArray(rule[j],'=',false);
						rules[LCase(value[1])] = value[2];
					}
					element[2] = rules;
				}
				event[LCase(element[1])] = element[2];
			}
		}
		
		ArrayAppend(events,event);
	}
		
	function checkDate(value, tz) {
		var DATETIME = "^(\d{4})(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)(Z?)$";
		var DATEONLY = "^(\d{4})(\d\d)(\d\d)$";
		var DATETIME_RANGE = "^(\d{4})(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)(Z?)\/(\d{4})(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)(Z?)$";
		
		var matches = REfind(DATETIME,value,1,true);
		if (matches.pos[1] GT 0) {
			return makeDate(value,matches,tz);
		}
		matches = REfind(DATETIME_RANGE,value,1,true);
		if (matches.pos[1] GT 0) {
			return {'start' = makeDate(value, matches, tz), 'end' = makeDate(value, matches.subList(7), tz)};
		}
		matches = REfind(DATEONLY,value,1,true);
		if (matches.pos[1] GT 0) {
			return makeDate(value, matches, tz, true);
		}
		return value;
	}
	
	function makeDate(datestring, dtparts, tz, dateonly=false){
		try{
			var dte = {};
			var yr = Mid(datestring,dtparts.pos[2],dtparts.len[2]);
			var mnth = Mid(datestring,dtparts.pos[3],dtparts.len[3]);
			var dy = Mid(datestring,dtparts.pos[4],dtparts.len[4]);
			
			var hr = (dateonly)? '0':Mid(datestring,dtparts.pos[5],dtparts.len[5]);
			var mn = (dateonly)? '0':Mid(datestring,dtparts.pos[6],dtparts.len[6]);
			var sec = (dateonly)? '0':Mid(datestring,dtparts.pos[7],dtparts.len[7]);
			var zz = (dateonly)? '':Mid(datestring,dtparts.pos[8],dtparts.len[8]);
			if(StructKeyExists(timezones,'tz'))	
				return DateAdd('n',timezones['#tz#'].tz_offset,CreateDateTime(yr,mnth,dy,hr,mn,sec));
			else return CreateDateTime(yr,mnth,dy,hr,mn,sec);
		}catch(any e){
			writedump(variables);
			writedump(local);
			abort;
		}
	}
	
	
	function processTimezone(tzarr){
		var TZ_OFFSET = "^([+-])(\d\d)(\d\d)$";
		
		var tz = {};
		var inside = false;
		var name = "";
		for(var i=1; i<=ArrayLen(tzarr);i++){
			element = ListToArray(tzarr[i],':',true);
			switch(element[1]){
				case "BEGIN":
					name=LCase(element[2]);
					inside = true;
					tz[name] = {};
					continue;
					break;
				case "END":
					inside = false;
					continue;
					break;
				default:
					if(Len(name) GT 0) tz[name][LCase(element[1])] = element[2];
					else  tz[LCase(element[1])] = element[2];
					break;
			}
		}		
		timezones['#tz.tzid#'] = tz;
		var matches = REFind(TZ_OFFSET, tz.standard.tzoffsetto,1,true);
		if (matches.pos[1] GT 0) {
			timezones['#tz.tzid#']["tz_offset"] = (Mid(tz.standard.tzoffsetto,matches.pos[2],matches.len[2]) == '-' ? -1 : +1) *
				(Mid(tz.standard.tzoffsetto,matches.pos[3],matches.len[3]) * 60 + Mid(tz.standard.tzoffsetto,matches.pos[4],matches.len[4]));
		} 
		
		
	}
}
</cfscript>