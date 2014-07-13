require('./spec_helper')
spy = require('through2-spy')

describe 'smoke test', ->
  createFS = require('../index')
  coffee = require('gulp-coffee')
  
  it 'should replace gulp', (done) ->  
    fs = createFS
          src:
            coffee:
              'sample.coffee': """
                console.log 'Hello world'
              """
              'another.coffee': """
                fib = (n) ->
                  switch n
                    when 0, 1
                      1
                    else
                      fib(n) + fib(n-1)  
              """
        
    fs.createReadStream 'src/coffee'
      .pipe coffee
        bare: true
      .pipe fs.createWriteStream('dest/js', true)
      .onFinished done, (folder) ->
        folder.should.equal fs.openFolder('dest/js')                
        folder['sample.js'].should.not.be.null
        folder['another.js'].should.not.be.null
      