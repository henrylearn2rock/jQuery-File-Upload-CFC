<cfscript>
array function getImageSize(file_path){
	var image = imageRead(file_path);
	return [imageGetWidth(image), imageGetHeight(image)];
}
</cfscript>