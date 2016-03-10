uuid = require 'uuid'
redis = require 'fakeredis'
MessengerManager = require '..'

describe 'MessengerManager', ->
  beforeEach ->
    @redisKey = uuid.v1()
    @client = redis.createClient @redisKey
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)

    messengerClient = redis.createClient @redisKey
    @sut = new MessengerManager {@uuidAliasResolver,client:messengerClient}

  describe 'subscribe', ->
    beforeEach (done) ->
      @nonce = Date.now()
      @sut.once 'message', (@channel, @message) => done()
      @sut.subscribe 'sent', 'some-uuid', =>
        @client.publish 'sent:some-uuid', @nonce, (error) =>
          return done error if error?

    it 'should receive a message', ->
      expect(@message).to.equal @nonce

  describe 'unsubscribe', ->
    beforeEach (done) ->
      @nonce = Date.now()
      @sut.once 'message', (@channel, @message) => done()
      @sut.subscribe 'sent', 'some-uuid', =>
        @client.publish 'sent:some-uuid', @nonce, (error) =>
            return done error if error?

    it 'should receive the first message', ->
      expect(@message).to.equal @nonce

    context 'when unsubscribed', ->
      beforeEach (done) ->
        @sut.once 'message', (@channel, @secondMessage) => done()
        @sut.unsubscribe 'sent', 'some-uuid', =>
          @client.publish 'sent:some-uuid', @nonce, (error) =>
            return done error if error?
            setTimeout done, 200

      it 'should not receive another message', ->
        expect(@secondMessage).not.to.exist
