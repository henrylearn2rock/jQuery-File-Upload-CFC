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
