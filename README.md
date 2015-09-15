jQuery-File-Upload-CFC
======================

Version 0.9 beta

Port of blueimp/jQuery-File-Upload into CFScript (CF10)

https://github.com/blueimp/jQuery-File-Upload

Setup
-----

1. in onApplicationStart(): `Application.uploadHandler = new UploadHandler()` 
2. use a cfm to invoke `Application.uploadHandler.processRequest()` as plugin's endpoint
