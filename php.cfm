<cfscript>
    
/** http://www.php.net//manual/en/function.empty.php */
private function empty(value) {
	return isNull(value) 
		|| (isBoolean(value) && !value)
		|| (isSimpleValue(value) && (len(value) == 0 || value == 0))
		|| (isArray(value) && arrayIsEmpty(value));
}	
	
/** 
 * http://www.php.net//manual/en/function.preg-replace-callback.php
 *
 * @pattern 	The pattern to search for. It can be either a string or an array with strings
 * @callback	A callback that will be called and passed an array of matched elements in the subject string. The callback should return the replacement string
 * @subject		The string or an array with strings to search and replace
 * @limit		The maximum possible replacements for each pattern in each subject string. Defaults to -1 (no limit)
 * @count		If specified, this variable will be filled with the number of replacements done
 */
function preg_replace_callback(required pattern, required function callback, required subject, numeric limit = -1)  {
	
	if (isArray(subject)) {
		return arrayMap(subject, function() {
			return preg_replace_callback(subject=s, argumentCollection=arguments);
		});
	}
	
    var regex = createObject("java", "java.util.regex.Pattern").compile(javaCast("string", pattern));
    var matcher = regex.matcher(javaCast("string", subject));
    var buffer = createObject("java", "java.lang.StringBuffer").init();
	var count = 0;
	 
	while (matcher.find() && count < limit) {
        var matches = [];
        
        for (var i = 0 ; i <= matcher.groupCount() ; i++) {
        	arrayAppend(matches, matcher.group(javaCast("int", i)));
        }
        
		var replacement = callback(matches);
		
		if (isNull(replacement))
			replacement = "";
			
		matcher.appendReplacement(buffer, matcher.quoteReplacement(javacast("string", replacement)));
		++count;
	}
	matcher.appendTail(buffer);
 
	return count ? buffer.toString() : subject;
}


array function getimagesize(file_path){
	var image = imageRead(file_path);
	return [imageGetWidth(image), imageGetHeight(image)];
}

</cfscript>