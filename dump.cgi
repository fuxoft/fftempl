#!/usr/bin/env lua5.2

print("Content-type: text/html; charset=UTF-8\n\n")
local str = io.read(10)
print("GOT:"..tostring(str)..":\n\nOK")

--[[
OK z Apache:
export CONTENT_LENGTH='31'
export CONTENT_TYPE='application/x-www-form-urlencoded'
export DOCUMENT_ROOT='/home/fuxoft/work/web/fuxoft.cz'
export GATEWAY_INTERFACE='CGI/1.1'
export HTTP_ACCEPT='text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
export HTTP_ACCEPT_CHARSET='UTF-8,*;q=0.5'
export HTTP_ACCEPT_ENCODING='gzip,deflate,sdch'
export HTTP_ACCEPT_LANGUAGE='cs,en-US;q=0.8,en;q=0.6'
export HTTP_CACHE_CONTROL='max-age=0'
export HTTP_CONNECTION='keep-alive'
export HTTP_HOST='localhost'
export HTTP_ORIGIN='http://localhost'
export HTTP_REFERER='http://localhost/fftempl/post.html'
export HTTP_USER_AGENT='Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.70 Safari/537.17'
export PATH='/usr/local/bin:/usr/bin:/bin'
export PWD='/media/DISK2/fuxoft_work/web/fuxoft.cz/fftempl'
export QUERY_STRING='jmeno=podpis'
export REMOTE_ADDR='127.0.0.1'
export REMOTE_PORT='45024'
export REQUEST_METHOD='POST'
export REQUEST_URI='/fftempl/test.cgi?jmeno=podpis'
export SCRIPT_FILENAME='/home/fuxoft/work/web/fuxoft.cz/fftempl/test.cgi'
export SCRIPT_NAME='/fftempl/test.cgi'
export SERVER_ADDR='127.0.0.1'
export SERVER_ADMIN='fuka@fuxoft.cz'
export SERVER_NAME='localhost'
export SERVER_PORT='80'
export SERVER_PROTOCOL='HTTP/1.1'
export SERVER_SIGNATURE='<address>Apache/2.2.22 (Ubuntu) Server at localhost Port 80</address>
'
export SERVER_SOFTWARE='Apache/2.2.22 (Ubuntu)'
	]]