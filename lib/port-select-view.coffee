{SelectListView} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
fs = require 'fs-plus'
utils = require './utils'

defaultPort = 'None'

module.exports =
class PortSelectView extends SelectListView  
  btnPortSelect: null
  sep: null
  portList: []
  curPort: null
  
  initialize: (btnPortSel) ->
    super
    @btnPortSelect = btnPortSel
    @addClass('grammar-selector')
    @list.addClass('mark-active')
    @sep = utils.getSeperator()
    
    @initPortList()
    @btnPortSelect.text defaultPort
    @curPort = defaultPort
    if atom.project.getPaths()[0] isnt undefined
      @savePort(defaultPort)

  destroy: ->
    @cancel()

  viewForItem: (port) ->
    element = document.createElement('li')
    element.classList.add('active') if port is @curPort
    element.textContent = port
    element
  
  cancelled: ->
    @panel?.destroy()
    @panel = null
    @editor = null

  confirmed: (port) ->
    @curPort = port
    @btnPortSelect.text port
    @savePort(port);
    @cancel()
  
  attach: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @focusFilterEditor()

  toggle: ->
    if @panel?
      @cancel()
    else
      @setItems(@portList)
      @attach()

  initPortList: ->
    @portList = utils.getPortList()
    
  savePort : (port) ->
    currentProjPath = atom.project.getPaths()[0]
    jsonFilePath = currentProjPath + @sep + '.atom-build.json'
    try 
      jsonData = JSON.parse(fs.readFileSync(jsonFilePath).toString())
      jsonData.port = port
      fs.writeFileSync(jsonFilePath, JSON.stringify(jsonData, null, ' '))
    catch e
      alert 'Error : .atom-build.json modification failure.'

    
      