redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'
MessengerManager = require '..'

class MessengerManagerFactory
  constructor: ({@uuidAliasResolver, @namespace, @redisUri}) ->

  build: =>
    client = new RedisNS @namespace, redis.createClient(@redisUri, dropBufferSupport: true)
    new MessengerManager {client, @uuidAliasResolver}

module.exports = MessengerManagerFactory
