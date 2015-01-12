# gulp-jsfy

## Usage
```bash
gulp= require 'gulp'
main= require 'main-bower-files'
jsfy= require 'gulp-jsfy'

gulp.src main
    paths:
      bowerDirectory:'bower_components'
      bowerJson:'bower.json'
  .pipe jsfy
    dataurl:true #replace url()
    <!-- offline:true #not replace url(http[s]), only relative -->
  .pipe concat 'bower_components.js'
  .pipe gulp.dest 'public_html'
```