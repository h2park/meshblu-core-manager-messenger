uuid                  = require 'uuid'
MessengerManager        = require '..'
MessengerManagerFactory = require '../factory'

describe 'MessengerManagerFactory', ->
  beforeEach ->
    @redisKey = uuid.v1()
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)

    @sut = new MessengerManagerFactory {
      @uuidAliasResolver
      namespace: 'something'
      redisUri: 'redis://localhost'
    }

  describe 'build', ->
    beforeEach ->
      @hydrantManager = @sut.build()

    it 'should create a MessengerManager', ->
      expect(@hydrantManager).to.be.an.instanceOf MessengerManager
