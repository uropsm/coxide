CreateProjectView = require './create-project-view'
SetPrivateKeyView = require './set-private-key-view'
UpdateView = require './update-view'
TopToolbarView = require './top-toolbar-view'
ToolbarButtonView = require './toolbar-button-view'
utils = require './utils'

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
privateKey = null
sep = null

module.exports = Coxide =
  subscriptions: null
  modalPanel: null
  topToolbarView: null
  privateKey: null
  
  activate: (state) ->
    serverURL = atom.config.get('coxide.serverURL')
    privateKey = atom.config.get('coxide.privateKey')

    installPath = utils.getInstallPath()
    sep = utils.getSeperator()

    prvKeyUrl = ''
    if typeof privateKey isnt 'undefined' and privateKey isnt ''
      prvKeyUrl = '/'+privateKey

    if atom.project.getPaths()[0] isnt undefined
      projectPath = atom.project.getPaths()[0]
    
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 
                'coxide:createProject': => @createProject(), 
                'coxide:openProject': => @openProject(),
                'coxide:closeProject': => @closeProject(),
                'coxide:viewVersion': => @viewVersion(),
                'coxide:viewLicense': => @viewLicense(),
                'coxide:libUpdate': => @libUpdate(),
                'coxide:setPrivateKey': => @setPrivateKey()
                
    createProjectView = new CreateProjectView
    @modalPanel = atom.workspace.addModalPanel(item: createProjectView.element, visible: false)
    
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
    request serverURL + '/lib-latest-version' + prvKeyUrl, (error, response, body) ->
      if error is null
        if body is "-1"
          atom.notifications.addInfo "Can NOT connect to Update Server."
        else if body is "-2"
          atom.notifications.addInfo "Private key is NOT valid.",
            detail : "Please reset or update on [Help] -> [Setting Private Key]"
        else
          Coxide.updateCheck(JSON.parse(body), true)

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
    spawn(utils.getSerialMonitorPath(), [ '.' ], { })

  setPrivateKey: ->
    new SetPrivateKeyView
    
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
      if fs.existsSync(workspacePath + sep + projectName) == true
        alert 'Same project already exists'
        return
        
      if @closeProject() is false
        return
        
      projectPath = workspacePath + sep + projectName
      fs.makeTreeSync(projectPath)
      fs.copySync(installPath + sep + "sample-proj" + sep + "config", projectPath)
      if fs.existsSync(projectPath + sep + "main.cpp") == false
        fs.copySync(installPath + sep + "sample-proj" + sep + "template", projectPath)
  
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
        if fs.existsSync(path[0] + sep + ".atom-build.json") == false
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
        else if fs.existsSync(path[0] + sep + ".atom-build.json") == true
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
    atom.workspace.open(utils.getLicensePath())

  libUpdate: ->
    serverURL = atom.config.get('coxide.serverURL')
    privateKey = atom.config.get('coxide.privateKey')
    prvKeyUrl = ''
    if typeof privateKey isnt 'undefined' and privateKey isnt ''
      prvKeyUrl = '/'+privateKey
    request serverURL + '/lib-latest-version' + prvKeyUrl, (error, response, body) ->
      if error is null
        if body is "-1"
          atom.notifications.addInfo "Can NOT connect to Update Server."
        else if body is "-2"
          atom.notifications.addInfo "Private key is NOT valid.",
            detail : "Please reset or update on [Help] -> [Setting Private Key]"
        else
          Coxide.updateCheck(JSON.parse(body), true)
          
  updateCheck: (libInfo, feedback) ->
    updateList = []
    libVersions = atom.config.get('coxide.libVersions')
    for i in [0...libVersions.length]
      for j in [0...libInfo.length]
        if libVersions[i].libType == libInfo[j].libType
          if libVersions[i].libVersion != libInfo[j].libVersion
            # Found new version of existing library.
            updateList.push({ libName: libVersions[i].libName, \
                              libType: libVersions[i].libType, \
                              libOldVer: libVersions[i].libVersion, \
                              libNewVer: libInfo[j].libVersion })
          break
        if j == libInfo.length-1
          # Found Deleted Library.
          updateList.push({ libName: libVersions[i].libName, \
                            libType: libVersions[i].libType, \
                            libOldVer: libVersions[i].libVersion, \
                            libNewVer: "DELETE"})
    
    for i in [0...libInfo.length]
      if libVersions.length == 0
        # Found new libraries
        updateList.push({ libName: libInfo[i].libName, \
                          libType: libInfo[i].libType, \
                          libOldVer: "NEW", \
                          libNewVer: libInfo[i].libVersion })
      else      
        for j in [0...libVersions.length]
          if libInfo[i].libType == libVersions[j].libType
            break
          if j == libVersions.length-1
            # Found new libraries
            updateList.push({ libName: libInfo[i].libName, \
                              libType: libInfo[i].libType, \
                              libOldVer: "NEW", \
                              libNewVer: libInfo[i].libVersion })

    if updateList.length > 0
      updateInfoStr = ""
      for i in [0...updateList.length]
        if updateList[i].libOldVer is "NEW"
          updateInfoStr = updateInfoStr + (i+1) + ". " + updateList[i].libName + \
            " [ New " + updateList[i].libNewVer + " ]\n"
        else if updateList[i].libNewVer is "DELETE"
          updateInfoStr = updateInfoStr + (i+1) + ". " + updateList[i].libName + \
            " [ Delete " + updateList[i].libOldVer + " ]\n"
        else
          updateInfoStr = updateInfoStr + (i+1) + ". " + updateList[i].libName + \
            " [ " + updateList[i].libOldVer + " -> " + updateList[i].libNewVer + "]\n"
      noti = atom.notifications.addInfo "New Update For Libraries!",
          dismissable: true,
          buttons: [{
            text: 'Update'
            className: 'btn-updateDo'
            onDidClick: -> 
              noti.dismiss()
              Coxide.doUpdate(updateList)
          }],
          detail : updateInfoStr
    else 
      if feedback == true
        atom.notifications.addInfo "You already have the latest version!"

  doUpdate: (updateList) ->
    updateView = new UpdateView(updateList)
    updatePanel = atom.workspace.addModalPanel(item: updateView.element, visible: true)
    updateView.setPanel(updatePanel)
    updateView.doUpdate()
