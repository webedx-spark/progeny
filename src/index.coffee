'use strict'

sysPath = require 'path'
fs = require 'fs'
each = require 'async-each'
glob = require 'glob'

defaultSettings = (extname) ->
  switch extname
    when 'jade'
      regexp: /^\s*(?:include|extends)\s+(.+)/
    when 'styl'
      regexp: /^\s*@(?:import|require)\s+['"]?([^'"]+)['"]?/
      exclusion: 'nib'
      supportsGlob: true
      handleDirectory: (fullPath) ->
        indexPath = sysPath.join fullPath, 'index.styl'
        if fs.existsSync indexPath then indexPath else fullPath
    when 'less'
      regexp: /^\s*@import\s+['"]([^'"]+)['"]/
    when 'scss', 'sass'
      regexp: /^\s*@import\s+['"]?([^'"]+)['"]?/
      prefix: '_'
      exclusion: /^compass/
      extensionsList: ['scss', 'sass']

module.exports =
({rootPath, extension, regexp, prefix, exclusion, extensionsList, supportsGlob, handleDirectory, shallow}={}) ->
  parseDeps = (data, path, depsList, callback) ->
    parent = sysPath.dirname path if path
    deps = data
      .toString()
      .split('\n')
      .map (line) ->
        line.match regexp
      .filter (match) ->
        match?.length > 0
      .map (match) ->
        match[1]
      .filter (path) ->
        exclusion = [exclusion] if '[object Array]' isnt toString.call exclusion
        !!path and not exclusion.some (_exclusion) -> switch
          when _exclusion instanceof RegExp
            _exclusion.test path
          when '[object String]' is toString.call _exclusion
            _exclusion is path
          else false
      .map (path) ->
        if extension and '' is sysPath.extname path
          "#{path}.#{extension}"
        else
          path
      .map (path) ->
        if path[0] is '/' or not parent
          sysPath.join rootPath, path[1..]
        else
          sysPath.join parent, path
      .map (path) ->
        if extension and not fs.existsSync path
          extensionRegex = ///.#{extension}$///
          basePath = path.replace extensionRegex, ''
          if fs.existsSync basePath
            return basePath
        path

    if supportsGlob
      globs = []
      deps.forEach (path) ->
        results = glob.sync path
        if results
          globs = globs.concat results
        else
          globs.push path
      deps = globs

    if handleDirectory?
      directoryFiles = []
      deps.forEach (path) ->
        stats = fs.lstatSync(path)
        if stats?.isDirectory()
          directoryFiles = directoryFiles.concat handleDirectory path
        else
          directoryFiles.push path
      deps = directoryFiles

    if extension
      deps.forEach (path) ->
        if ".#{extension}" isnt sysPath.extname path
          deps.push "#{path}.#{extension}"

    if prefix?
      prefixed = []
      deps.forEach (path) ->
        dir = sysPath.dirname path
        file = sysPath.basename path
        if 0 isnt file.indexOf prefix
          prefixed.push sysPath.join dir, "#{prefix}#{file}"
      deps = deps.concat prefixed

    if extensionsList.length
      altExts = []
      deps.forEach (path) ->
        dir = sysPath.dirname path
        extensionsList.forEach (ext) ->
          if ".#{ext}" isnt sysPath.extname path
            base = sysPath.basename path, ".#{extension}"
            altExts.push sysPath.join dir, "#{base}.#{ext}"
      deps = deps.concat altExts

    if deps.length
      each deps, (path, callback) ->
        if path in depsList
          callback()
        else
          depsList.push path
          if shallow
            do callback
          else
            fs.readFile path, encoding: 'utf8', (err, data) ->
              return callback() if err
              parseDeps data, path, depsList, callback
      , callback
    else
      callback()

  (data, path, callback) ->
    depsList = []

    extension ?= sysPath.extname(path)[1..]
    def = defaultSettings extension
    regexp ?= def.regexp
    prefix ?= def.prefix
    exclusion ?= def.exclusion
    extensionsList ?= def.extensionsList or []
    supportsGlob ?= def.supportsGlob or false
    shallow ?= def.shallow or false
    handleDirectory ?= def.handleDirectory

    run = ->
      parseDeps data, path, depsList, ->
        callback null, depsList
    if data?
      do run
    else
      fs.readFile path, encoding: 'utf8', (err, fileContents) ->
        return callback err if err
        data = fileContents
        do run

