{CompositeDisposable} = require 'atom'
{View} = require 'space-pen'
DeviceSelectView = require './device-select-view'

module.exports = class TopToolbarView extends View
  @content: ->
    @div class: 'coxide coxide-tool-bar', =>
      @button outlet: 'btnDevSelect', class: 'pull-right btn btn-default tool-bar-long-btn icon icon-check', 'Select Your Device'
      
  items: []

  initialize: ->
    @addClass "tool-bar-24px"
    @btnDevSelect.on "click", => @showDevSelectView()
  
  destroy: ->
  
  showDevSelectView: ->
    devSelectView = new DeviceSelectView(@btnDevSelect)
    devSelectView.toggle()
    
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
