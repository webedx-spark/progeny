require 'coffee-script/register'
chai = require 'chai'
progenyFunc = require '../src/index'

describe 'Stylus', ->
  beforeEach ->
    @rootPath = 'test/fixtures/stylus'
    @progeny = progenyFunc
      rootPath: @rootPath

  it 'should find dependencies', (done) ->
    fixtureFile = 'test/fixtures/stylus/stylus.styl'
    @progeny null, fixtureFile, (err, dependencies) =>
      chai.expect dependencies
        .to.include.members [
          "#{@rootPath}/test.styl"
          "#{@rootPath}/test.css"
        ]
      do done

  it 'should expand dependencies', (done) ->
    fixtureFile = 'test/fixtures/stylus/stylus.expands.styl'
    @progeny null, fixtureFile, (err, dependencies) =>
      chai.expect dependencies
        .to.include.members [
          "#{@rootPath}/testDir/index.styl"
          "#{@rootPath}/testDir/test.styl"
          "#{@rootPath}/testDir/deep.styl"
        ]
      do done

  it 'should prioritize dependencies', (done) ->
    fixtureFile = 'test/fixtures/stylus/stylus.priority.styl'
    firstPriority = "#{@rootPath}/testDir.styl"
    secondPriority = "#{@rootPath}/testDir/index.styl"

    @progeny null, fixtureFile, (err, dependencies) =>
      firstIndex = dependencies.indexOf firstPriority
      secondIndex = dependencies.indexOf secondPriority

      chai.expect dependencies
        .to.include.members [
          firstPriority
          secondPriority
        ]

      chai.expect(firstIndex).to.be.below secondIndex
      do done

  it 'should respect the shallow option', (done) ->
    progeny = progenyFunc
      rootPath: @rootPath
      shallow: true
    fixtureFile = 'test/fixtures/stylus/stylus.shallow.styl'
    progeny null, fixtureFile, (err, dependencies) ->
      chai.expect dependencies
        .to.not.include "#{@rootPath}/testDir/deep.styl"
      do done

  it 'should find project-relative paths', (done) ->
    progeny = progenyFunc
      rootPath: @rootPath
    fixtureFile = 'test/fixtures/stylus/nested/stylus.styl'
    progeny null, fixtureFile, (err, dependencies) =>
      chai.expect dependencies
        .to.include.members [
          "#{@rootPath}/testDir.styl"
        ]
      do done


