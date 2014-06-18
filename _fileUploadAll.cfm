<cffunction name="_fileUploadAll" output="false"
		hint="CF10 bug 3777301: fileUploadAll() does not work with HTML5 input multiple">
	<cfargument name="destination" required="true">
	<cfargument name="accept" default="">
	<cfargument name="nameConflict" default="">
	
	<cfif NOT len(arguments.accept)>
		<cfset structDelete(arguments, "accept")>
	</cfif>
	<cfif NOT len(arguments.nameConflict)>
		<cfset structDelete(arguments, "nameConflict")>
	</cfif>
	
	<cffile action="uploadall" attributeCollection="#arguments#" result="local.result">
	
	<cfreturn local.result>	
</cffunction>