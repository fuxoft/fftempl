--[[
	This file (whose name "custom.lua" is hardcoded into FFTempl) is executed at the beginning of FFTempl parsing 
	and can be used to change FFTempl behaviour in almost any way.
	Because of the dynamic nature of Lua, all of the following hooks can be
	redefined at runtime. For example you can change what "hookParametersWereParsed()" does based on what is
	passed to "hookGetMissingFile()". You can include and run other files, etc...
	Also note that if you don't want to use any facilities provided
	by "custom.lua" file, you can simply delete the whole file! FFTempl won't mind.
--]]

--[[
	The following two functions are used on my www.fuxoft.cz web (see later in this file).
	They are NOT required for FFTempl itself to function.
--]]

--the following function is referenced in my "default.tag" file and called on every page of my site
function page_url(str)
	return "/"..args.file
end

local function unHTML(str) --make raw text (which may contain '<') suitable for HTML output
	return '<html><body><pre>'..string.gsub(str,'<','&lt;')..'</pre></body></html>'
end

--[[
	If the webserver requests .htm page that does not exist on disk, FFTempl tries this hook
	to get the contents (not name!) of the file. This function receives the desired filename
	(e.g. "/subdir/somefile.htm") and should return a string with the contents of this file.
	This could be used for very complex tricks - e.g. dynamically generating hundreds of different pages
	based just on their filenames, without actually having the relevant .htm files on disk.
	If this function returns nil, the normal FFTempl "file missing" mechanism resumes, 
	i.e. file "404.htm" in document root directory is parsed and displayed if it exists.
--]]
FFTEMPL.hook.get_missing_file = function(filename)
end


--[[
	This hook is called after the whole contents of .htm file was read
	from disk into global "file" variable. You can change it here or do other stuff.
--]]	
FFTEMPL.hook.we_have_the_file = function ()
end

--[[	
	This function is called immediately after the .htm file is parsed and resulting values are inserted
	into "FFTEMPL.params" table. Note that "params" values can be strings or arrays of strings.
--]]
FFTEMPL.hook.parameters_were_parsed = function ()
end

--[[	
	This function is called immediately after the contents of relevant .tag file is read into 'tags' string variable.
--]]
FFTEMPL.hook.tags_loaded = function()
end

--[[
	This hook is called immediately before the resulting parsed file is being fed back to the webserver.
	This is the last chance to replace the contents of 'file' string variable with something else than generated page.
	Here it is used to "view source" of different FFTempl files based on the value of "debug" flag in the URL.
--]]
FFTEMPL.hook.last_chance = function ()
	local dbg = FFTEMPL.args.debug
	if dbg =='source' then
		FFTEMPL.file = unHTML(FFTEMPL.raw_file)
	elseif dbg == 'tags' then
		FFTEMPL.file = unHTML(FFTEMPL.raw_tags)
	elseif dbg == 'template' then
		FFTEMPL.file = unHTML(FFTEMPL.raw_template)
	end
end

--You can add other stuff here, which gets executed immediately when FFTEMPL.main() starts
--For example, you can change FFTEMPL.404 page to point elsewhere...

--[[
The following environment variables are made available to FFTempl by Apache, at least on my installation.

export DOCUMENT_ROOT="/home/fuxoft/work/web/fuxoft.cz"
export GATEWAY_INTERFACE="CGI/1.1"
export HTTP_ACCEPT="text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"
export HTTP_ACCEPT_CHARSET="UTF-8,*"
export HTTP_ACCEPT_ENCODING="gzip,deflate"
export HTTP_ACCEPT_LANGUAGE="en-us,en;q=0.5"
export HTTP_CONNECTION="keep-alive"
export HTTP_HOST="localhost"
export HTTP_KEEP_ALIVE="300"
export HTTP_USER_AGENT="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.4) Gecko/20060608 Ubuntu/dapper-security Firefox/1.5.0.4"
export OLDPWD
export PATH="/bin:/usr/bin:/usr/local/bin"
export PWD="/home/fuxoft/work/web/fuxoft.cz/fftempl"
export QUERY_STRING="file=/ja.htm&debug=yes"
export REDIRECT_QUERY_STRING="file=/ja.htm&debug=yes"
export REDIRECT_STATUS="200"
export REDIRECT_URL="/ja.lhtm"
export REMOTE_ADDR="127.0.0.1"
export REMOTE_PORT="46035"
export REQUEST_METHOD="GET"
export REQUEST_URI="/ja.lhtm?debug=yes"
export SCRIPT_FILENAME="/home/fuxoft/work/web/fuxoft.cz/fftempl/parser.cgi"
export SCRIPT_NAME="/fftempl/parser.cgi"
export SERVER_ADDR="127.0.0.1"
export SERVER_ADMIN="webmaster@localhost"
export SERVER_NAME="localhost"
export SERVER_PORT="80"
export SERVER_PROTOCOL="HTTP/1.1"
export SERVER_SIGNATURE="
Apache/1.3.34 Server at localhost Port 80

"
export SERVER_SOFTWARE="Apache/1.3.34 (Ubuntu) mod_ruby/1.2.5 Ruby/1.8.4(2005-12-24)"
export SHLVL="1"
--]]
