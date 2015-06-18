CoxideView = require './coxide-view'
{CompositeDisposable} = require 'atom'
ipc = require 'ipc'
fs = require 'fs-plus'

serialPane = null

module.exports = Coxide =
  subscriptions: null
  
  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'coxide:createProject': => @createProject()
	
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
      icon: 'archive',
      callback: @flash
      tooltip: 'Flash'
      iconset: 'ion'

  serialPort: ->
    if serialPane is null
      panes = atom.workspace.getPanes()
      serialPane = panes.pop()
      serialPane = serialPane.splitRight()
      serialPane.activate()
    else
      serialPane.destroy()
      serialPane = null
            
  flash: ->
    alert 'start flashing..'
    
  createProject: ->
    responseChannel = "atom-pick-folder-response"
    ipc.on responseChannel, (path) ->
      ipc.removeAllListeners(responseChannel)
      fs.copySync("C:\\coxide\\BuildConfig", path[0])
      fs.copySync("C:\\coxide\\Template", path[0])
      atom.project.setPaths(path)
    ipc.send('pick-folder', responseChannel)
