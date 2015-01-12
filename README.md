# gulp-jsfy

## Usage
```bash
gulp=   require 'gulp'
jsfy=   require 'gulp-jsfy'
concat= require 'gulp-concat'
main=   require 'main-bower-files'

gulp.task 'default',->
  gulp.src main
      paths:
        bowerDirectory:'bower_components'
        bowerJson:'bower.json'
    .pipe jsfy
      dataurl:true
      ignoreURL:false #optional
      wrapClassName:false #optional
    .pipe concat 'bower_components.js'
    .pipe gulp.dest 'public_html'
```