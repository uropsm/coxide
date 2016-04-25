{CompositeDisposable} = require 'atom'
{View} = require 'space-pen'
DeviceSelectView = require './device-select-view'
PortSelectView = require './port-select-view'
ToolbarButtonView = require './toolbar-button-view'

module.exports = class TopToolbarView extends View
  devSelectView: null
  portSelectView: null
  
  @content: ->
    @div class: 'coxide coxide-tool-bar', =>
      @button outlet: 'btnDevSelect', class: 'pull-right btn btn-default tool-bar-long-btn icon icon-check', 'Select Your Device'
      @button outlet: 'btnPortSelect', class: 'pull-right btn btn-default tool-bar-long-btn icon icon-check', 'JTAG'
  items: []

  initialize: ->
    atom.workspace.addTopPanel item: @
    @devSelectView = new DeviceSelectView(@btnDevSelect)
    @addClass "tool-bar-24px"
    @btnDevSelect.on "click", => @showDevSelectView()
    
    @portSelectView = new PortSelectView(@btnPortSelect)
    @addClass "tool-bar-24px"
    @btnPortSelect.on "click", => @showPortSelectView()

    guideOpt = { tooltip: "Guide", icon: "book", callback: @guideLink }
    guideBtn = new ToolbarButtonView(guideOpt)
    @addItem(guideBtn)
    
    serialOpt = { tooltip: "Serial Port", icon: "checklist", callback: @serialPort }
    serialBtn = new ToolbarButtonView(serialOpt)
    @addItem(serialBtn)
    
  destroy: ->
  
  addItem: (newItem) ->
    nextItem = null
    for existingItem, index in @items
      nextItem = existingItem
      break
    @items.splice index, 0, newItem
    newElement = atom.views.getView newItem
    nextElement = atom.views.getView nextItem
    @.element.insertBefore newElement, nextElement
    nextItem

  serialPort: ->
    alert "Not available now."

  guideLink: ->
    shell = require 'shell'
    shell.openExternal('http://www.coxlab.kr/index.php/docs/')
    
  loadTargetDevice: ->
    @devSelectView.loadDevice()

  clearTargetDevice: ->
    @devSelectView.clearDevice()

  showDevSelectView: ->
    if atom.project.getPaths()[0] is undefined
      alert "Please open or create a project"
    else
      @devSelectView.toggle()

  showPortSelectView: ->
    if atom.project.getPaths()[0] is undefined
      alert "Please open or create a project"
    else
      @portSelectView.toggle()