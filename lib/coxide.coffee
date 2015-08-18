CreateProjectView = require './create-project-view'
TopToolbarView = require './top-toolbar-view'
ToolbarButtonView = require './toolbar-button-view'
{CompositeDisposable} = require 'atom'
ipc = require 'ipc'
fs = require 'fs-plus'
{spawn} = require 'child_process'
{View} = require 'space-pen'
{SelectListView} = require 'atom-space-pen-views'

createProjectView = null
workspacePath = null
projectPath = null
projectName = null
installPath = null
  
module.exports = Coxide =
  subscriptions: null
  modalPanel: null
  topToolbarView: null
  
  activate: (state) ->
    installPath = atom.config.get('coxide.installPath')
    
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 
                'coxide:createProject': => @createProject(), 
                'coxide:openProject': => @openProject(),
                'coxide:closeProject': => @closeProject(),
                'coxide:viewVersion': => @viewVersion(),
                'coxide:viewLicense': => @viewLicense()
                
    createProjectView = new CreateProjectView
    @modalPanel = atom.workspace.addModalPanel(item: createProjectView.element, visible: false)
  
    btnWorkspacePath = createProjectView.getElementByName('btnWorkspacePath')  
    btnWorkspacePath.on 'click', =>  @selectWorkspacePath()
    btnDoCreateProj = createProjectView.getElementByName('btnDoCreateProj')  
    btnDoCreateProj.on 'click', =>  @doCreateProj()
    btnCancel = createProjectView.getElementByName('btnCancel')  
    btnCancel.on 'click', =>  @modalPanel.hide() 

    @topToolbarView = new TopToolbarView()
    atom.workspace.addTopPanel item: @topToolbarView
    
    guideOpt = {
      tooltip: "Guide",
      icon: "book",
      callback: @guideLink
    }
    guideBtn = new ToolbarButtonView(guideOpt)
    @topToolbarView.addItem(guideBtn)
    
    serialOpt = {
      tooltip: "Serial Port",
      icon: "checklist",
      callback: @serialPort
    }
    serialBtn = new ToolbarButtonView(serialOpt)
    @topToolbarView.addItem(serialBtn)
  
  deactivate: ->
    @toolBar?.removeItems()
  
  serialize: ->

  serialPort: ->
    spawn(installPath + '\\Nol.A\\serial_monitor\\nw.exe', [ '.' ], { })

  createProject: ->  
    if @modalPanel.isVisible() is false
      @modalPanel.show()
  
  doCreateProj:  ->
    edtWorkspacePath = createProjectView.getElementByName('edtWorkspacePath') 
    workspacePath = edtWorkspacePath.getModel().getText()
    
    edtProjName = createProjectView.getElementByName('edtProjName') 
    projectName = edtProjName.getModel().getText()
    
    if projectName == ""
      alert 'Invalid Project Name.'
      return
          
    if fs.existsSync(workspacePath) == true
      if fs.existsSync(workspacePath + "\\" + projectName) == true
        alert 'Same project already exists'
        return
        
      if @closeProject() is false
        return
        
      projectPath = workspacePath + "\\" + projectName
      fs.makeTreeSync(projectPath)
      fs.copySync(installPath + "\\Nol.A\\sample-proj\\config", projectPath)
      if fs.existsSync(projectPath + "\\main.c") == false
        fs.copySync(installPath + "\\Nol.A\\sample-proj\\template", projectPath)
  
      atom.project.setPaths([projectPath])
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:show')
      @modalPanel.hide()
    else
      alert 'Invalid Workspace Path.'
      
  selectWorkspacePath: ->
    responseChannel = "atom-create-project-response"
    ipc.on responseChannel, (path) ->
      ipc.removeAllListeners(responseChannel)
      if path isnt null
        if fs.existsSync(path[0] + "\\.atom-build.json") == false
          edtWorkspacePath = createProjectView.getElementByName('edtWorkspacePath') 
          edtWorkspacePath.getModel().setText(path[0])
        else
          alert('The selected path is including a project. Please select another path for workspace.');
    ipc.send('create-project', responseChannel)
  
  openProject: ->
    responseChannel = "atom-open-project-response"
    ipc.on responseChannel, (path) ->
      ipc.removeAllListeners(responseChannel)
      if path isnt null 
        if path[0] == projectPath
          alert 'This project is already opened.' 
        else if fs.existsSync(path[0] + "\\.atom-build.json") == true
          if Coxide.closeProject() is false
            return
          atom.project.setPaths(path)
          atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:show')
          projectPath = path[0]
          Coxide._loadTargetDevice()
        else
          alert 'No exist available project in this path.'
    ipc.send('open-project', responseChannel)    
  
  _isProjectModified: ->
    textEditors = atom.workspace.getTextEditors()
    for editor in textEditors
      if editor.isModified() is true and editor.getPath() isnt null
        path = "" + editor.getPath()
        return true if path.indexOf(projectPath) == 0
    return false
 
  _clearProject: ->
    atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:detach')
    atom.project.removePath(projectPath)
    projectPath = null
    @topToolbarView.clearTargetDevice()
  
  _loadTargetDevice: ->
    @topToolbarView.loadTargetDevice()
  
  _closeFiles: (flag) ->
    panes = atom.workspace.getPanes() 
    for pane in panes 
      for item in pane.getItems()
        path = "" + item.getPath()
        if path isnt null and path.indexOf(projectPath) == 0
            if flag == 'save'
              item.save() if item.isModified() is true  
            item.destroy()

  closeProject: ->
    if projectPath isnt null    
      if @_isProjectModified() is true
        atom.confirm
          message: 'The current project has changes. Do you want to save them? Your changes will be lost if you close without saving'
          buttons:
            'Save': -> 
              Coxide._closeFiles('save')
              Coxide._clearProject() 
              return true
            'Don\'t save': -> 
              Coxide._closeFiles()
              Coxide._clearProject()
              return true
            'Cancel': ->
              return false
      else
        @_closeFiles()
        @_clearProject()
        return true

  guideLink: ->
    shell = require 'shell'
    shell.openExternal('http://www.coxlab.kr/index.php/docs/')
    
  viewVersion: ->
    alert 'Nol.A IDE version 0.13.0\nCopyright 2015 CoXlab Inc. All rights reserved.'
    
  viewLicense: ->
    atom.workspace.open(installPath + "\\Nol.A\\Atom\\resources\\LICENSE.md")
  