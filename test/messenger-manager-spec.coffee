uuid = require 'uuid'
redis = require 'ioredis'
MessengerManager = require '..'

describe 'MessengerManager', ->
  beforeEach (done) ->
    @client = redis.createClient()
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)
    @client.on 'ready', done

  beforeEach 'messenger client setup', (done) ->
    messengerClient = redis.createClient()
    @sut = new MessengerManager {@uuidAliasResolver,client:messengerClient}
    @sut.connect done

  context 'message', ->
    describe 'subscribe', ->
      beforeEach (done) ->
        @nonce = Date.now()
        @sut.once 'message', (@channel, @message) => done()
        @sut.subscribe type: 'sent', uuid: 'some-uuid', =>
          @client.publish 'sent:some-uuid', @nonce, (error) =>
            return done error if error?

      it 'should receive a message', ->
        expect(@message).to.equal @nonce

    describe 'unsubscribe', ->
      beforeEach (done) ->
        @nonce = Date.now()
        @sut.once 'message', (@channel, @message) => done()
        @sut.subscribe type: 'sent', uuid: 'some-uuid', =>
          @client.publish 'sent:some-uuid', @nonce, (error) =>
            return done error if error?

      it 'should receive the first message', ->
        expect(@message).to.equal @nonce

      context 'when unsubscribed', ->
        beforeEach (done) ->
          @sut.once 'message', (@channel, @secondMessage) =>
          @sut.unsubscribe type: 'sent', uuid: 'some-uuid', =>
            @client.publish 'sent:some-uuid', @nonce, (error) =>
              return done error if error?
              setTimeout done, 200

        it 'should not receive another message', ->
          expect(@secondMessage).not.to.exist

  context 'config', ->
    describe 'subscribe', ->
      beforeEach (done) ->
        @nonce = Date.now()
        @sut.once 'config', (@channel, @message) => done()
        @sut.subscribe type: 'config', uuid: 'some-uuid', =>
          @client.publish 'config:some-uuid', @nonce, (error) =>
            return done error if error?

      it 'should receive a message', ->
        expect(@message).to.equal @nonce

  context 'data', ->
    describe 'subscribe', ->
      beforeEach (done) ->
        @nonce = Date.now()
        @sut.once 'data', (@channel, @message) => done()
        @sut.subscribe type: 'data', uuid: 'some-uuid', =>
          @client.publish 'data:some-uuid', @nonce, (error) =>
            return done error if error?

      it 'should receive a message', ->
        expect(@message).to.equal @nonce

  describe 'topic filtering onMessage', ->
    describe 'exact match', ->
      beforeEach (done) ->
        @nonce = Date.now()
        message =
          topic: 'pears'
          nonce: @nonce

        @sut.once 'message', (@channel, @message) => done()
        @sut.subscribe type: 'sent', uuid: 'some-uuid', topics: ['pears'], =>
          @client.publish 'sent:some-uuid', JSON.stringify(message), (error) =>
            return done error if error?

      it 'should receive a message', ->
        expect(@message.nonce).to.equal @nonce

    describe 'no match', ->
      beforeEach (done) ->
        @nonce = Date.now()
        message =
          topic: 'rears'
          nonce: @nonce

        @sut.once 'message', (@channel, @message) =>
        @sut.subscribe type: 'sent', uuid: 'some-uuid', topics: ['pears'], =>
          @client.publish 'sent:some-uuid', JSON.stringify(message), (error) =>
            return done error if error?
            setTimeout done, 200

      it 'should not receive a message', ->
        expect(@message).not.to.exist

    describe 'minus match', ->
      beforeEach (done) ->
        @nonce = Date.now()
        message =
          topic: 'pears'
          nonce: @nonce

        @sut.once 'message', (@channel, @message) =>
        @sut.subscribe type: 'sent', uuid: 'some-uuid', topics: ['-pears'], =>
          @client.publish 'sent:some-uuid', JSON.stringify(message), (error) =>
            return done error if error?
            setTimeout done, 200

      it 'should not receive a message', ->
        expect(@message).not.to.exist

    describe 'partial match', ->
      beforeEach (done) ->
        @nonce = Date.now()
        message =
          topic: 'sears'
          nonce: @nonce

        @sut.once 'message', (@channel, @message) => done()
        @sut.subscribe type: 'sent', uuid: 'some-uuid', topics: ['*ears'], =>
          @client.publish 'sent:some-uuid', JSON.stringify(message), (error) =>
            return done error if error?

      it 'should receive a message', ->
        expect(@message.nonce).to.equal @nonce
