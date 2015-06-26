--FFTempl
--by Frantisek Fuka
--See http://fftempl.googlecode.com

--This is the main parser file which is called from "fftempl.cgi"

FFTEMPL.call_hook = function (hook, ...)
	local hookfun = FFTEMPL.hook[hook]
	if not hookfun then --function not defined
		return
	end
	if type(hookfun) ~= 'function' then
		error ("Custom hook refers to something else than a function.")
	end
	return hookfun(...)
end

------------------------------------------------------ MAIN()
FFTEMPL.main = function ()

	local dbg = function () return end --Logging disabled, used only for development
	--You can use FFTEMPL.log() function in your own extensions to display debug information!

	function parseArguments(str) --parse the arguments in HTTP request, e.g. 'foo=hello&bar=69'
		local args={}
		local str0 = str:match("^(.-)#") or str
		for key, value in string.gmatch(str0..'&','([_%w]-)=(.-)&') do
			args[key] = value
		end
		return args
	end

	local callHook = FFTEMPL.call_hook
	function isLineBreak(byte)
		return byte == 10 or byte == 13 or not byte
	end

	local function parse_code()
		if FFTEMPL.params._CODE then
			local status,result = loadstring(FFTEMPL.params._CODE) --load custom extensions and hooks
			if not status then
				error('error in _CODE section of .htm file\n'..result)
			end
			dbg('parsing _CODE segment')
			return status()
		end
	end

	local function loadf(fname)
		assert(type(fname) == 'string', 'String filename expected')
		local fd=io.open(fname)
		if fd then
			local lines = {}
			while true do
				local line = fd:read()
				if not line then
					break
				end
				line = line:gsub("[\n\r]*","")
				table.insert(lines,line)
			end
			fd:close()
			return table.concat(lines,"\n"), lines
		else
			return nil, 'Cannot open file: ' .. fname
		end
	end

	--Here we go.
	--Try loading and executing "custom.lua"
	local status,result = pcall(dofile,"custom.lua") --load custom extensions and hooks
	if not status and not string.match(result,"cannot open custom.lua") then
		return FFTEMPL.error_HTML('Local "custom.lua" file contains an error. Please inform whoever is running this site!\n'..result)
	end

	local query_string=assert(os.getenv('QUERY_STRING'),'unable to get QUERY_STRING from environment')

	args=parseArguments(query_string) --_G.args is deprecated, use FFTEMPL.args
	FFTEMPL.args=args

	--args.file=assert(os.getenv('SCRIPT_NAME'), "Unable to get SCRIPT_NAME from environment")
	-- if true then return ("fname="..args.file) end -------

	assert (args.file, "Undefined 'file' parameter in QUERY_STRING. Webserver configuration error?")

	if string.match(args.file,'%.%.') then
		error ("Yes, you are l33t h&x0r. Please don't do that again.")
	end

	-- The following handles the special dynamic pages whose names contain "--".
	-- see "Double dash parameter masking" in the Docs
	local file0, param0 = args.file:match("(.-)%-%-(.+)%.htm")
	if file0 and param0 then
		args.file = file0 .. ".htm"
		args._dash_argument = param0
	end

	local file
	file, FFTEMPL.raw_file_lines = loadf('../' .. args.file)
	if not file then
		file = callHook('get_missing_file',args.file)
		if not file then
			file, FFTEMPL.raw_file_lines = loadf('../'..FFTEMPL.pageNe404)
			-- note that this "404 error" page actually does not generate HTTP error code 404. It's just a normal page!
			if not file then
				return('<html><b>FFTempl Error!</b> File <b>/'..FFTEMPL.page404.."</b> should contain the 404 error page but it does not exist. Either create it or change FFTEMPL.page404 variable (in 'custom.lua').</html>")
			end
		end
	end

	FFTEMPL.raw_file = file or '--no raw source--'
	callHook('we_have_the_file')

	FFTEMPL.params = {}
	local params = FFTEMPL.params

	local result = ''

	local curtag = nil
	local curline = ''
	local function addTag(t,k,v)
		if not t[k] then
			t[k] = v
			dbg('New param '..k..' = '..v)
		elseif type(t[k]) == 'table' then
			table.insert(t[k], v)
			dbg('Multiparam '..k..': ' .. #t[k] .. ' items')
		else
			t[k] = {t[k], v}
			dbg('Param '..k..' is now multiparam (2 items)')
		end
	end
--	for line in (file.."\n"):gmatch("(.-)\n") do
	for _,line in ipairs(FFTEMPL.raw_file_lines) do
--		for line in (file.."\n"):gmatch("(.-)\n") do
	dbg('line=['..line..']')
	local tag=string.match(line,'^%(%((%S-)%)%)$')
		if tag then
			if curtag then
				addTag(params, curtag, curline)
			end
			curtag = tag
			curline = ''
		else	--normal line
			if curline ~= '' then
				curline = curline .. '\n'
			end
			curline = curline .. line
		end
	end
	addTag(params, curtag, curline)

	callHook('parameters_parsed')
	parse_code() -- parse and execute optional _CODE section in source file

	params._TEMPLATE = params._TEMPLATE or 'default'
	params._TAGS = params._TAGS or 'default'

	file = assert(loadf(params._TEMPLATE .. '.tpl'))
	FFTEMPL.raw_template = file

	local function randomId()
		return 'X'..math.random(99999999)..'x'..os.time()..'x'
	end

	local keys = {}
	for key in string.gmatch(file,'%(%(([_%w]-)%)%)') do
		keys[key]=true
	end

	local ids = {}
	math.randomseed(os.time())
	for key,_ in pairs(keys) do
		local id = randomId()
		ids[id] = key
		file = string.gsub(file,'%(%('..key..'%)%)',id)
	end

	for id,key in pairs(ids) do
		if not params[key] then params[key] = {} end
		local value = params[key]
		if type(value) == 'string' then
			file,howmany = string.gsub(file,id, (string.gsub(value,'%%','%%%%')))
		else -- it's multiparameter - this is more complex.
			assert(type(value) == 'table')
			local from, to = string.find(file,id, 1, true)
			if from then
				local pre, post = from - 1, to + 1
				while not isLineBreak(string.byte(file, from-1)) do
					from = from - 1
				end
				while not isLineBreak(string.byte(file, to+1)) do
					to = to + 1
				end
				pre = string.sub(file, from, pre)
				post = string.sub(file, post, to)
				local line = string.sub(file, from, to)
				local lines = {}
				for _,oneval in ipairs(value) do
					table.insert(lines, pre .. oneval .. post)
				end
				file = string.sub(file, 1, from-1) .. table.concat(lines,'\n') .. string.sub(file, to+1)
			end
		end
	end

	local tags = assert(loadf(params._TAGS .. '.tag'))
	FFTEMPL.raw_tags = tags
	callHook('tags_loaded')
	tags = (params._EXTRATAGS or '')..'\n'..tags
	for line in (tags.."\n"):gmatch("(.-)\n") do
		if line ~= '' then
			local tag, op, replace = string.match(line,'(.-)%s*(:=!?)%s*(.*)')
			assert (op == ':=' or op == ':=!', 'Invalid tag line: '..line)
			replace = string.gsub(replace,'%%','%%%%')
			local textTag = string.gsub(tag, "([^%w%s])", "%%%1")
			local hasDollar = string.match(line,'%$')
			if op == ':=' then
				if hasDollar then --simple replace with $ parameter
					local replacer = string.gsub(replace,'%$','%%1')
					dbg(string.gsub(textTag,'%%%$','(.-)') .. ' x ' .. replacer)
					file, howmany = string.gsub(file, string.gsub(textTag,'%%%$','(.-)'), replacer)
					dbg(howmany..'x')
				else --simplest replace without $
					dbg('tag: '..textTag)
					dbg('replace: '..replace)
					file = string.gsub(file, textTag, replace)
				end
			else	--calling custom script
				dbg('calling '..replace)
				file, howmany = string.gsub(file, string.gsub(textTag,'%%%$','(.-)'), function (str)
					if type(_G[replace])~='function' then
						error ('function "'..replace..'", called from the tag file, does not exist')
					end
					return _G[replace](str)
				end)
			end
		end
	end
	FFTEMPL.file = file
	callHook('last_chance')
	return FFTEMPL.file
end

FFTEMPL.page404='404.htm' -- this page is displayed when no page is actually found
FFTEMPL.hook = {} -- Custom hooks (see "custom.lua" file)
return FFTEMPL.main()
