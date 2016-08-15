'use strict'

lruCache = require 'lru-cache'
debug = require('debug')('loopback:cache:memory')

AbstractStore = require './abstract'

class MemoryStore extends AbstractStore
  constructor: (options = {}) ->
    super options

    @client = lruCache options.count or 100

  get: (key, fn) ->
    data = @client.get @key(key)

    debug 'get', key, data

    if not data
      return fn null, data

    if data.expire < Date.now()
      debug 'expired key: %s removing from cache', key

      @client.del @key(key)
      return setImmediate fn

    setImmediate fn.bind null, null, data.value

    return

  set: (key, val, ttl = 30, fn) ->
    if typeof ttl is 'function'
      return @set key, val, null, ttl

    debug 'set', key, val, ttl

    if val is undefined
      return fn()

    @client.set @key(key),
      value: val
      expire: Date.now() + ttl * 1000

    setImmediate fn.bind null, null, val

    return

  del: (key, fn) ->
    debug 'delete', key

    @client.delete @key(key)
    setImmediate fn

    return

  clear: (fn) ->
    debug 'clear'

    @client.reset()
    setImmediate fn

    return

module.exports = MemoryStore