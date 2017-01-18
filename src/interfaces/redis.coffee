redis = require 'redis'

{ EventEmitter } = require 'events'

class RedisInterface extends EventEmitter
  constructor: (@options = {}) ->
    super()

    @up = 0

    @redisConnect 'subClient', @onReady.bind this
    @redisConnect 'pubClient', @onReady.bind this

    @subClient.on "pmessage", (pattern, channel, msg) =>
      @emit 'message', msg

  onReady: ->
    @up++

    if @up is 2
      @connected = true
      @emit 'ready'

  redisConnect: (clientName, cb) =>
    @[clientName] = redis.createClient @options

    @[clientName].on "error", (err) -> console.warn "#{ err }"
    @[clientName].on "ready", cb

  subscribe: (channel) ->
    @subClient.psubscribe channel

  publish: (channel, message) =>
    @pubClient.publish channel, message

module.exports = RedisInterface