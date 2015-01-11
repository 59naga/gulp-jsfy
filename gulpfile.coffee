gulp= require 'gulp'
gulp.task 'default',->
  gulp.src '*.spec.coffee'
    .pipe require('gulp-jasmine')
      verbose:true