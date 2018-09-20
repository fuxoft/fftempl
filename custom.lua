--Custom stuff to include for your whole website
--Use hooks described in fftempl_core.lua

FFTEMPL.hooks.sections = function()
	local dir = FFTEMPL.htm_dir
	local file = FFTEMPL.htm_file
	local path = dir..file
	path = path:gsub("^/home/fuxoft/work/web/","http://www.")
	path = path:match("^.+/")

	if FFTEMPL.http_status_code == "404" then
		path = "http://www.fuxoft.cz/404error.htm"
	end

	local chunk=string.format([[<div id="disqus_thread"></div>
<script>

/**
*  RECOMMENDED CONFIGURATION VARIABLES: EDIT AND UNCOMMENT THE SECTION BELOW TO INSERT DYNAMIC VALUES FROM YOUR PLATFORM OR CMS.
*  LEARN WHY DEFINING THESE VARIABLES IS IMPORTANT: https://disqus.com/admin/universalcode/#configuration-variables*/
/*
var disqus_config = function () {
this.page.url = '%s';  // Replace PAGE_URL with your page's canonical URL variable
this.page.identifier = '%s'; // Replace PAGE_IDENTIFIER with your page's unique identifier variable
};
*/
(function() { // DON'T EDIT BELOW THIS LINE
var d = document, s = d.createElement('script');
s.src = 'https://fuxoft.disqus.com/embed.js';
s.setAttribute('data-timestamp', +new Date());
(d.head || d.body).appendChild(s);
})();
</script>
<noscript>Please enable JavaScript to view the <a href="https://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>]], path, path)

	FFTEMPL.sections.DISQUS = chunk
end

return