<cffunction name="QueryGetRow" output="false" returntype="struct"
			hint="https://wikidocs.adobe.com/wiki/display/coldfusionen/QueryGetRow">
	<cfargument name="query" type="query" required="true">
	<cfargument name="row" type="numeric">
	
	<cfif !structKeyExists(arguments, "row")>
		<cfset row = query.currentRow>
	</cfif>
	
	<cfset var struct = {}>

	<cfloop list="#query.columnList#" index="local.col">
		<cfset struct[lcase(col)] = query[col][row]>
	</cfloop>

	<cfreturn struct>
</cffunction>


<cffunction name="cf_header" output="false" returntype="void">
	<cfheader attributecollection="#arguments#">
</cffunction>
	
	
<cffunction name="arrayMap" output="false" returntype="array">
	<cfargument name="arr" type="array" required="true">
	<cfargument name="func" type="function" required="true">
	
	<cfset var results = []>
	
	<cfloop from="1" to="#arrayLen(arr)#" index="local.index">
		<cfset arrayAppend(results, func(arr[index], index, arr))>
	</cfloop>
	
	<cfreturn results> 
</cffunction>

