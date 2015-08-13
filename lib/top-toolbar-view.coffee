{CompositeDisposable} = require 'atom'
{View} = require 'space-pen'
DeviceSelectView = require './device-select-view'

module.exports = class TopToolbarView extends View
  devSelectView: null
  
  @content: ->
    @div class: 'coxide coxide-tool-bar', =>
      @button outlet: 'btnDevSelect', class: 'pull-right btn btn-default tool-bar-long-btn icon icon-check', 'Select Your Device'
      
  items: []

  initialize: ->
    @devSelectView = new DeviceSelectView(@btnDevSelect)
    @addClass "tool-bar-24px"
    @btnDevSelect.on "click", => @showDevSelectView()
    
  destroy: ->
  
  showDevSelectView: ->
    if atom.project.getPaths()[0] is undefined
      alert "Please open or create a project"
    else
      @devSelectView.toggle()

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
    
  loadTargetDevice: ->
    @devSelectView.loadDevice()

  clearTargetDevice: ->
    @devSelectView.clearDevice()
