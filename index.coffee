path= require 'path'
jsfy= (options={})->
  queues= []
  through= require 'through'
  through (file)->
    return this.emit 'data',file if file.path.substr(-4) isnt '.css'

    queues.push (next)=>
      jsfy.parse file,options,(error,js)=>
        return next error if error?

        file.path+= '.js'
        file.contents= new Buffer js
        this.emit 'data',file

        next null
  ,->
    async= require 'async'
    async.parallel queues,(error)=>
      throw error if error?

      this.emit 'end'

jsfy.parse= (file,args...)->
  callback= undefined
  options= undefined
  args.forEach (arg)-> switch typeof arg
    when 'function' then callback= arg
    when 'object' then options= arg

  deval= (error,file)=>
    return callback error if error?

    name= path.basename(file.path,'.css')

    if options.dataurl
      jsfy.replaceToDataURI file,options,(error,css)->
        return callback error if error?

        file.contents= new Buffer css

        callback null,jsfy.deval file,name,options
    else
      callback null,jsfy.deval file,name,options

  if options.wrapInClass
    jsfy.wrap file,options,(error,css)=>
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

  change= require 'change-case'
  """
    (function(){
      var link=document.createElement('link');
      link.setAttribute('data-name','#{change.snakeCase(name)}');
      link.setAttribute('rel','stylesheet');
      link.setAttribute('href',"#{jsfy.dataurify css,'text/css',charset}");
      document.head.appendChild(link);
    })();
  """

jsfy.dataurify= (str,mime,charset='')->
  data= if typeof str is 'object' then str.contents else new Buffer str
  charset= ";charset=#{charset}" if charset.length > 0 and charset.indexOf(';') isnt 0
  "data:#{mime}#{charset};base64,#{data.toString('base64')}"

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
  matches= str.match(pattern) || []

  async= require 'async'
  async.map matches,(match,next)->
    begin= match.indexOf('(')+1
    end= match.length-begin-1
    schema= match.substr(begin,end).replace /"|'/g,''

    is_local= schema.indexOf('http') isnt 0
    schema= path.resolve path.dirname(file.path),schema if is_local

    if is_local
      schema= schema.replace /(\?#\w+|#\w+)$/,'' # fix: slick-carousel.css > url("./fonts/slick.eot?#iefix")
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
  fs= require 'fs'
  fs.readFile filename,(error,buffer)->
    if error is null
      mime= require('mime').lookup filename
      data= buffer.toString 'base64'

      callback null,"data:#{mime};base64,#{data}"
    else
      callback error

jsfy.fetchDataURI= (url,callback)->
  http= require 'http'
  http.get url,(response)->
    response.on 'data',(buffer)->
      mime=  response?.headers?['content-type']
      data= buffer.toString 'base64'

      callback null,"data:#{mime};base64,#{data}"
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

  change= require 'change-case'
  css= file.contents.toString()
  className= change.snakeCase(path.basename file.path,'.css')

  # example: 
  #   css= html{...},body{...}
  #   stylus.render ".className{ css }""
  #     -> ".className html{...} .className body{...}"
  stylus= require 'stylus'
  stylus.render ".#{className}{ #{css} }",(error,css)->
    callback error,css

module.exports= jsfy