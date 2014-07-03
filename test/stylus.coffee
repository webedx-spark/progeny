require 'coffee-script/register'
chai = require 'chai'
progenyFunc = require '../src/index'

describe 'Stylus', ->
  beforeEach ->
    @rootPath = 'test/fixtures/stylus'
    @progeny = progenyFunc
      rootPath: @rootPath

  it 'should find dependencies correctly', (done) ->
    fixtureFile = 'test/fixtures/stylus/stylus.styl'
    @progeny null, fixtureFile, (err, dependencies) =>
      chai.expect dependencies
        .to.eql [
          "#{@rootPath}/test.styl"
          "#{@rootPath}/test.css"
        ]
      do done

  it 'should expand dependencies correctly', (done) ->
    fixtureFile = 'test/fixtures/stylus/stylus.expands.styl'
    @progeny null, fixtureFile, (err, dependencies) =>
      chai.expect dependencies
        .to.contain \
          "#{@rootPath}/testDir/index.styl", 
          "#{@rootPath}/testDir/test.styl", 
          "#{@rootPath}/testDir/deep.styl"
      do done

  it 'should respect the shallow option', (done) ->
    progeny = progenyFunc
      rootPath: @rootPath
      shallow: true
    fixtureFile = 'test/fixtures/stylus/stylus.shallow.styl'
    progeny null, fixtureFile, (err, dependencies) =>
      chai.expect dependencies
        .to.eql [
          "#{@rootPath}/testDir/index.styl",
        ]
      do done


