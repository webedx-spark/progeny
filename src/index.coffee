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
      exclusion: /(?:nib|url)/
      supportsGlob: true
      extensionsList: ['css']
      handleDirectory: (fullPath) ->
        sysPath.join fullPath, 'index.styl'
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
    paths = data
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

    dirs = []
    dirs.push parent if parent
    dirs.push rootPath if rootPath and rootPath isnt parent

    deps = []
    dirs.forEach (dir) ->
      paths.forEach (path) ->
        deps.push sysPath.join dir, path

    if supportsGlob
      globs = []
      deps.forEach (path) ->
        results = glob.sync path
        if results.length
          globs = globs.concat results
        else
          globs.push path
      deps = globs

    if extension
      extFiles = []
      deps.forEach (path) ->
        if ".#{extension}" isnt sysPath.extname path
          extFiles.push "#{path}.#{extension}"
      deps = deps.concat extFiles

    if handleDirectory?
      directoryFiles = []
      deps.forEach (path) ->
        directoryPath = handleDirectory path
        directoryFiles.push directoryPath
      deps = deps.concat directoryFiles

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

