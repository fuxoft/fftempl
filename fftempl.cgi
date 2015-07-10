#!/usr/bin/env luajit

--FFTempl
--by Frantisek Fuka
--v2015.06.15
--This is FFTempl loader which must never fail
_G.FFTEMPL = {debug = {log={}}}
FFTEMPL.fftempl_dir = "/home/fuxoft/work/web/fuxoft.cz/fftempl/"

function FFTEMPL.log(str)
	table.insert(FFTEMPL.debug.log, tostring(str))
end

local function fftempl_main()

	local function error_HTML(str)
		local debugtext = table.concat(FFTEMPL.debug.log,"<p>\n")
		if debugtext == "" then
			 debugtext="No debug text! <i>(You can log debug messages yourself by calling FFTEMPL.log() function)</i>"
		end
		return('<html><body><h1>FFTempl Error!</h1><pre>' .. str .. '</pre><p><h3>FFTEMPL DEBUG OUTPUT FOLLOWS:</h3><p>'..debugtext..'</body></html>')
	end

	local function err_fun(errstat)
		local tback = debug.traceback(errstat)
--[[	local start,msg,rest = tback:match("^(%S- )([^\n]*)(.+)$")
		if rest == rest then
			tback = "<b>"..tostring(start) .. "<font color=red>"..tostring(msg).."</font></b>"..tostring(rest)
		end
	]]
		return tback
	end

	local function doit()
		local result = dofile("fftempl_core.lua")
		assert(type(result)=="table", "Result is not table")
		assert(result.html, "Missing .html")
		assert(result.content_type, "Missing .content_type")
		assert(result.http_status_code,"Missing .http_status_code")
		return result
	end

	local status,result = xpcall(doit, err_fun)
	if not status then
		print("Status: 500") --Internal server error
		print("Content-type: text/html; charset=UTF-8")
		print()
		print(error_HTML(result))
	else
		print("Status: "..result.http_status_code)
		print("Content-type: "..result.content_type)
		print()
		if FFTEMPL.args.fftempl_debug=='messages' then --if the URL contains parameter "fftempl_debug=messages"
			print(table.concat(FFTEMPL.debug.log,"<p>\n"))
		end
		print(result.html)
	end
end

fftempl_main()
