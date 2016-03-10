{EventEmitter2} = require 'eventemitter2'

class MessengerManager extends EventEmitter2
  constructor: ({@client,@uuidAliasResolver}) ->
    @client.on 'message', @_onMessage

  close: =>
    @client.end true

  subscribe: (type, uuid, callback) =>
    @uuidAliasResolver.resolve uuid =>
      channel = @_channel type, uuid
      @client.subscribe channel, callback

  unsubscribe: (type, uuid, callback) =>
    channel = @_channel type, uuid
    @client.unsubscribe channel, callback

  _channel: (type, uuid) =>
    "#{type}:#{uuid}"

  _onMessage: (channel, messageStr) =>
    try
      message = JSON.parse messageStr
    catch
      return

    @emit 'message', channel, message

module.exports = MessengerManager
