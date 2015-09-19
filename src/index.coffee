fs= require 'fs'
path= require 'path'
http= require 'http'

through2= require 'through2'

async= require 'async'
change= require 'change-case'
mime= require 'mime'
stylus= require 'stylus'

gutil= require 'gulp-util'

jsfy= (options={})->
  through2.obj (file,encode,next)->
    if file.isStream()
      return @emit 'error',new gutil.PluginError 'gulp-jsfy','Streaming not supported'

    if file.path.substr(-4) isnt '.css'
      @push file
      return next()

    jsfy.parse file,options,(error,js)=>
      return @emit 'error',new gutil.PluginError 'gulp-jsfy',error if error?

      file.path+= '.js'
      file.contents= new Buffer js
      @push file

      next()

jsfy.parse= (file,args...)->
  callback= undefined
  options= {}
  args.forEach (arg)-> switch typeof arg
    when 'function' then callback= arg
    when 'object' then options= arg

  deval= (error,file)->
    return callback error if error?

    name= path.basename file.path,'.css'

    if options.dataurl
      jsfy.replaceToDataURI file,options,(error,css)->
        return callback error if error?

        file.contents= new Buffer css

        callback null,jsfy.deval file,name,options
    else
      callback null,jsfy.deval file,name,options

  if options.wrapInClass
    jsfy.wrap file,options,(error,css)->
      return deval error if error?

      file.contents= new Buffer css

      deval null,file,null,options
  else
    deval null,file,null,options

jsfy.deval= (css,args...)->
  name= undefined
  charset= 'utf8'
  options= {}
  args.forEach (arg)-> switch typeof arg
    when 'string' then name= arg
    when 'object' then options= arg

  charset= '' if options.charset is false

  """
    ;(function(){
      var link=document.createElement('link');
      link.setAttribute('data-name','#{change.snakeCase(name)}');
      link.setAttribute('rel','stylesheet');
      link.setAttribute('href',"#{jsfy.dataurify css,'text/css',charset}");
      document.head.appendChild(link);
    })();
  """

jsfy.dataurify= (str,type,charset='')->
  data= if typeof str is 'object' then str.contents else new Buffer str
  charset= ";charset=#{charset}" if charset.length > 0 and charset.indexOf(';') isnt 0
  "data:#{type}#{charset};base64,#{data.toString('base64')}"

jsfy.cssfy= (devalJs)->
  begin= devalJs.indexOf 'data:text/css;'
  end= devalJs.indexOf('"',begin) - begin
  dataurl= (new Buffer devalJs.substr(begin,end),'base64').toString('utf8')
  (new Buffer devalJs.substr(begin,end).split(',')[1],'base64').toString()
  
jsfy.replaceLocalPattern= ///
# only match: url("./path/to/file.ext")
url\(
  (?!(["']?(data|http)))
  .+?
\)
///g
jsfy.replaceGlobalPattern= ///
# add match: url('http://berabou.me/.../ootani_oniji_1x.png')
url\(
  (?!(["']?(data)))
  .+?
\)
///g
jsfy.replaceToDataURI= (file,args...)->
  callback= undefined
  pattern= undefined
  options= {}
  args.forEach (arg)-> switch typeof arg
    when 'function' then callback= arg
    when 'string' then pattern= arg
    when 'object' then options= arg

  if pattern is undefined
    pattern= if options.ignoreURL then jsfy.replaceLocalPattern else jsfy.replaceGlobalPattern

  str= file.contents.toString()
  matches= str.match(pattern) or []

  async.map matches,(match,next)->
    begin= match.indexOf('(')+1
    end= match.length-begin-1
    schema= match.substr(begin,end).replace /"|'/g,''

    is_local= schema.indexOf('http') isnt 0
    schema= path.resolve path.dirname(file.path),schema if is_local

    if is_local
      # delete qs/hash for fs.readFile
      # eg: ./fonts/slick.eot?query=string#iefix -> ./fonts/slick.eot
      [schema,qs]= schema.split /[\?#]/
      jsfy.readDataURI schema,(error,datauri)->
        str= str.replace match,"url(#{datauri})"
        next error
    else
      jsfy.fetchDataURI schema,(error,datauri)->
        str= str.replace match,"url(#{datauri})"
        next error

  ,(error)->
    callback error,str

jsfy.readDataURI= (filename,callback)->
  fs.readFile filename,(error,buffer)->
    if error is null
      type= mime.lookup filename
      data= buffer.toString 'base64'

      callback null,"data:#{type};base64,#{data}"
    else
      callback error

jsfy.fetchDataURI= (url,callback)->
  http.get url,(response)->
    chunks= ''
    response.on 'data',(buffer)->
      chunks+= buffer.toString()
    response.on 'end',->
      type= response?.headers?['content-type']
      callback null,"data:#{type};base64,#{(new Buffer chunks).toString('base64')}"
  .on 'error',(error)->
    callback error

jsfy.wrap= (file,args...)->
  callback= undefined
  className= undefined
  options= {}
  args.forEach (arg)-> switch typeof arg
    when 'function' then callback= arg
    when 'string' then className= arg
    when 'object' then options= arg

  css= file.contents.toString()
  className= change.snakeCase(path.basename file.path,'.css')

  # example:
  #   css= html{...},body{...}
  #   stylus.render ".className{ css }""
  #     -> ".className html{...} .className body{...}"
  stylus.render ".#{className}{ #{css} }",(error,css)->
    callback error,css

module.exports= jsfy
