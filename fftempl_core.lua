--FFTEMPL
--fuka@fuxoft.cz

-- [[[[*<= Version '20180302a' =>*]]]]

--[[
Available hooks (called in this order):
	FFTEMPL.hooks.sections - HTM sections are loaded in FFTEMPL.sections
	FFTEMPL.hooks.tags - Tags are parsed in FFTEMPL.tags
	FFTEMPL.hooks.html - HTML is done and is stored in FFTEMPL.html

variables:
	FFTEMPL.fftempl_dir - WHere fftempl files reside (absolute path, readonly)
	FFTEMPL.htm_dir - Directory of the currently executing HTM file (relative to fftempl directory)
	FFTEMPL.htm_text - Contents of HTM file (readonly)
	FFTEMPL.http_status_code - Normally "200"
	FFTEMPL.sections - Table of all HTM sections indexed by their ID
	FFTEMPL.tags - Table of all replaceable tags indexed by their ID
	FFTEMPL.tags_filename - Filename from where to get tags file (default = "default.tag" in fftempl dir)
	FFTEMPL.template_filename - Filename from where to get template (default = "default.tpl" in fftempl dir)

API calls:
	FFTEMPL.add_dumb_tag(<tag>, <string or func>)
	FFTEMPL.add_lua_tag(<tag>, <string or func>)
]]

local function main()

	local function parse_args(str)
	--Parse the arguments in URL request, e.g. 'foo=hello&bar=69'
	--All values are parsed as strings
	local args={}
		local str0 = str:match("^(.-)#") or str
		for key, value in string.gmatch(str0..'&','([_%w]-)=(.-)&') do
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
		assert(type(tag) == "string", "Tag must be string")
		local typ = type(what)
		assert(typ == "function" or typ == "string", "Tag type is "..typ..", not string or function")
		table.insert(FFTEMPL.tags, {kind = "dumb", orig = tag, repl = what})
	end

	function FFTEMPL.add_lua_tag(tag, what)
		assert(type(tag) == "string", "Tag must be string")
		local typ = type(what)
		assert(typ == "function" or typ == "string", "Tag type is "..typ..", not string or function")
		table.insert(FFTEMPL.tags, {kind = "lua", orig = tag, repl = what})
	end

	------ HERE WE GO
	local query_string=assert(os.getenv('QUERY_STRING'),'Unable to get QUERY_STRING from environment')
	FFTEMPL.http_status_code = "200"
	FFTEMPL.content_type = "text/html; charset=UTF-8"
	FFTEMPL.args = parse_args(query_string)
	local htm_filename = assert(FFTEMPL.args.fftempl_htm_file, "No fftempl_htm_file specified")

	assert(not htm_filename:match("%.%."), "Stop doing that")

	--extra parameter in file name?
	--No FFTEMPL.log("htm_filename = "..htm_filename)
	local fname, param = htm_filename:match("^(.-)%-%-(.*)%.htm$")
	--FFTEMPL.log("fname = "..tostring(fname))
	--FFTEMPL.log("param = "..tostring(param))
	if fname and param then
		htm_filename = fname .. ".htm"
		FFTEMPL.args._dash_argument = param
	end

	local htm_full_path = "../"..htm_filename
	FFTEMPL.htm_dir = get_dir(htm_full_path)
	local htm_text = readfile(htm_full_path)

	local file404 = "404error.htm"

	if not htm_text then --Cannot read the HTM file
		--look for 404 fire in the current dir
		FFTEMPL.http_status_code = "404"
		htm_text = readfile(FFTEMPL.htm_dir..file404)
		if not htm_text then --Not found in current dir, look for it in root dir
			htm_text = readfile("../"..file404)
			if not htm_text then
				error("File "..htm.." not found, "..file404.." file also not found")
			end
		end
	end

	assert(#htm_text > 0, "Empty HTM file")
	htm_text = htm_text:gsub("\r\n", "\n")
	FFTEMPL.htm_text = htm_text
	FFTEMPL.tags = {}

	FFTEMPL.hooks = {}

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

	FFTEMPL.template_filename = FFTEMPL.template_filename or "default.tpl"
	local tpl_txt = readfile(FFTEMPL.template_filename)
	assert(tpl_txt, "Cannot read template file "..FFTEMPL.template_filename)

	for k, v in pairs(FFTEMPL.sections) do
		local escaped = v:gsub("%%", "%%%%") --Prevent "%1, %2..." expansion
		tpl_txt = tpl_txt:gsub("%(%("..k.."%)%)", escaped)
	end

	--Remove unmatched section markers
	local html = tpl_txt:gsub("%(%([%dA-Z_]+%)%)","")

	FFTEMPL.tags_filename = FFTEMPL.tags_filename or "default.tag"

	local tag_txt = readfile(FFTEMPL.tags_filename)
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
			FFTEMPL.log(tag.orig)
			FFTEMPL.log(tag.repl)
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
	return result
end

return main()
