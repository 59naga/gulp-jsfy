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
  .pipe jsfy()
  .pipe concat 'bower_components.js'
```