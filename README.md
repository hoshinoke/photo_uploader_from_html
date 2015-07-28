# USAGE

prepare a html with `<img>`

```
$ cat dat.html
<h2>hello(^^</h2>
<li>
<img src="http://url.fullpath.example.com/fullpath/1.jpg">
</li>
```

do the command

```
$ cat dat.html | photo_uploader_from_html > dat2.html
```

then converted!

```
$ cat dat2.html
<h2>hello(^^</h2>
<li>
<img src="http://25.media.tumblr.com/someabc/tumblr_someabc.jpg">
</li>
```
