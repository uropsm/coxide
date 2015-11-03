CreateProjectView = require './create-project-view'
UpdateView = require './update-view'
TopToolbarView = require './top-toolbar-view'
ToolbarButtonView = require './toolbar-button-view'
{CompositeDisposable} = require 'atom'
ipc = require 'ipc'
fs = require 'fs-plus'
{spawn} = require 'child_process'
{View} = require 'space-pen'
{SelectListView} = require 'atom-space-pen-views'
request = require 'request'

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
    serverURL = atom.config.get('coxide.serverURL')
    
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 
                'coxide:createProject': => @createProject(), 
                'coxide:openProject': => @openProject(),
                'coxide:closeProject': => @closeProject(),
                'coxide:viewVersion': => @viewVersion(),
                'coxide:viewLicense': => @viewLicense(),
                'coxide:libUpdate': => @libUpdate()
                
    createProjectView = new CreateProjectView
    @modalPanel = atom.workspace.addModalPanel(item: createProjectView.element, visible: false)
  
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
    request serverURL + '/lib-latest-version', (error, response, body) ->
      if error is null
        if body isnt "0"
          Coxide.updateCheck(JSON.parse(body), false)

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
    for versionInfo in atom.packages.getAvailablePackageMetadata()
      if versionInfo.name == "coxide"
        alert "Nol.A IDE version " + versionInfo.version + "\nCopyright 2015 CoXlab Inc. All rights reserved."

  viewLicense: ->
    atom.workspace.open(installPath + "\\Nol.A\\Atom\\resources\\LICENSE.md")

  libUpdate: ->
    serverURL = atom.config.get('coxide.serverURL')
    request serverURL + '/lib-latest-version', (error, response, body) ->
      if error is null
        if body isnt "0"
          Coxide.updateCheck(JSON.parse(body), true)

  updateCheck: (libInfo, feedback) ->
    updateList = []
    libVersions = atom.config.get('coxide.libVersions')
    for i in [0...libVersions.length]
      for j in [0...libInfo.length]
        if libVersions[i].libType == libInfo[j].libType
          if libVersions[i].libVersion != libInfo[j].libVersion
            updateList.push({ libName: libVersions[i].libName, \
                              libType: libVersions[i].libType, \
                              libOldVer: libVersions[i].libVersion, \
                              libNewVer: libInfo[j].libVersion })
            break
    
    if libInfo.length > libVersions.length
      # find new library type.
      for i in [0...libInfo.length]
        for j in [0...libVersions.length]
          if libInfo[i].libType == libVersions[j].libType
            break
          if j == libVersions.length-1
            updateList.push({ libName: libInfo[i].libName, \
                              libType: libInfo[i].libType, \
                              libOldVer: "NEW", \
                              libNewVer: libInfo[i].libVersion })

    if updateList.length > 0
      noti = atom.notifications.addInfo "New Update For Libraries!",
          dismissable: true,
          buttons: [{
            text: 'Update'
            className: 'btn-updateDo'
            onDidClick: -> 
              noti.dismiss()
              Coxide.doUpdate(updateList)
          }]
    else 
      if feedback == true
        atom.notifications.addInfo "You already have the latest version!"

  doUpdate: (updateList) ->
    updateView = new UpdateView(updateList)
    updatePanel = atom.workspace.addModalPanel(item: updateView.element, visible: true)
    updateView.setPanel(updatePanel)