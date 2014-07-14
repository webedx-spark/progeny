chai = require 'chai'
progeny = require '..'
path = require 'path'
assert = require 'assert'

getFixturePath = (subPath) ->
  path.join __dirname, 'fixtures', subPath

describe 'progeny', ->
  it 'should preserve original file extensions', (done) ->
    progeny() null, getFixturePath('altExtensions.jade'), (err, dependencies) ->
      paths = (getFixturePath x for x in ['htmlPartial.html', 'htmlPartial.html.jade'])
      assert.deepEqual dependencies, paths
      do done

describe 'progeny configuration', ->
  describe 'excluded file list', ->
    progenyConfig =
      rootPath: path.join __dirname, 'fixtures'
      exclusion: [
        /excludedDependencyOne/
        /excludedDependencyTwo/
      ]
      extension: 'jade'

    checkContents = (dependencies, includes, excludes) ->
      chai.expect dependencies
        .to.include.members includes
        .and.not.include.members excludes

    it 'should accept one regex', (done) ->
      progenyConfig.exclusion = /excludedDependencyOne/
      getDependencies = progeny progenyConfig

      getDependencies null, getFixturePath('excludedDependencies.jade'), (err, dependencies) ->
        paths = (getFixturePath x for x in ['excludedDependencyTwo.jade', 'includedDependencyOne.jade'])
        checkContents dependencies, paths, [getFixturePath 'excludedDependencyOne.jade']
        do done

    it 'should accept one string', (done) ->
      progenyConfig.exclusion = 'excludedDependencyOne'
      getDependencies = progeny progenyConfig

      getDependencies null, getFixturePath('excludedDependencies.jade'), (err, dependencies) ->
        paths =  (getFixturePath x for x in ['excludedDependencyTwo.jade', 'includedDependencyOne.jade'])
        checkContents dependencies, paths, [getFixturePath 'excludedDependencyOne.jade']
        do done

    it 'should accept a list of regexes', (done) ->
      progenyConfig.exclusion = [
        /excludedDependencyOne/
        /excludedDependencyTwo/
      ]
      getDependencies = progeny progenyConfig

      getDependencies null, getFixturePath('excludedDependencies.jade'), (err, dependencies) ->
        paths =  (getFixturePath x for x in ['excludedDependencyOne.jade', 'excludedDependencyTwo.jade'])
        checkContents dependencies, [getFixturePath 'includedDependencyOne.jade'], paths
        do done

    it 'should accept a list of strings', (done) ->
      progenyConfig.exclusion = [
        'excludedDependencyOne'
        'excludedDependencyTwo'
      ]
      getDependencies = progeny progenyConfig

      getDependencies null, getFixturePath('excludedDependencies.jade'), (err, dependencies) ->
        paths =  (getFixturePath x for x in ['excludedDependencyOne.jade', 'excludedDependencyTwo.jade'])
        checkContents dependencies, [getFixturePath 'includedDependencyOne.jade'], paths
        do done

    it 'should accept a list of both strings and regexps', (done) ->
      progenyConfig.exclusion = [
        'excludedDependencyOne'
        /excludedDependencyTwo/
      ]
      getDependencies = progeny progenyConfig

      getDependencies null, getFixturePath('excludedDependencies.jade'), (err, dependencies) ->
        paths =  (getFixturePath x for x in ['excludedDependencyOne.jade', 'excludedDependencyTwo.jade'])
        checkContents dependencies, [getFixturePath 'includedDependencyOne.jade'], paths
        do done
