redis = require 'redis'
debug = require('debug')('loopback:cache:redis')

AbstractStore = require './abstract'

class RedisStore extends AbstractStore
  constructor: (options = {}) ->
    super options

    @client = redis.createClient options.port or 6379, options.host or '127.0.0.1', detect_buffers: true

    return

  get: (key, fn) ->
    @client.get @key(key), (err, data) ->
      debug 'get', key, data

      fn err, data

  set: (key, val, ttl = 30, fn) ->
    if typeof ttl is 'function'
      return @set key, val, null, ttl

    if val is undefined
      return fn()

    debug 'set', key, val, ttl

    key = @key key

    if ttl is -1
      @client.set key, val, fn
    else
      @client.setex key, ttl, val, fn

    return

  del: (key, fn) ->
    debug 'delete', key

    @client.keys @key(key), (err, keys) =>
      if err or not keys.length
        return fn err, null

      multi = @client.multi()

      keys.forEach (key) ->
        multi.del key

      multi.exec fn

    return

  clear: (fn) ->
    debug 'clear'

    @del '*', fn

    return

module.exports = RedisStore