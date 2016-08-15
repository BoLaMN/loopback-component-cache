'use strict'

debug = require('debug')('loopback:cache:standard')
CachePolicy = require './abstract'
async = require 'async'

class StandardCachePolicy extends CachePolicy
  constructor: (@cache, @datastores, @codec, @options) ->
    super()

    @ttl = @options.ttl or 30

  get: (context, callback) ->
    debug 'get: %s', context.keyCache

    fullKey = @key context.keyCache

    get = (datastore, done) =>
      datastore.get fullKey, (err, result) =>
        debug 'encoded result:', result

        if err or not result
          if err
            @cache.emit 'persistenceError', err

          return done err

        @decode result, (err, decompressedResult) ->
          debug 'decoded result:', decompressedResult

          if err
            return done err

          done null, decompressedResult

    get @datastores[0], (err, data) ->
      if err
        return callback err

      cached = context.cached = ! !data

      if not cached
        return callback()

      context.result = data

      context.done (err) ->
        if err
          callback err

      return
    return

  set: (key, result, callback) ->
    debug 'set: %s', key, result

    fullKey = @key key

    @encode result, (err, compressed) =>
      debug 'encoded set: %s', compressed

      set = (datastore, done) =>
        datastore.set fullKey, compressed, @ttl, done

      async.each @datastores, set, (err) =>
        if err
          @cache.emit 'persistenceError', err, datastore

        callback()

    return

module.exports = StandardCachePolicy
