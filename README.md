# FFTempl

Extremely simple but extremely powerful website templating and server side scripting using LuaJIT and anything else you like (used on www.fuxoft.cz).

Documentation version: [[*<= Version '20180302c' =>*]]

Warning: If you are not already familiar with Lua language and/or if you don't run your own HTTP server on your own machine, it's highly unlikely you'll find FFTempl useful in any way.

## About FFTempl

FFTempl allows you to have (almost) absolute freedom in mixing dynamic and static content using various templates and scripts, without need for any database. You only need LuaJIT installed (available as package in Ubuntu and Debian) and a sensible webserver that allows for CGI execution and URL rewriting. The core FFTempl system is (like Lua itself) extremely simple but allows you to expand its possibilities almost limitlessly.

FFTempl was tested using Apache 2 on Linux, I have no idea if and how it works under different servers / OSes (it probably won't without some tweaking because it uses ``os.getenv('QUERY_STRING')`` to get the URL parameters from Apache).

I made FFTempl to satisfy my needs which are probably different from what you need. If you find it useful, great. If you don't, please use one of many other dynamic content systems that are freely available. It's probably meaningless to ask me to "implement this or that" in FFTempl because you can implement almost everything yourself, using hooks, without changing the core system. But I am open to suggestions.

## What FFTempl allows you to do

Your whole HTML site is stored as static files in any directory structure you deem necessary (as if you used normal static webpages). FFTempl itself and template files are all stored in a single directory called called ``fftempl/`` in your website root directory. The name of this directory can be changed (see below).

The most important principle of FFTempl operation is as follows: FFTempl is only concerned with files that have ".htm" extension and leaves all other files alone. That means you can have .php or .html (yes, ".html" is something different than ".htm") or .gif or .swf files on your website and FFTempl does not care about them at all - how they are handled depends on your webserver configuration only and has nothing to do with FFTempl. Note that FFTempl is perfectly capable of generating dynamic .gif or .swf files (or any other files to be delivered by your webserver) but the scripts that generate them must have the .htm extension (and correctly set the content-type for the generated file).

FFTempl springs into action every time a file with ".htm" extension is requested. If someone requests file called ``/dir1/dir2/page.htm`` from your webserver, this request is redirected to FFTempl, which loads this file from disk (this is not a HTML file but "FFTempl source file", explained later), parses it and returns the result to the webbrowser which asked for it. "Parsing the file" means that template, tags and/or scripts are applied to the file. You can do almost anything, including incorporating the results of arbitrary OS commands into your pages. Thanks to templates and tags, it's very easy to make different parts of your website available in different designs and layouts, each of which only has to be defined once to immediately propagate the changes to whole site. To a casual visitor, your website looks like it consists only of static HTM pages (unless you want it to look like dynamically generated website).

Once more: The directory structure is entirely up to you (except for the required ``fftempl/`` directory). The only rule is that if something has to be dynamic or use templates, it has to have the ".htm" extension. Other files are not altered by FFTempl in any way. Note that all your normal webserver configuration is still in effect for all files.

## What FFTempl does NOT allow you to do

If you are excited after reading the previous paragraphs, please curb your enthusiasm. You must understand what FFTempl is not:

FFTempl does not provide any means for "live" editing of your online pages. How you create your web contents and templates and how you transfer them to your webserver is entirely up to you (personally, I have the whole website structure on my home PC, edit it using texteditor and then transfer the changes online using rsync).

FFTempl does not incorporate WYSIWYG in any shape or form. You have to understand HTML/CSS if your want to create your own webdesigns and you have to understand Lua if you want to create your own scripts. All the content is defined using text files. You don't have to understand Apache or change its configuration after you successfully installed FFTempl.

## Security

FFTempl is not very "secure", although this needs longer explanation: I think FFTempl is very secure in the sense that person who visits your website cannot use FFTempl to gain unauthorized access to your system or to see files outside of your public HTML directory. On the other hand, it's not very difficult, under the default FFTempl configuration, for knowledgeable person to see your FFTempl source, template and tag files, your FFTempl scripts etc... FFTempl may be made more "obscured" by choosing hard-to-guess filenames for these files but this is not something I needed or wanted.

FFTempl does not "hold you by the hand". With great power comes great responsibility. There is nothing in FFTempl that prevents you from creating megabytes of useless output or scripts that consume 100% of your CPU or erase your important files. You have been warned. Also note that your FFTempl scripts run with full Apache CGI script permissions! If you want to change this, you have to properly configure Apache, not FFTempl.


## Installation

Installing FFTempl on your server requires a working webserver (preferably Apache), LuaJIT scripting language and nothing else. No database, no PHP, no Java, no other libraries, nothing. Actually, it also requires small but specific tweaking of your webserver configuration. If your pages are hosted on some basic free webhosting service, you probably won't be able to run FFTempl at all.

First, download the latest version of FFTempl and put all the files into the directory called "fftempl" which should reside in your document root.

Check that you have LuaJIT installed (command ``luajit`` should work).

The following instructions are written with Apache 2 in mind:

Run your webserver (if not already running), open your favorite web browser and point it to "http://yourServerDomain.com/fftempl/fftempl.cgi". You should see the output of running the script fftempl.cgi but you probably won't see it at the first try. That's because you don't have your webserver configured to execute this script. In Apache, this can be done for example by adding the following lines to your httpd.conf:

```
AddHandler cgi-script .cgi
Options +ExecCGI
```

Also make sure that the CGI file has correct attributes and permissions to be executed by the webserver. When you get some sort of "FFTempl error" in your browser, that means FFTempl is getting invoked, you are on the right path and you can continue to the next step.

Then, you must configure the redirection of ".htm" file requests. Again, this can be done in several ways, for example adding .htaccess file with the following contents to your document root, if you have RewriteEngine module included in your Apache, which you probably have (you must also allow the required .htaccess override in your server config file):

```
RewriteEngine on
RewriteBase /
RewriteRule ^(.*\.htm)$ /fftempl/fftempl.cgi?fftempl_htm_file=$1 [PT,QSA]
```

If you don't understand what this means or if you don't use Apache 2: The idea is that all .htm file requests should be automatically rewritten from ``/some_dir/some_file.htm?some_parameter=some_value`` to ``/fftempl/fftempl.cgi?fftempl_htm_file=/some_dir/some_file.htm&some_parameter=some_value``.

If subsequent visit of page ``some_random_nonexistent_name.htm`` (must end with ".htm"!) on your webserver displays FFTempl error message, congratulations! FFTempl is installed and you can start using it.

For increased security, you can change the name of the directory from "fftempl" to "superSecretFFTemplDirectory", for example (and change the redirection rule accordingly). You don't have to change anything else. FFTempl just expects to find the document root exactly one directory level above itself.

## Basic Terminology

Each page FFTempl generates is created from its source file, template file and tag file.

Source files contain the actual dynamic content of the page. Source files have the ".htm" extension and can be located anywhere on your website (even inside the "fftempl" directory!). Source files can also contain page-specific Lua scripts which are to be executed.

Template files define the basic rules of transforming the source files into something that almost resembles HTML. They use the ".tpl" extension and are located inside the "fftempl" directory. The template files usually define the pages' colors, fonts and other common elements like header and footer (but can also define anything else). Many different source files can use the same template file and there can be any number of different template files, each for different part of your site.

Tag files define your own (pseudo)HTML tags. Basically, it defines which sequences of characters should be replaced by other sequences of characters or by results of running your custom scripts. For example, you can define your own HTML tag called ``{crazy_divider}`` which will be replaced by the following HTML code:

```
<center>
- o - o - o - o - o -
</center>
```

This replacement will happen each time the tag ``{crazy_divider}`` appears in your source or template file. Tag files use the ".tag" extension and are all stored in the "fftempl" directory. As with template files, many different source files can use the same tag file and there can be any number of different tag files for different parts of your site.

## How does it work

If any document ending with ".htm" is requested, FFTempl loads the source file (of the same name) from the disk (again: The ".htm" files don't contain HTML code bude "pseudocode" which is used to generate the HTML the websurfer sees). The source consists of any number of parameters and each parameter begins with line containing its name, enclosed in double parentheses. The simple .htm file could look like this:

```
((TITLE))
Hello World webpage
((BODY))
HELLO WORLD!
```

As a next step, FFTempl loads the relevant template file. The template file is usually "fftempl/default.tpl" but this can be overriden.

The template files look almost like a HTML page. What FFTempl does now is that it takes the template and replaces all occurences of string "((paramname))" with the contents of parameter called paramname (from the original ".htm" source file). If the template file contains parameter which does not exist in the source file, it's silently discarded from the result.

We now have something that resembles HTML page (let's call it "intermediate page") but we are not done yet.

Now we load the relevant tag file from the disk. As was the case with the template file, tag file can be overriden on a file-by-file basis using the LuaJIT variable FFTEMPL.tags_filename but if it's not present, "fftempl/default.tag" file is used by default.

The tag file consists of lines which have the following format:

```
tag := replacement
```

FFTempl now looks for all instances of each tag in the intermediate page and replaces each of them with the relevant replacement. Note that both tag and replacement can be anything at all and they don't have to be enclosed in parentheses. I used parentheses because they are easily accessed even when I am using the Czech keyboard. If you are working on U.S. keyboard you should probably use some less common delimiters like "" or "{}"... Or you don't have to use the delimiters at all and write something like StartOfBoldText, if you are bold. The choice is yours.

FFTempl also supports more complicated tags with parameters. Those use ":=!" instead of ":=". In this case, both "tag" and "replacement" are not simple string but search and replace strings according to Lua's ``string.match()`` format so __they have to be properly escaped__. For example, let's say you define the following tag:

```
%(mailto "(.-)"%) :=! (ahref "mailto:%1")%1(/a)
```

Then, if you include the following text anywhere in your source file (or template - it doesn't matter because it appears in the intermediate file in both cases):

```
My e-mail is (mailto "satan@hell.sk"), write to me!
```

it gets automatically expanded to:

```
My e-mail is (ahref="mailto:satan@hell.sk")satan@hell.sk(/a), write to me!
```

Note that the lines in .tag file are interpreted and replaced one by one, from top to bottom, and this order is very significant because it can be used for tags wrapped by other tags. In the specific example above, there should be other lines in the .tag file (after this mailto line) that expand (ahref=...) to &lt;a href=...>, (/a) to &lt;/a> etc., so that the result is actual valid HTML.

Now think for a little while about the possibilities all of this gives to you. However, there is lots more that FFTempl can do for you!

## Advanced usage

If you want to create dynamic content, you need to learn Lua. The reasons I rewrote FFTempl from Ruby to Lua were Lua's great speed, small footprint and the fact that Lua scripts are easily "hackable" and modifiable during the runtine (i.e. scripts modifying themselves) which is very useful in FFTempl.

After you learn Lua (which is really very simple and elegant language), just look at the main two FFTempl files: "fftempl.cgi" and "fftempl_core.lua". They contain all the functionality of FFTempl in just a few kilobytes of Lua code and you can see what other mechanisms FFTempl allows. For example, what exactly happens if someone requests non-existent .htm page.

## Arbitrary copmplex Lua code using LUASCRIPT tag

The .htm file can begin with special --LUASCRIPT tag which allows you to include arbitrary Lua code right in the page source. The tag must be at the beginning of the file, before everything else. For example, the .htm file can begin like this:

```
--LUASCRIPT
FFTEMPL.add_lua_tag('%(days_age "(%d*)%.(%d*)%.(%d*)"%)', function (d,m,y)
	local days = (os.time() - os.time{year=tonumber(y); month=tonumber(m); day=tonumber(d); hour = 6}) / (60*60*24)
	return tostring(math.floor(days+0.5))
end)
--/LUASCRIPT
((TITLE))
My Homepage
((BODY))
I was born on January 20, 1980, so today I am exactly (days_age "20.1.1980") days old!
...etc...
```

The LuaJIT code between the two LUASCRIPT tags (which must look exactly like in this example) is executed and can add tags, execution hooks and do lots of other stuff (even including and executing other separate .lua files).

The LUASCRIPT code is called as soon as possible, before all other parsing, so it can override the tag file, the template file, change the content-type of the HTTP response, set and read the cookies, etc... Have a look at the fftempl_core.lua source.

## Double dash parameter masking

This scary name hides rather simple feature: Whenever the web client asks fftempl for a page which is named ``foo--bar.htm`` (contains double dash), this name is automagically and transparently changed to ``foo.htm?_dash_argument=bar``. What use is this? The easiest way to explain is to look at http://fuxoft.cz/redmeat/. You see dozens of links on that page, which seem to point to dozens of different static pages, each of which contains a comic strip. In fact, all strips are displayed using the same .htm source page called "strip.htm". For example, the URL ``/redmeat/strip--zoo.jpg.htm`` is automatically expanded to ``/redmeat/strip.htm?_dash_argument=zoo.jpg``. The "strip.htm" page just looks at what's in the variable args._dash_argument and displays the specific image file.

(By the way, the "FFTEMPL.args" Lua table always contains all GET arguments of the current HTTP request available for your perusal.)

Are you still asking what's this good for? It allows your parametrized dynamic pages to look as if they were static pages. That means they can be better indexed by search engines, for example, or mirrored by download programs.

Note that the part before the (first) "--" is non-greedy, i.e. the URL ``/foo--bar--baz.htm`` gets replaced by ``/foo.htm?_dash_argument=bar--baz``. Also note that you probably encounter horrible problems if your site contains any .htm files whose name contains "--" (that was the reason why I chose this rather unusual combination, which is hardcoded into FFTempl).

## Persistence and speed

This is probably the right time to stress that FFTempl has no status persistence at all. Everything is loaded and invoked from scratch with each request and everything is deleted and forgotten after handling the request. I think this is good thing because you don't have to worry whether your tricks with hooks and _CODE changed the FFTempl functionality in some undesired way.

The speed (all scripts have to be compiled from scratch for each request) also doesn't seem to be a problem even on our old server. However, to lower the system load under critical conditions, you could use luac to pre-compile "fftempl.lua" and "custom.lua" files (see Lua documentation).

The only drawback is the fact that lack of persistence prohibits you from having for example some global page visit counter. However, even this can be done in FFTempl - you just have to store the dynamic data somewhere on disk (beware of the right permissions) or call some database from your FFTempl script using ``os.execute()`` or ``os.popen()``. Also, your scripts can set and use cookies, of course.
