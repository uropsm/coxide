CoxideView = require './coxide-view'
{CompositeDisposable} = require 'atom'

module.exports = Coxide =
  coxideView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @coxideView = new CoxideView(state.coxideViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @coxideView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'coxide:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @coxideView.destroy()

  serialize: ->
    coxideViewState: @coxideView.serialize()

  toggle: ->
    console.log 'Coxide was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
