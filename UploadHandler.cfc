component {
  if (
       (server.coldfusion.productName eq 'ColdFusion'  && ListFirst(server.coldfusion.productVersion) < 11 ) ||
       (server.coldfusion.productName eq 'Lucee'  && ListFirst(server.coldfusion.productVersion) < 10 ) ||
       (server.coldfusion.productName eq 'Railo'  && ListFirst(server.coldfusion.productVersion) < 10 )
     ) {
    include "_cf_header.cfm";
    include "_arrayMap.cfm";
  }

  include "_fileUploadAll.cfm";      // CF10 bugfix

  if (server.coldfusion.productName neq 'Railo' && server.coldfusion.productName neq 'Lucee' ) {
    include "_empty.cfm";
  }
  include "_preg_replace_callback.cfm";
  include "_getImageSize.cfm";

  options = {};

    error_messages = {
        1 = 'The uploaded file exceeds the upload_max_filesize directive in php.ini',
        2 = 'The uploaded file exceeds the MAX_FILE_SIZE directive that was specified in the HTML form',
        3 = 'The uploaded file was only partially uploaded',
        4 = 'No file was uploaded',
        6 = 'Missing a temporary folder',
        7 = 'Failed to write file to disk',
        8 = 'A PHP extension stopped the file upload',
        'post_max_size' = 'The uploaded file exceeds the post_max_size directive in php.ini',
        'max_file_size' = 'File is too big',
        'min_file_size' = 'File is too small',
        'accept_file_types' = 'Filetype not allowed',
        'max_number_of_files' = 'Maximum number of files exceeded',
        'max_width' = 'Image exceeds maximum width',
        'min_width' = 'Image requires a minimum width',
        'max_height' = 'Image exceeds maximum height',
        'min_height' = 'Image requires a minimum height',
        'abort' = 'File upload aborted',
        'image_resize' = 'Failed to resize image'
    };

    image_objects = {};

    function init(options, processRequest=false, error_messages) {
        variables.options = {
            'script_url' = get_full_url() & '/',
            'upload_dir' = expandPath('/fm/files/'),
            'upload_url' = get_full_url() & '/files/',
            'user_dirs' = false,
            'mkdir_mode' = 0755,
            'param_name' = 'files',
            // Set the following option to 'POST', if your server does not support
            // DELETE requests. This is a parameter sent to the client:
            'delete_type' = 'DELETE',
            'access_control_allow_origin' = '*',
            'access_control_allow_credentials' = false,
            'access_control_allow_methods' = [
                'OPTIONS',
                'HEAD',
                'GET',
                'POST',
                'PUT',
                'PATCH',
                'DELETE'
            ],
            'access_control_allow_headers' = [
                'Content-Type',
                'Content-Range',
                'Content-Disposition'
            ],
            // Enable to provide file downloads via GET requests to the PHP script:
            //     1. Set to 1 to download files via readfile method through PHP
            //     2. Set to 2 to send a X-Sendfile header for lighttpd/Apache
            //     3. Set to 3 to send a X-Accel-Redirect header for nginx
            // If set to 2 or 3, adjust the upload_url option to the base path of
            // the redirect parameter, e.g. '/files/'.
            'download_via_cf' = false,
            // Read files in chunks to avoid memory limits when download_via_cf
            // is enabled, set to 0 to disable chunked reading of files:
            'readfile_chunk_size' = 10 * 1024 * 1024, // 10 MiB
            // Defines which files can be displayed inline when downloaded:
            'inline_file_types' = '\.(gif|jpe?g|png)',
            // Defines which files (based on their names) are accepted for upload:
            'accept_file_types' = '.+',
            'max_file_size' = 20 * 1024 * 1024,  // 20mb
            'min_file_size' = 1,
            // The maximum number of files for the upload directory:
            'max_number_of_files' = "",
            // Defines which files are handled as image files:
            'image_file_types' = '/\.(gif|jpe?g|png)/i',
            // Image resolution restrictions:
            'max_width' = javacast("null", ""),
            'max_height' = javacast("null", ""),
            'min_width' = 1,
            'min_height' = 1,
            // Set the following option to false to enable resumable uploads:
            'discard_aborted_uploads' = true,
            // Set to 0 to use the cfimage to scale and orient images,
            // set to 2 to use the ImageMagick convert binary directly:
            'image_library' = 0,
            // Uncomment the following to define an array of resource limits
            // for imagick:
            /*
            'imagick_resource_limits' = [
                imagick::RESOURCETYPE_MAP = 32,
                imagick::RESOURCETYPE_MEMORY = 32
            ],
            */
            // Command or path for to the ImageMagick convert binary:
            'convert_bin' = 'convert',
            // Uncomment the following to add parameters in front of each
            // ImageMagick convert call (the limit constraints seem only
            // to have an effect if put in front):
            /*
            'convert_params' = '-limit memory 32MiB -limit map 32MiB',
            */
            // Command or path for to the ImageMagick identify binary:
            'identify_bin' = 'identify',
            'image_versions' = {
                // The empty image version key defines options for the original image:
                '' = {
                    // Automatically rotate images based on EXIF meta data:
                    'auto_orient' = true
                },
                // Uncomment the following to create medium sized images:
                /*
                'medium' = {
                    'max_width' = 800,
                    'max_height' = 600
                },
                */
                'thumbnail' = {
                    // Uncomment the following to use a defined directory for the thumbnails
                    // instead of a subdirectory based on the version identifier.
                    // Make sure that this directory doesn't allow execution of files if you
                    // don't pose any restrictions on the type of uploaded files, e.g. by
                    // copying the .htaccess file from the files directory for Apache:
                    //'upload_dir' = getDirectoryFromPath(get_server_var('SCRIPT_FILENAME')).'/thumb/',
                    //'upload_url' = get_full_url().'/thumb/',
                    // Uncomment the following to force the max
                    // dimensions and e.g. create square thumbnails:
                    //'crop' = true,
                    'max_width' = 80,
                    'max_height' = 80
                }
            }
        };
        if (isDefined("arguments.options")) {
          structAppend(variables.options, options);
        }
        if (isDefined("arguments.error_messages")) {
          structAppend(variables.error_messages, error_messages);
        }
    if (processRequest){
          this.processRequest();
    }
    return this;
    }

    function processRequest() {
        switch (get_server_var('REQUEST_METHOD')) {
            case 'OPTIONS':
            case 'HEAD':
                head();
                break;
            case 'GET':
                get();
                break;
            case 'PATCH':
            case 'PUT':
            case 'POST':
                post();
                break;
            case 'DELETE':
                delete();
                break;
            default:
                getpagecontext().getresponse().setStatus(405, 'Method Not Allowed');
        }
    }

    private function get_full_url() {
        var https = !empty(CGI['HTTPS']) && compare(CGI['HTTPS'], 'on') == 0;
        return
            (https ? 'https://' : 'http://') &
            (!empty(CGI['REMOTE_USER']) ? CGI['REMOTE_USER'] & '@' : '') &
            (!isNull(CGI['HTTP_HOST']) ? CGI['HTTP_HOST'] : (CGI['SERVER_NAME'] &
            (https && CGI['SERVER_PORT'] == 443 ||
            CGI['SERVER_PORT'] == 80 ? '' : ':' & CGI['SERVER_PORT']))) &
            GetDirectoryFromPath(CGI['SCRIPT_NAME']);
    }

    private function get_user_id() {
        return session.cfid;
    }

    private function get_user_path() {
        if (structKeyExists(options, 'user_dirs') && options['user_dirs']) {
            return get_user_id() & '/';
        }
        return '';
    }

    private function get_upload_path(file_name="", version="") {
        if (empty(version)) {
            var version_path = '';
        } else {
            var version_dir = isDefined("variables.options.image_versions.#version#.upload_dir") ?
              options['image_versions'][version]['upload_dir'] : "";
            if (len(version_dir)) {
                return version_dir & get_user_path() & file_name;
            }
            var version_path = version & '/';
        }
        return options['upload_dir'] & get_user_path()
             & version_path & file_name;
    }

    private function get_query_separator(urlString) {
        return find('?', urlString) == 0 ? '?' : '&';
    }

    private function get_download_url(file_name, version="", direct = false) {
        if (!direct && options['download_via_cf']) {
            var url = options['script_url']
                 & get_query_separator(options['script_url'])
                 & get_singular_param_name()
                 & '=' & urlEncodedFormat(file_name);
            if (len(version)) {
                url &= '&version=' & urlEncodedFormat(version);
            }
            return url & '&download=1';
        }
        if (empty(version)) {
            var version_path = '';
        } else {
            var version_url = isDefined("options.image_versions.#version#.upload_url") ?
              options['image_versions'][version]['upload_url'] : "";
            if (len(version_url)) {
                return version_url & get_user_path() & urlEncodedFormat(file_name);
            }
            var version_path = urlEncodedFormat(version) & '/';
        }
        return options['upload_url'] & get_user_path()
             & version_path & urlEncodedFormat(file_name);
    }

    private function set_additional_file_properties(file) {
        file['deleteUrl'] = options['script_url']
             & get_query_separator(options['script_url'])
             & get_singular_param_name()
             & '=' & urlEncodedFormat(file.name);
        file['deleteType'] = options['delete_type'];
        if (file.deleteType != 'DELETE') {
            file['deleteUrl'] &= '&_method=DELETE';
        }
        if (options['access_control_allow_credentials']) {
            file['deleteWithCredentials'] = true;
        }
    }

    // Fix for overflowing signed 32 bit integers in PHP, not needed for CF
    //private function fix_integer_overflow(size) {
    //    return size;
    //}

    private function get_file_size(file_path) {
        return getFileInfo(file_path).size;
    }

    private function is_valid_file_object(file_name) {
        file_path = get_upload_path(file_name);
        if (fileExists(file_path) && left(file_name, 1) != '.') {
            return true;
        }
        return false;
    }

    private function get_file_object(file_name) {
        if (is_valid_file_object(file_name)) {
            var file = {};
            file['name'] = file_name;
            file['size'] = get_file_size(
                get_upload_path(file_name)
            );
            file['url'] = get_download_url(file.name);
            structEach(options['image_versions'], function(version, options) {
                if (!empty(version)) {
                    if (fileExists(get_upload_path(file_name, version))) {
                        file[version & 'Url'] = get_download_url(
                            file.name,
                            version
                        );
                    }
                }
            });
            set_additional_file_properties(file);
            return file;
        }
        return;
    }

  private function get_file_objects(iterationMethod=get_file_object) {
    var uploadDir = get_upload_path();
    if (!directoryExists(uploadDir)) {
      return [];
    }
    return arrayFilter(
      arrayMap(directoryList(uploadDir, false, "name"), iterationMethod),
      function(el) {
        return !isNull(el);
      }
    );
  }

    private function count_file_objects() {
        return arrayLen(get_file_objects('is_valid_file_object'));
    }

    private function get_error_message(error) {
        return structKeyExists(error_messages, error) ? error_messages[error] : error;
    }


    private function validate(uploaded_file, file, error, index) {
        if (len(error)) {
            file['error'] = get_error_message(error);
            return false;
        }
        content_length = val(
            get_server_var('CONTENT_LENGTH')
        );

        if (!reFindNoCase(options['accept_file_types'], file.name)) {
            file['error'] = get_error_message('accept_file_types');
            return false;
        }
        if (len(uploaded_file) && fileExists(uploaded_file)) {
            file_size = get_file_size(uploaded_file);
        } else {
            file_size = content_length;
        }
        if (options['max_file_size'] && (
                file_size > options['max_file_size'] ||
                file.size > options['max_file_size'])
            ) {
            file['error'] = get_error_message('max_file_size');
            return false;
        }
        if (options['min_file_size'] &&
            file_size < options['min_file_size']) {
            file['error'] = get_error_message('min_file_size');
            return false;
        }
        if (isNumeric(options['max_number_of_files']) &&
                (count_file_objects() >= options['max_number_of_files']) &&
                // Ignore additional chunks of existing files:
                !fileExists(get_upload_path(file.name))) {
            file['error'] = get_error_message('max_number_of_files');
            return false;
        }
        max_width = isDefined('variables.options.max_width') ? options['max_width'] : "";
        max_height = isDefined('variables.options.max_height') ? options['max_height'] : "";
        min_width = isDefined('variables.options.min_width') ? options['min_width'] : "";
        min_height = isDefined('variables.options.min_height') ? options['min_height'] : "";

        var img_width = "";
        var img_height = "";

        if ( (len(max_width) || len(max_height) || len(min_width) || len(min_height)) &&
            reFindNoCase(options['image_file_types'] ,file.name) ) {
             var size = get_image_size(uploaded_file);
             img_width = size[1];
             img_height = size[2];
        }
        if (!isNull(local.img_width) && !empty(local.img_width)) {
            if (len(max_width) && img_width > max_width) {
                file['error'] = get_error_message('max_width');
                return false;
            }
            if (len(max_height) && img_height > max_height) {
                file['error'] = get_error_message('max_height');
                return false;
            }
            if (len(min_width) && img_width < min_width) {
                file['error'] = get_error_message('min_width');
                return false;
            }
            if (len(min_height) && img_height < min_height) {
                file['error'] = get_error_message('min_height');
                return false;
            }
        }
        return true;
    }

    private function upcount_name_callback(matches) {
    var index = arrayIsDefined(matches, 2) ? val(matches[2]) + 1 : 1;
    var ext = arrayIsDefined(matches, 3) ? matches[3] : '';
    return ' (' & index & ')' & ext;
    }

  private function upcount_name(name) {
    return preg_replace_callback(
      '(?:(?: \(([\d]+)\))?(\.[^.]+))?$',
      upcount_name_callback,
      name,
      1
    );
  }

    private function get_unique_filename(file_path, name, size, type, error,
            index, content_range) {
        while(directoryExists(get_upload_path(name))) {
            name = upcount_name(name);
        }
        // Keep an existing filename if this is part of a chunked upload:
        var uploaded_bytes = val(isArray(content_range) ? content_range[2] : "") ;
        while (fileExists(get_upload_path(name))) {
            if (uploaded_bytes == get_file_size(
                    get_upload_path(name))) {
                break;
            }
            name = upcount_name(name);
        }
        return name;
    }

    private function trim_file_name(file_path, name, size, type, error,
            index, content_range) {
        // Remove path information and dots around the filename, to prevent uploading
        // into different directories or replacing hidden system files.
        // Also remove control characters and spaces (\x00..\x20) around the filename:
        name = rereplace(getFileFromPath(name), "[\x00-\x1F]", '', 'all');
        // Use a timestamp for empty filenames:
        if (!len(name)) {
            name = getTickCount();
        }

        extensions=[];
        switch(fileGetMimeType(file_path)){
            case "image/jpeg":
                extensions = ['jpg', 'jpeg'];
                break;
            case "image/png":
                extensions = ['png'];
                break;
            case "image/gif":
                extensions = ['gif'];
                break;
        }
        // Adjust incorrect image file extensions:
        if (!empty(extensions)) {
            parts = listToArray(name, '.');
            extIndex = arrayLen(parts);
            ext = lcase( arrayIsDefined(parts, extIndex) ? parts[extIndex] : "" );
            if (!arrayContains(extensions, ext)) {
                parts[extIndex] = extensions[1];
                name = arrayToList(parts,'.');
            }
        }
        return name;
    }

    private function get_file_name(file_path, name, size, type, error,
            index, content_range) {
        return get_unique_filename(
            file_path,
            trim_file_name(file_path, name, size, type, error,
                index, content_range),
            size,
            type,
            error,
            index,
            content_range
        );
    }

    private function handle_form_data(file, index) {
        // Handle form data, e.g. FORM['description'][index]
    }

    private function get_scaled_image_file_paths(file_name, version) {
        file_path = get_upload_path(file_name);
        if (!empty(version)) {
            version_dir = get_upload_path(version=version);
            if (!directoryExists(version_dir)) {
			    try {
	                directoryCreate(version_dir);
			    } catch (exception e) {
			    }
            }
            new_file_path = version_dir & '/' & file_name;
        } else {
            new_file_path = file_path;
        }
        return [file_path, new_file_path];
    }

    private function cfimage_get_image_object(file_path, func, no_cache = false) {
        if (!structKeyExists(image_objects, file_path) || no_cache) {
            cfimage_destroy_image_object(file_path);
            image_objects[file_path] = imageRead(file_path);
        }
        return image_objects[file_path];
    }


    private function cfimage_set_image_object(file_path, image) {
        cfimage_destroy_image_object(file_path);
        image_objects[file_path] = image;
    }

    private function cfimage_destroy_image_object(file_path) {
        return structDelete(image_objects, file_path, true);
    }


  private function cfimage_imageFlip(image, mode) {
    switch(mode) {
      case 1:
        imageFlip(image, "horizontal");
        return image;
        break;
      case 2:
        imageFlip(image, "vertical");
        return image;
        break;
      case 3:
        imageFlip(image, "diagonal");
        return image;
        break;
      default:
        return image;
    }
  }

  private function cfimage_orient_image(file_path, src_img) {
        var image = imageRead(file_path);
    var orientation = ImageGetEXIFTag(image, 'orientation');

    if (!isNull(orientation) && findNoCase('rotate', orientation)) {
      var rotateValue = reReplace(orientation,'[^0-9]','','all');

      // copy the image to remove the exif data
      var theImage = imageCopy(src_img,0,0,src_img.width,src_img.height);

        imageRotate(theImage,rotateValue);
      imageWrite(theImage, file_path, 1, true);
	    cfimage_set_image_object(file_path, theImage);
    }

    return true;
    }

  private function cfimage_create_scaled_image(fileName, version, options) {
    var paths = get_scaled_image_file_paths(fileName, version);
    var file_path = paths[1];
    var new_file_path = paths[2];

    var type = listLast(fileName, '.');

    var src_img = cfimage_get_image_object(
      file_path,
      "",
      structKeyExists(options,'no_cache') && !empty(options['no_cache'])
    );
    var image_oriented = false;
    if (structKeyExists(options,'auto_orient') && !empty(options['auto_orient']) && cfimage_orient_Image(
      file_path,
      src_img
    )) {
      image_oriented = true;
      src_img = cfimage_get_image_object(
        file_path,
        ""
      );
    }
    var max_width = img_width = ImageGetWidth(src_img);
    var new_height = img_height = ImageGetHeight(src_img);
    if (structKeyExists(options,'max_width') && !empty(options['max_width'])) {
      max_width = options['max_width'];
    }
    if (structKeyExists(options,'max_height') && !empty(options['max_height'])) {
      max_height = options['max_height'];
    }
    var scale = min(
      max_width / img_width,
      new_height / img_height
    );
    if (scale >= 1) {
      if (image_oriented) {
        imageWrite(src_img, new_file_path);
        return true;
      }
      if (file_path != new_file_path) {
        filecopy(file_path, new_file_path);
        return true;
      }
      return true;
    }
    var new_img = duplicate(src_img);
    if (structKeyExists(options,'crop') && empty(options['crop'])) {
      var new_width = img_width * scale;
      var new_height = img_height * scale;
      var dst_x = 0;
      var dst_y = 0;
      imageScaleToFit(new_img, new_width, new_height);
    } else {
      if ((img_width / img_height) >= (max_width / max_height)) {
        new_width = img_width / (img_height / max_height);
        new_height = max_height;
      } else {
        new_width = max_width;
        new_height = img_height / (img_width / max_width);
      }
      var dst_x = 0 - (new_width - max_width) / 2;
      var dst_y = 0 - (new_height - max_height) / 2;
          imageScaleToFit(new_img, new_width, new_height);
    }

        var success = true;

    try {
      imageWrite(new_img, new_file_path);
    } catch (exception e) {
      success = false;
    }
    cfimage_set_image_object(file_path, new_img);
    return success;
  }


    private function imagemagick_create_scaled_image(file_name, version, options) {
        paths = get_scaled_image_file_paths(file_name, version);
        file_path = paths[1];
        new_file_path = paths[2];

        resize = (structKeyExists(options, 'max_width') ? options['max_width'] : "")
             & (empty(options['max_height']) ? '' : 'X' & options['max_height']);
        if (!resize && empty(options['auto_orient'])) {
            if (file_path != new_file_path) {
                filecopy(file_path, new_file_path);
                return true;
            }
            return true;
        }
        cmd = options['convert_bin'];
        if (!empty(options['convert_params'])) {
            cmd &= ' ' & options['convert_params'];
        }
        cmd &= ' ' & escapeshellarg(file_path);
        if (!empty(options['auto_orient'])) {
            cmd &= ' -auto-orient';
        }
        if (resize) {
            // Handle animated GIFs:
            cmd &= ' -coalesce';
            if (empty(options['crop'])) {
                cmd &= ' -resize ' & escapeshellarg(resize & '>');
            } else {
                cmd &= ' -resize ' & escapeshellarg(resize & '^');
                cmd &= ' -gravity center';
                cmd &= ' -crop ' & escapeshellarg(resize & '+0+0');
            }
            // Make sure the page dimensions are correct (fixes offsets of animated GIFs):
            cmd &= ' +repage';
        }
        if (!empty(options['convert_params'])) {
            cmd &= ' ' & options['convert_params'];
        }
        cmd &= ' ' & escapeshellarg(new_file_path);
        exec(cmd, output, error);
        if (error) {
            error_log(arrayToList(output, '\n'));
            return false;
        }
        return true;
    }

    private function get_image_size(file_path) {
        if (structKeyExists(options, 'image_library') && options['image_library'] == 2) {
            cmd = ' -ping ' & file_path;
            cf_execute(name=options['identify_bin'], arguments=cmd, variable=output, errorVariable=error);
            if (!len(error) && !empty(output)) {
                // image.jpg JPEG 1920x1080 1920x1080+0+0 8-bit sRGB 465KB 0.000u 0:00.000
                infos = preg_split('/\s+/', output[0]);
                dimensions = preg_split('/x/', infos[2]);
                return dimensions;
            }
            return false;
        }
        return getimagesize(file_path);
    }


    private function create_scaled_image(file_name, version, options) {
        if (structKeyExists(options, 'image_library') && options['image_library'] == 2) {
            return imagemagick_create_scaled_image(file_name, version, options);
        }
        return cfimage_create_scaled_image(file_name, version, options);
    }

    private function destroy_image_object(file_path) {
    // TODO: do nothing?
    }


    private function is_valid_image_file(file_path) {
        return isImageFile(file_path);
    }

    private function handle_image_file(file_path, file) {
        var failed_versions = [];
        structEach(options['image_versions'], function(version, options) {
            if (create_scaled_image(file.name, version, options)) {
                if (!empty(version)) {
                    file[version & 'Url'] = get_download_url(
                        file.name,
                        version
                    );
                } else {
                    file['size'] = get_file_size(file_path, true);
                }
            } else {
              arrayAppend(failed_versions, version ? version : 'original');
            }
        });
        if (arrayLen(failed_versions)) {
            file['error'] = get_error_message('image_resize')
                     & ' (' & arrayToList(failed_versions,', ') & ')';
        }
        // Free memory:
        destroy_image_object(file_path);
    }

    private function handle_file_upload(uploaded_file, name, size, type, error,
            index, content_range) {
        var file = {};
        file['name'] = get_file_name(uploaded_file, name, size, type, error,
            index, content_range);
        file['size'] = val(size);
        file['type'] = type;
        if (validate(uploaded_file, file, error, index)) {
            handle_form_data(file, index);
            upload_dir = get_upload_path();
            if (!directoryExists(upload_dir)) {
			    try {
			       directoryCreate(upload_dir);
			    } catch (exception e) {
			    }

            }
            file_path = get_upload_path(file.name);
            append_file = isArray(content_range) && arrayLen(content_range) && fileExists(file_path) &&
                file.size > get_file_size(file_path);
            if (len(uploaded_file) && fileExists(uploaded_file)) {
                // multipart/formdata uploads (POST method uploads)
                if (append_file) {
                    var fileObj = fileOpen(file_path, "append");
                    fileWrite(fileObj, fileReadBinary(uploaded_file));
                } else {
                    fileMove(uploaded_file, file_path);
                }
            } else {
                // Non-multipart uploads (PUT method support)
                var fileObj = fileOpen(file_path, append_file ? "append" : "write");
                fileWrite(fileObj, getHttpRequestData().content);
            }
            var file_size = get_file_size(file_path, append_file);
            if (file_size == file.size) {
                file['url'] = get_download_url(file.name);
                if (is_valid_image_file(file_path)) {
                    handle_image_file(file_path, file);
                }
            } else {
                file['size'] = file_size;
                if (isArray(content_range) && !arrayLen(content_range) && options['discard_aborted_uploads']) {
                    fileDelete(file_path);
                    file['error'] = get_error_message('abort');
                }
            }
            set_additional_file_properties(file);
        }
        return file;
    }

  //if doesn't work, use cfcontent
    private function readfile(file_path) {
        var file_size = get_file_size(file_path);
        var chunk_size = options['readfile_chunk_size'];
        if (len(chunk_size) && file_size > chunk_size) {
            handle = fileOpen(file_path, 'readBinary');
            var response = getPageContext().getFusionContext().getResponse();
            while (!fileIsEOF(handle)) {
        // replace the output stream contents with the binary
        response.getOutputStream().writeThrough( fileRead(handle, chunk_size) );

                getPageContext().getOut().flush();
        // leave immediately to ensure now whitespace is added
            }
            fileClose(handle);
            return file_size;
        }
        return readfile(file_path);
    }

    private function body(str) {
        writeOutput(str);
    }

    private function header(str) {
        var name = listFirst(str, ':');
        var value = trim(listRest(str, ':'));

        if (name == "location") {
          location(value);
         } else {
          //cf_header(name=name, value=value);
          getpagecontext().getresponse().setHeader(name,value);
      }
    }

    private function get_server_var(id) {
        return !isNull(CGI[id]) ? CGI[id] : '';
    }

    private function generate_response(content, print_response = true) {
        if (print_response) {
            json = serializeJson(content);
            redirect = !isNull(URL.redirect) ?
                URL['redirect'] : "";
            if (len(redirect)) {
                header('Location: ' & sprintf(redirect, urlEncodedFormat(json)));  //TODO: replace sprintf
                return;
            }
            head();
            if (len(get_server_var('HTTP_CONTENT_RANGE'))) {
                var files = !isNull(content[options['param_name']]) ?
                    content[options['param_name']] : "";
                if (isArray(files) && arrayIsDefined(files, 1) && files[1].size) {
                    header('Range: 0-' & (
                        precisionEvaluate(val(files[1].size) - 1)
                    ));
                }
            }
            body(json);
        }
        return content;
    }

    private function get_version_param() {
        return !isNull(URL['version']) ? getFileFromPath(URL['version']) : "";
    }

    private function get_singular_param_name() {
        return left(options['param_name'], len(options['param_name']) - 1);
    }

    private function get_file_name_param() {
        var name = get_singular_param_name();
        return structKeyExists(URL, name) ? getFileFromPath(URL[name]) : "";
    }

    private function get_file_names_params() {
        if(!structKeyExists(URL,options['param_name'])){
            return false;
        }
        var params = !isNull(URL[options['param_name']]) ?
          URL[options['param_name']] : {};
        structEach(params, function(key, value) {
            params[key] = getFileFromPath(value);
        });
        return params;
    }

    private function get_file_type(file_path) {
        switch (listLast(filePath, '.')) {
            case 'jpeg':
            case 'jpg':
                return 'image/jpeg';
            case 'png':
                return 'image/png';
            case 'gif':
                return 'image/gif';
            default:
                return '';
        }
    }

    private function download() {
        switch (options['download_via_cf']) {
            case 1:
                redirect_header = '';
                break;
            case 2:
                redirect_header = 'X-Sendfile';
                break;
            case 3:
                redirect_header = 'X-Accel-Redirect';
                break;
            default:
                return getpagecontext().getresponse().setStatus(403, 'Forbidden');
        }
        file_name = get_file_name_param();
        if (!is_valid_file_object(file_name)) {
            return getpagecontext().getresponse().setStatus(404, 'Not Found');
        }
        if (len(redirect_header)) {
            return header(
                redirect_header & ': ' & get_download_url(
                    file_name,
                    get_version_param(),
                    true
                )
            );
        }
        file_path = get_upload_path(file_name, get_version_param());
        // Prevent browsers from MIME-sniffing the content-type:
        header('X-Content-Type-Options: nosniff');
        if (!reFindNoCase(options['inline_file_types'], file_name)) {
            header('Content-Type: application/octet-stream');
            header('Content-Disposition: attachment; filename="' & file_name & '"');
        } else {
            header('Content-Type: ' & get_file_type(file_path));
            header('Content-Disposition: inline; filename="' & file_name & '"');
        }
        header('Content-Length: ' & get_file_size(file_path));
        header('Last-Modified: ' & gmdate('D, d M Y H:i:s T', filemtime(file_path)));
        readfile(file_path);
    }

    private function send_content_type_header() {
        header('Vary: Accept');
        if (findNoCase('application/json', get_server_var('HTTP_ACCEPT'))) {
            header('Content-type: application/json');
        } else {
            header('Content-type: text/plain');
        }
    }

    private function send_access_control_headers() {
        header('Access-Control-Allow-Origin: ' & options['access_control_allow_origin']);
        header('Access-Control-Allow-Credentials: '
             & (options['access_control_allow_credentials'] ? 'true' : 'false'));
        header('Access-Control-Allow-Methods: '
             & arrayToList(options['access_control_allow_methods'], ', '));
        header('Access-Control-Allow-Headers: '
             & arrayToList(options['access_control_allow_headers'], ', '));
    }

    public function head() {
        header('Pragma: no-cache');
        header('Cache-Control: no-store, no-cache, must-revalidate');
        header('Content-Disposition: inline; filename="files.json"');
        // Prevent Internet Explorer from MIME-sniffing the content-type:
        header('X-Content-Type-Options: nosniff');
        if (!isNull(options.access_control_allow_origin)) {
            send_access_control_headers();
        }
        send_content_type_header();
    }

    public function get(print_response = true) {
        if (print_response && !isNull(URL.download)) {
            return download();
        }
        var file_name = get_file_name_param();
        if (len(file_name)) {
            response[get_singular_param_name()] = get_file_object(file_name);
        } else {
            response[options['param_name']] = get_file_objects();
        }
        return generate_response(response, print_response);
    }


    public function post(print_response = true) {
        if (!isNull(URL._method) && URL['_method'] == 'DELETE') {
            return delete(print_response);
        }

        // TODO: factor out tmp folder
        var upload = _fileUploadAll( getTempDirectory() ,"","makeUnique");

        // Parse the Content-Range header, which has the following form:
        // Content-Range: bytes 0-524287/2000000
         var content_range = len(get_server_var('HTTP_CONTENT_RANGE')) ?
           reMatch('[0-9]+', get_server_var('HTTP_CONTENT_RANGE')) : "";

        var size = isArray(content_range) ? content_range[3] : "";
        var files = [];

        for (var index=1; index <= arrayLen(upload); index++) {
          var curUpload = upload[index];
            arrayAppend(files,
              handle_file_upload(
                curUpload.serverDirectory & '/' & curUpload.serverFile,
                curUpload.attemptedserverFile,
                len(size) ? size : curUpload.fileSize,
                curUpload.contentType & '/' & curUpload.contentSubType,
                "",
                index,
                content_range
                ));
        }

        return generate_response(
            {"#options.param_name#" = files},
            print_response
        );
    }

    public function delete(print_response = true) {
        var file_names = get_file_names_params();
        if (empty(file_names)) {
            file_names = [get_file_name_param()];
        }
        response = {};
        for(var file_name in file_names) {
            var file_path = get_upload_path(file_name);
            var success = fileExists(file_path) && left(file_name,1) != '.';
            if (success) {
              fileDelete(file_path);
                structEach(options['image_versions'], function(version, options) {
                    if (!empty(version)) {
                        var file = get_upload_path(file_name, version);
                        if (fileExists(file)) {
                            fileDelete(file);
                        }
                    }
                });
            }
            response[file_name] = success;
        }
        return generate_response(response, print_response);
    }
}
