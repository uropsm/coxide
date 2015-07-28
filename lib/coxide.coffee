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
                'coxide:openProject': => @openProject(),
                'coxide:closeProject': => @closeProject()
    
  deactivate: ->
    @toolBar?.removeItems()
  
  serialize: ->

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'coxide-tool-bar'

    @toolBar.addButton
      icon: 'checklist',
      callback: @serialPort
      tooltip: 'Serial Port'
      
    @toolBar.addButton
      icon: 'book',
      callback: @guideLink
      tooltip: 'Guide'

  serialPort: ->
    spawn('C:\\NOL.A\\serial_monitor\\nw.exe', [ '.' ], { })

  flash: ->
    alert 'start flashing..'
    if projectPath is null
        projectPath = atom.project.getPaths()[0]
    result = spawn('C:\\NOL.A\\cox-sdk\\make\\program.cmd', ['-v'], { cwd: projectPath })
    result.stdout.on "data", (data) ->
      alert 'data : ' + data
    result.stderr.on "data", (data) ->
      alert 'err : ' + data
  
  openProject: ->
    responseChannel = "atom-open-project-response"
    ipc.on responseChannel, (path) ->
      ipc.removeAllListeners(responseChannel)
      if path isnt null 
        if fs.existsSync(path[0] + "\\.atom-build.json") == true
            atom.project.setPaths(path)
            atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:show')
            projectPath = path
        else
            alert('Failed : no available project in this path.');
    ipc.send('open-project', responseChannel)
    
  createProject: ->
    responseChannel = "atom-create-project-response"
    ipc.on responseChannel, (path) ->
      ipc.removeAllListeners(responseChannel)
      if path isnt null
        if fs.existsSync(path[0] + "\\.atom-build.json") == false
          fs.copySync("C:\\NOL.A\\sample-proj\\config", path[0])
          if fs.existsSync(path[0] + "\\main.c") == false
            fs.copySync("C:\\NOL.A\\sample-proj\\template", path[0])
          atom.project.setPaths(path)
          atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:show')
          projectPath = path
        else
          alert('Failed : Project exists already in this path.');
    ipc.send('create-project', responseChannel)
    
  closeProject : ->
    if projectPath isnt null
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:detach')
      atom.project.removePath(projectPath)
      projectPath = null
 
  guideLink : ->
    shell = require 'shell'
    shell.openExternal('http://www.coxlab.kr/index.php/docs/')