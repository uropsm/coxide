CoxideView = require './coxide-view'
{CompositeDisposable} = require 'atom'
ipc = require 'ipc'
fs = require 'fs-plus'
{spawn} = require 'child_process'

serialPane = null
projectPath = null

module.exports = Coxide =
  subscriptions: null
  
  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 
                'coxide:createProject': => @createProject(), 
                'coxide:openProject': => @openProject()
    
  deactivate: ->
    @toolBar?.removeItems()
  
  serialize: ->

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'coxide-tool-bar'

    @toolBar.addButton
      icon: 'checklist',
      callback: @serialPort
      tooltip: 'Serial Port'

  serialPort: ->
    spawn('C:\\coxide\\serial_monitor\\nw.exe', [ '.' ], { })

  flash: ->
    alert 'start flashing..'
    if projectPath is null
        projectPath = atom.project.getPaths()[0]
    result = spawn('C:\\coxide\\cox-sdk\\make\\program.cmd', ['-v'], { cwd: projectPath })
    result.stdout.on "data", (data) ->
      alert 'data : ' + data
    result.stderr.on "data", (data) ->
      alert 'err : ' + data
  
  openProject: ->
    responseChannel = "atom-open-project-response"
    ipc.on responseChannel, (path) ->
      ipc.removeAllListeners(responseChannel)
      if path isnt null 
        atom.project.setPaths(path)
        projectPath = path
    ipc.send('open-project', responseChannel)
    
  createProject: ->
    responseChannel = "atom-create-project-response"
    ipc.on responseChannel, (path) ->
      ipc.removeAllListeners(responseChannel)
      if path isnt null
        if fs.existsSync(path[0] + "\\.atom-build.json") == false
          fs.copySync("C:\\coxide\\sample-proj", path[0])
          atom.project.setPaths(path)
          projectPath = path
        else
          alert('Project exists already in this path.');
    ipc.send('create-project', responseChannel)