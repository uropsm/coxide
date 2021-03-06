utils = require './utils'
remote = require 'remote'
app = remote.require('app')
os = require 'os'
fs = require 'fs-plus'
{XRegExp} = require 'xregexp'

exports.getInstallPath = ->
  sep = ""
  uselessPath = ""
  appPath = app.getAppPath()

  platform = os.platform()
  if platform == "linux"
    sep = "/"
    uselessPath = sep + "share" + sep + "atom" + sep + "resources" + sep + "app.asar"
  else if platform == "darwin"
    sep = "/"
    uselessPath = sep + "Contents" + sep +  "Resources" + sep + "app.asar"
  else if platform == "win32" || platform == "win64"
    sep = "\\"
    uselessPath = sep + "Atom" + sep + "resources" + sep + "app.asar"
  
  installPath = appPath.replace(uselessPath, "")
  return installPath

exports.getSeperator = ->
  platform = os.platform()
  if platform is "linux" or platform is "darwin"
    return "/"
  else if platform is "win32" or platform is "win64"
    return "\\"

exports.getCleanScriptPath = ->
  installPath = utils.getInstallPath()
  sep = utils.getSeperator()
  platform = os.platform()
  cleanScriptPath = ""
  if platform is "linux" or platform is "darwin"
    cleanScriptPath = sep + "cox-sdk" + sep + "make" + sep + "clean.cmd"
  else if platform is "win32" or platform is "win64"
    cleanScriptPath = sep + "cox-sdk" + sep + "make" + sep + "clean.sh"

  return installPath + cleanScriptPath

exports.getLicensePath = ->
  installPath = utils.getInstallPath()
  sep = utils.getSeperator()
  licensePath = ""

  platform = os.platform()
  if platform == "linux"
    licensePath = sep + "share" + sep + "atom" + sep + "resources" + sep + "LICENSE.md"
  else if platform == "darwin"
    licensePath = sep + "Contents" + sep + "Resources" + sep + "LICENSE.md"
  else if platform == "win32" || platform == "win64"
    licensePath = sep + "Atom" + sep + "resources" + sep + "LICENSE.md"
  
  return installPath + licensePath

exports.getSerialMonitorPath = ->
  installPath = utils.getInstallPath()
  sep = utils.getSeperator()
  serialMonitorPath = ""

  platform = os.platform()
  if platform == "linux" || platform == "darwin"
    serialMonitorPath = sep + "serial_monitor" + sep + "nw"
  else if platform == "win32" || platform == "win64"
    serialMonitorPath = sep + "serial_monitor" + sep + "nw.exe"
  
  return installPath + serialMonitorPath

exports.getPlatform = ->
  platform = os.platform()
  if platform == "win32" || platform == "win64"
    platform = "window"
  return platform

exports.getPortList = ->
  portList = ['None', 'JTAG']
  platform = os.platform()
  if platform == "win32" || platform == "win64"
    for i in [1...30]
      portList.push("COM"+i)
  else if platform == "linux"
    dirInfo = fs.listSync('/dev', '')
    dirXReg = XRegExp('tty.*' , 'gi')
    for i in [0...dirInfo.length]
      if XRegExp.exec(dirInfo[i], dirXReg) isnt null
       portList.push(dirInfo[i])
  else if platform == "darwin"
    dirInfo = fs.listSync('/dev', '')
    dirXReg = XRegExp('tty\\..*' , 'gi')
    for i in [0...dirInfo.length]
      if XRegExp.exec(dirInfo[i], dirXReg) isnt null
       portList.push(dirInfo[i])
  return portList
