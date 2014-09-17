<cfscript>
/** http://www.php.net//manual/en/function.empty.php */
private function empty(value) {
	return isNull(value)
		|| (isBoolean(value) && !value)
		|| (isSimpleValue(value) && (len(value) == 0 || value == 0))
		|| (isArray(value) && arrayIsEmpty(value));
}
</cfscript>