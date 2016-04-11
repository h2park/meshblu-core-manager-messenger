_ = require 'lodash'
{EventEmitter2} = require 'eventemitter2'

class MessengerManager extends EventEmitter2
  constructor: ({@client,@uuidAliasResolver}) ->
    @topicMap = {}
    @client.on 'message', @_onMessage

  connect: (callback) =>
    @client.once 'ready', =>
      callback()
      callback = ->

    @client.once 'error', (error) =>
      callback error
      callback = ->

  close: =>
    if @client.disconnect?
      @client.quit()
      @client.disconnect false
      return
    @client.end true

  subscribe: ({type, uuid, topics}, callback) =>
    @uuidAliasResolver.resolve uuid, (error, uuid) =>
      return callback error if error?
      @_addTopics uuid, topics
      channel = @_channel type, uuid
      @client.subscribe channel, callback

  unsubscribe: ({type, uuid, topics}, callback) =>
    @uuidAliasResolver.resolve uuid, (error, uuid) =>
      return callback error if error?
      delete @topicMap[uuid]
      channel = @_channel type, uuid
      @client.unsubscribe channel, callback

  _addTopics: (uuid, topics=['*']) =>
    topics = [topics] unless _.isArray topics
    [skips, names] = _.partition topics, (topic) => _.startsWith topic, '-'
    names = ['*'] if _.isEmpty names
    map = {}

    map.names = _.map names, (topic) =>
      topic = topic.replace(/\*/g, '.*?')
      new RegExp "^#{topic}$"

    map.skips = _.map skips, (topic) =>
      topic = topic.replace(/\*/g, '.*?').replace(/^-/, '')
      new RegExp "^#{topic}$"

    @topicMap[uuid] = map

  _channel: (type, uuid) =>
    "#{type}:#{uuid}"

  _defaultTopics: =>

  _onMessage: (channel, messageStr) =>
    try
      message = JSON.parse messageStr
    catch
      return

    if /^config:/.test channel
      @emit 'config', channel, message
      return

    if /^data:/.test channel
      @emit 'data', channel, message
      return

    uuid = _.last channel.split /:/

    if @_topicMatch uuid, message?.topic
      @emit 'message', channel, message

  _topicMatch: (uuid, topic) =>
    @_addTopics uuid unless @topicMap[uuid]?

    return false if _.some @topicMap[uuid].skips, (re) => re.test topic
    _.some @topicMap[uuid].names, (re) => re.test topic

module.exports = MessengerManager
