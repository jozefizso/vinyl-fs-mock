require('./spec_helper')

describe 'FileSystem', ->
  {createFS} = require('../index') 
  FileSystem = createFS.FileSystem
  PathNotExistsException = createFS.PathNotExistsException
  File = createFS.File
  
  it 'should exists', ->
    createFS.should.be.ok
    FileSystem.should.be.ok

  describe 'create function', ->
    fsData = -> 
      'a.txt': 'text'
      'b.config': 'config'    

    it 'should create fs with 3 params', ->
      fs = createFS('sample', '/projects', fsData())
      fs.should.be.instanceOf FileSystem

      fs.fs.should.has.keys '.', '..', 'a.txt', 'b.config'
      fs.name().should.equal 'sample'
      fs.path().should.equal '/projects'

    it 'create fs with 2 params', ->
      fs = createFS('/projects/sample', fsData())
      fs.should.be.instanceOf FileSystem

      fs.fs.should.has.keys '.', '..', 'a.txt', 'b.config'
      fs.name().should.equal 'sample'
      fs.path().should.equal '/projects'
    
    describe 'create fs with 1 param', ->   
      it 'should take fs as root', ->
        fs = createFS(fsData())
        fs.should.be.instanceOf FileSystem      

        fs.fs.should.has.keys '.', '..', 'a.txt', 'b.config'
        fs.name().should.equal require('path').basename process.cwd()
        fs.path().should.equal require('path').dirname process.cwd()

      it 'should reserve existing data', ->
        data = fsData()
        data['.'] = 'project'
        data['..'] = '/projects'
        fs = createFS(data)
        fs.should.be.instanceOf FileSystem      

        fs.fs.should.has.keys '.', '..', 'a.txt', 'b.config'
        fs.name().should.equal 'project'
        fs.path().should.equal '/projects'

  describe 'basic attributes', ->
    fsData = ->
      '.': 'project'
      '..': '/projects'
      'a.txt': 'text'
      'b.bin': new Buffer('binary')
      'folder':
        'c.config': 'config'        

    it 'should read and write name', ->
      fs = createFS(fsData())

      fs.name().should.equal 'project'
      fs.name('new').should.equal('new')
      fs.name().should.equal 'new'
      fs.fs['.'].should.equal 'new'

    it 'should read and write path', ->
      fs = createFS(fsData())

      fs.path().should.equal '/projects'
      fs.path('/new').should.equal('/new')
      fs.path().should.equal '/new'
      fs.fs['..'].should.equal '/new'

    it 'should populate fullpath', ->
      fs = createFS(fsData())

      fs.fullpath().should.equal '/projects/project'

    it 'should fetch entry type', ->
      fs = createFS(fsData())

      fs.entryType('/projects/project/a.txt').should.equal 'file.text'
      fs.entryType('/projects/project/b.bin').should.equal 'file.binary'
      fs.entryType('/projects/project/folder').should.equal 'folder'
      
      fs.isFolder('/projects/project/folder').should.be.true
      fs.isFolder('/projects/project/a.txt').should.be.false
      fs.isFolder('/projects/project/b.bin').should.be.false

      fs.isFile('/projects/project/a.txt').should.be.true
      fs.isFile('/projects/project/b.bin').should.be.true
      fs.isFile('/projects/project/folder').should.be.false

  describe 'file operations', ->
    fsData = ->
      '.': ''
      '..': '/'
      'a.txt': 'text'
      'b.bin': new Buffer('binary')
      'folder':
        'c.config': 'config' 
        
    describe 'open folder', ->
      it 'should accept realive path', ->      
        fs = createFS '/x/y/z', fsData()

        folder = fs.openFolder('folder')
        folder.should.has.keys 'c.config'

      it 'should open existing folder', ->
        fs = createFS fsData()

        folder = fs.openFolder('/folder')

        folder.should.has.keys 'c.config'

      it 'should throw when path does not exist', ->
        fs = createFS fsData()

        expect ->
          fs.openFolder('/x/y/z')
        .to.throw PathNotExistsException, 'path x/y/z is invalid'
        
      it 'should create path when necessary', ->
        fs = createFS fsData()

        folder = fs.openFolder('/x/y/z', true)

        expect(fs.fs.x.y.z).to.be.ok

      it 'should resolve root', ->
        fs = createFS '/x/y/z', fsData()

        folder = fs.openFolder('/x/y/z')

        folder.should.equal fs.fs     

    describe 'resolve path', ->
      it 'should resolve relative path', ->
        fs = createFS '/x/y/z', fsData()        

        fs.resolvePath('folder').should.equal '/x/y/z/folder'

      it 'should resolve full path', ->
        fs = createFS '/x/y/z', fsData()        

        fs.resolvePath('/x/y/z/folder').should.equal '/x/y/z/folder'

      it 'should handle tail /', ->
        fs = createFS '/x/y/z', fsData()        

        fs.resolvePath('/x/y/z/folder/').should.equal '/x/y/z/folder'

      it 'should handle ..', ->
        fs = createFS '/x/y/z', fsData()        

        fs.resolvePath('/x/y/z/../.././').should.equal '/x'

    it 'should list files', ->
      fs = createFS '/x/y/z', fsData()

      files = fs.listFiles('/x/y/z/')
      files.should.have.members [
        '/x/y/z/a.txt',
        '/x/y/z/b.bin',
        '/x/y/z/folder'
      ]

    describe 'read file', ->
      
      it 'should read file', ->
        fs = createFS fsData()

        fs.readFile('/a.txt').should.equal 'text'      

      it 'should read file as text', ->
        fs = createFS fsData()

        fs.readFileAsString('/b.bin').should.equal 'binary'  

      it 'should read file as buffer', ->
        fs = createFS fsData()

        fs.readFileAsBuffer('/a.txt').should.be.instanceOf Buffer

    describe 'write file', ->
      
      it 'should write existing file', ->
        fs = createFS fsData()

        fs.writeFile('/a.txt', 'cool')            
        fs.readFile('/a.txt').should.equal 'cool'

      it 'should write new file', ->
        fs = createFS fsData()

        fs.writeFile('/d.txt', 'cool')            
        fs.readFile('/d.txt').should.equal 'cool'

      it 'should write create folder when necessary', ->
        fs = createFS fsData()

        fs.writeFile('/x/y/z.txt', 'cool', true)            
        fs.readFile('/x/y/z.txt').should.equal 'cool'
        expect(fs.fs.x.y).to.be.ok

    it 'should open as vinyl file', ->
      fs = createFS fsData()
      file = fs.openAsVinylFile('/a.txt')
      file.should.be.instanceOf File
      file.path.should.equal '/a.txt'
      file.isBuffer().should.be.true
      file.contents.toString('utf8').should.equal 'text'

    it 'should delete file', ->
      fs = createFS fsData()
      fs.deleteFile '/a.txt'
      expect(fs.fs['/a.txt']).to.not.exist

    it 'should check file existence', ->
      fs = createFS fsData()

      fs.exists('/a.txt').should.be.true
      fs.exists('/not_exists').should.be.false


    it 'should create sub file system', ->
      fs = createFS fsData()
      subFs = fs.subFileSystem('folder')
      subFs.writeFile('new.txt','new')
      fs.readFile('folder/new.txt').should.equal 'new'
