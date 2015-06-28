# gulp-jsfy [![NPM version][npm-image]][npm] [![Build Status][travis-image]][travis]

> transform .css to .js append to &lt;head&gt;

## Installation
```bash
$ npm install gulp-jsfy
```

## Plugin Usage
```bash
gulp=   require 'gulp'
gulp.task 'default',->
  main=   require 'main-bower-files'
  jsfy=   require 'gulp-jsfy'
  concat= require 'gulp-concat'

  gulp.src main()
    .pipe jsfy dataurl:true
    .pipe concat 'bower_components.js'
    .pipe gulp.dest 'public_html'
```

## Plugin Options
* dataurl:`false`
  * `true`: Replace `url(relative/URL)` to `url(DATAURI)`
* ignoreURL:`false`
  * `true`: Don't Replace `url(URL)`
  
<!--
### Deprecated
* wrapInClass:`false`
  * `true`: (Experimental) Wrap all selector into the .className{} [e.g.][1]

[1]: https://github.com/59naga/gulp-jsfy-example
-->

## How do transform to .js ?
It's transform .css into `<link href="DATAURI">`.js And resolve `url()` references.
Becomes css is standalone.

### Example
[animate.css](http://daneden.github.io/animate.css/)

```css
@charset "UTF-8";
/*!
Animate.css - http://daneden.me/animate
Licensed under the MIT license - http://opensource.org/licenses/MIT

Copyright (c) 2014 Daniel Eden
...
*/
```

gulpfile.coffee

```coffee
gulp= require 'gulp'
jsfy= require 'gulp-jsfy'

gulp.task 'default',->
  gulp.src 'animate.css'
    .pipe jsfy()
    .pipe gulp.dest './'
```

Execute gulp

```bash
$ npm install gulp gulp-jsfy coffee-script
$ gulp
# Finished 'default' after 37 ms
```

Become animate.css.js

```js
(function(){
  var link=document.createElement('link');
  link.setAttribute('data-name','animate');
  link.setAttribute('rel','stylesheet');
  link.setAttribute('href',"data:text/css;charset=utf8;base64,QGNoYXJzZXQgIlVU..."
  document.head.appendChild(link);
})();
```

License
=========================
[MIT][license]

[license]: http://59naga.mit-license.org/
[npm-image]: https://badge.fury.io/js/gulp-jsfy.svg
[npm]: https://npmjs.org/package/gulp-jsfy
[travis-image]: https://travis-ci.org/59naga/gulp-jsfy.svg?branch=master
[travis]: https://travis-ci.org/59naga/gulp-jsfy
[depstat-image]: https://gemnasium.com/59naga/gulp-jsfy.svg
[depstat]: https://gemnasium.com/59naga/gulp-jsfy