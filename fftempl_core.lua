--FFTEMPL
--fuka@fuxoft.cz

_G.FFTEMPL.version.core = string.match([[*<= Version '2.1.9+D20210402T174600' =>*]], "'.+'")

--[[
Available hooks (called in this order):
	FFTEMPL.hooks.sections - HTM sections are loaded in FFTEMPL.sections
	FFTEMPL.hooks.tags - Tags are parsed in FFTEMPL.tags
	FFTEMPL.hooks.html - HTML is done and is stored in FFTEMPL.html (where it can be replaced with something completely different)

variables:
	FFTEMPL.args - Table of parsed GET arguments. Very basic functionality. No fancy parsing / un-escaping is taking place.
	FFTEMPL.custom_dir - The full filesystem path (with ending slash) to the directory (relative to website root) where "default.tag", "default.tmp" and "custom.lua" script files are kept. READONLY - DO NOT MODIFY. Equal to FFTEMPL.document_root .. "/.fftempl/"
	FFTEMPL.document_root - contains the document root, e.g. "/user/ada/www/myweb.com" - WITHOUT the ending forward slash
	FFTEMPL.extra_headers - Contains extra headers (a single string without the trailing \n) e.g. for setting cookies
	FFTEMPL.fftempl_dir - Where fftempl app files reside (absolute path, readonly), ends with "/"
	FFTEMPL.htm_dir - Full path (on disk) to the directory of the currently executing HTM file. Ends with "/"
	FFTEMPL.htm_file - Name of the currently executing HTM file (without directory name)
	FFTEMPL.htm_url - The URL path of the .htm file. Without server name but including the opening forward slash. E.g. "/dir/dir2/file.htm"
	FFTEMPL.htm_text - Contents of HTM file (readonly)
	FFTEMPL.http_status_code - Normally "200"
	FFTEMPL.content_type - Normally "text/html; charset=UTF-8"
	FFTEMPL.parse_args(string) - Can be called to parse POST arguments, e.g. FFTEMPL.parse_args(FFTEMPL.stdin). Very limited functionality!
	FFTEMPL.sections - Table of all HTM sections indexed by their ID
	FFTEMPL.stdin - stdin from server (for POST request parsing)
	FFTEMPL.tags - Table of all replaceable tags indexed by their ID
	FFTEMPL.tags_filename - Full path to file with tags for current page. Default = FFTEMPL.custom_dir.."default.tag"
	FFTEMPL.template_filename - Full path to template file for current page. Default = FFTEMPL.custom_dir.."default.tpl"

API calls:
	FFTEMPL.add_dumb_tag(<tag>, <string or func>)
	FFTEMPL.add_lua_tag(<tag>, <string or func>)
]]

local function main()
	FFTEMPL.parse_args = function(str)
	--Parse the arguments in URL request, e.g. 'foo=hello&bar=69'
	--All values are parsed as strings
	--This is very basic and does not work correctly for non-trivial values!
	local args={}
		local str0 = str:match("^(.-)#") or str
		for key, value in string.gmatch(str0..'&','([_%w]-)=(.-)&') do
			value = value:gsub("%+", " ")
			value = value:gsub("(%%%x%x)", function(str)
				return string.char(tonumber(str:match(".(..)"), 16))
			end)
			args[key] = value
		end
		return args
	end

	local function get_dir(str)
		return str:match("^(.+/)")
	end

	local function readfile(fname)
		local fd = io.open(fname, "r")
		if not fd then
			return false, "File not found"
		end
		local txt = assert(fd:read("*a"))
		assert(fd:close())
		return txt
	end

	local function call_hook(id)
		local fn = FFTEMPL.hooks[id]
		if not fn then
			return false
		end
		assert (type(fn) == "function", "Hook "..id.." is present but isn't a function")
		local result = fn()
		if result ~= nil then
			error("Hook "..id.." shouldn't return any value but returned: "..tostring(result))
		end
		return true
	end

	function FFTEMPL.add_dumb_tag(tag, what)
		assert(type(tag) == "string", "Tag must be string, is "..tostring(tag))
		local typ = type(what)
		assert(typ == "function" or typ == "string", "Tag type is "..typ..", not string or function")
		table.insert(FFTEMPL.tags, {kind = "dumb", orig = tag, repl = what})
	end

	function FFTEMPL.add_lua_tag(tag, what)
		assert(type(tag) == "string", "Tag must be string, is "..tostring(tag))
		local typ = type(what)
		assert(typ == "function" or typ == "string", "Tag type is "..typ..", not string or function")
		table.insert(FFTEMPL.tags, {kind = "lua", orig = tag, repl = what})
	end

	------ HERE WE GO
	FFTEMPL.hooks = {}
	math.randomseed(bit.bxor(tonumber(tostring({}):match("0x(.+)"),16), os.time())) --Thorough PRNG seeding
	
	local query_string=assert(os.getenv('QUERY_STRING'),'Cannot get $QUERY_STRING')
	local droot = assert(os.getenv("DOCUMENT_ROOT"), "Cannot get $DOCUMENT_ROOT")
	FFTEMPL.document_root = droot
	FFTEMPL.custom_dir = FFTEMPL.document_root .. "/.fftempl/"
	
	--execute custom include file, if it exists
	local incname = FFTEMPL.custom_dir.."custom.lua"
	local fd = io.open(incname)
	if fd then
		fd:close()
		dofile(incname)
	end

	local stdin = io.read("*a")
	FFTEMPL.stdin = stdin

	FFTEMPL.http_status_code = "200"
	FFTEMPL.content_type = "text/html; charset=UTF-8"
	
	--[[local fd = io.popen('export')
	local exp = fd:read("*a")
	fd:close()
	FFTEMPL.log("<pre>"..exp.."</pre>")
	]]

	local origURL = os.getenv("REDIRECT_URL")
	FFTEMPL.args = FFTEMPL.parse_args(query_string)
	--error(FFTEMPL.args.fftempl_htm_file)

	--extra parameter in file name?
	--No FFTEMPL.log("htm_filename = "..htm_filename)

	if not origURL then --no REDIRECT_URL, we are running through nginx + FCGI
		origURL = assert(os.getenv("SCRIPT_NAME"), "Cannot get $DOCUMENT_ROOT or $SCRIPT_NAME")
	end
	local fname, param = origURL:match("^(.+)%-%-(.-)%.htm$")
	--FFTEMPL.log("fname = "..tostring(fname))
	--FFTEMPL.log("param = "..tostring(param))
	if fname and param and not param:match("/") then
		origURL = fname .. ".htm"
		FFTEMPL.args._dash_argument = param
	end

	FFTEMPL.htm_url = origURL
	local htm_full_path = droot..origURL
	assert(not htm_full_path:match("%.%."), "Stop doing that")
	FFTEMPL.htm_dir = get_dir(htm_full_path)
	FFTEMPL.htm_file = htm_full_path:match(".+/(.-)$")
	local htm_text = readfile(htm_full_path)

	local file404 = "404error.htm"

	if not htm_text then --Cannot read the HTM file
		--look for 404 file in the current dir
		FFTEMPL.http_status_code = "404"
		htm_text = readfile(FFTEMPL.htm_dir..file404)
		if not htm_text then --Not found in current dir, look for it in root dir
			htm_text = readfile(FFTEMPL.document_root.."/"..file404)
			if not htm_text then
				error("File "..htm_full_path.." not found, "..file404.." file also not found")
			end
		end
	end

	assert(#htm_text > 0, "Empty HTM file")
	htm_text = htm_text:gsub("\r\n", "\n")
	FFTEMPL.htm_text = htm_text
	FFTEMPL.tags = {}

	--FFTEMPL.log(htm_text)

	if htm_text:match("^%-%-LUASCRIPT") then --Embedded script in HTM
		local code, rest = htm_text:match("^(.-\n%-%-/LUASCRIPT.-)(\n.+)$")
		assert (code, "Cannot find --/LUASCRIPT (ending tag)")
		htm_text = rest
		local compiledcode = assert(loadstring(code,htm_filename))
		local result = compiledcode()
		assert(result==nil, "LUASCRIPT should not return any value")
	end

	local sections0 = {}
	htm_text = "\n"..htm_text
	for pos1, sectname, pos2 in htm_text:gmatch("\n()%(%(([%dA-Z_]+)%)%)\n()") do
		--FFTEMPL.log("Found section "..sectname)
		table.insert(sections0, {name=sectname, start=pos2})
		if #sections0 > 1 then
			local prev = sections0[#sections0 - 1]
			assert(not prev.finish)
			prev.finish = pos1 - 2
		end
	end
	assert(#sections0 > 0, "No sections found in HTM file. This is not a fftempl file.")
	sections0[#sections0].finish = #htm_text

	local sections = {}
	for i,sect in ipairs(sections0) do
		sections[sect.name] = htm_text:sub(sect.start, sect.finish)
	end

	FFTEMPL.sections = sections
	call_hook("sections")

	FFTEMPL.template_filename = FFTEMPL.template_filename or (FFTEMPL.custom_dir.."default.tpl")
	local tpl_txt = readfile(FFTEMPL.template_filename) or "<html><title>FFTEMPL</title><body>FFTEMPL is installed and works but your default template is missing (usually in /.fftempl/default.tpl)</body></html>"

	for k, v in pairs(FFTEMPL.sections) do
		local escaped = v:gsub("%%", "%%%%") --Prevent "%1, %2..." expansion
		tpl_txt = tpl_txt:gsub("%(%("..k.."%)%)", escaped)
	end

	--Remove unmatched section markers
	local html = tpl_txt:gsub("%(%([%dA-Z_]+%)%)","")

	FFTEMPL.tags_filename = FFTEMPL.tags_filename or (FFTEMPL.custom_dir .. "default.tag")

	local tag_txt = readfile(FFTEMPL.tags_filename) or ""
	assert(tag_txt, "Cannot read tags file "..FFTEMPL.tags_filename)
	for row in (tag_txt.."\n"):gmatch("(.-)\n") do
		if #row > 3 and (not row:match("^%-%-")) then
			local part1, op, part2 = row:match("^(.-) ?(:=!?) ?(.*)$")
			local tag = {orig = part1, repl = part2}
			if op == ":=" then --dumb
				tag.kind = "dumb"
			else --Lua regex
				assert(op == ":=!")
				tag.kind = "lua"
			end
			table.insert(FFTEMPL.tags,tag)
		end
	end

	call_hook("tags")

	--Tag replacement

	for i, tag in ipairs (FFTEMPL.tags) do
		local kind = tag.kind
		assert(type(tag.orig) == "string")
		assert(tag.repl)

		--FFTEMPL.log(tag.kind.." "..tag.orig.." "..tag.repl.." / ")
		if kind == "lua" then
			--FFTEMPL.log(tag.orig)
			--FFTEMPL.log(tag.repl)
			html = html:gsub(tag.orig, tag.repl)
		else
			assert (kind == "dumb", "Tag must be of kind 'lua' or 'dumb'")
			local orig = tag.orig:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?%]]","%%%1")
			local repl = tag.repl
			if type(repl) ~= "function" then
				repl = tag.repl:gsub("%%", "%%%%")
			end
			html = html:gsub(orig,repl)
		end
	end

	FFTEMPL.html = html
	call_hook("html")

	local result = {html = FFTEMPL.html}
	result.http_status_code = assert(FFTEMPL.http_status_code)
	result.content_type = assert(FFTEMPL.content_type)
	result.extra_headers = FFTEMPL.extra_headers
	return result
end

return main()
