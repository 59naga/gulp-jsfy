gulp= require 'gulp'
jsfy= require './'
fs= require 'fs'

describe 'gulp-jsfy',->
  css= 'fixtures/second.css'
  now= Date.now()
  content= "body:before{content:\"#{now}\"}"

  beforeEach ->
    try
      fs.writeFileSync css,content
      fs.unlinkSync "#{css}.js"

  it 'only jsfy for .css',(done)->
    gulp.src 'fixtures/*'
      .pipe jsfy()
      .pipe gulp.dest 'fixtures'
      .on 'end',()->
        expect(fs.readFileSync "#{css}.js").toMatch encodeURIComponent content
        
        done()
