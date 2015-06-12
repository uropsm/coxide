CoxideView = require './coxide-view'
{CompositeDisposable} = require 'atom'

module.exports = Coxide =
  coxideView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->

  deactivate: ->
    @toolBar?.removeItems()
  
  serialize: ->

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'coxide-tool-bar'

    @toolBar.addButton
      icon: 'checklist',
      callback: @build
      tooltip: 'Build'

    @toolBar.addButton
      icon: 'archive',
      callback: @flash
      tooltip: 'Flash'
      iconset: 'ion'

  build: ->
    alert 'start building..'
  flash: ->
    alert 'start flashing..'