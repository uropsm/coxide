Coxide = require '../lib/coxide'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Coxide", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('coxide')

  describe "when the coxide:toggle event is triggered", ->
    it "hides and shows the modal panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.coxide')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'coxide:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.coxide')).toExist()

        coxideElement = workspaceElement.querySelector('.coxide')
        expect(coxideElement).toExist()

        coxidePanel = atom.workspace.panelForItem(coxideElement)
        expect(coxidePanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'coxide:toggle'
        expect(coxidePanel.isVisible()).toBe false

    it "hides and shows the view", ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('.coxide')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'coxide:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        coxideElement = workspaceElement.querySelector('.coxide')
        expect(coxideElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'coxide:toggle'
        expect(coxideElement).not.toBeVisible()
