'use strict'

debug = require('debug')('loopback:cache:standard')
CachePolicy = require './abstract'
async = require 'async'

class StandardCachePolicy extends CachePolicy
  constructor: (@cache, @datastores, @codec, @options) ->
    super()

    @ttl = @options.ttl or 30

  get: (key, callback) ->
    debug 'get: %s', key

    fullKey = @key key

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

    get @datastores[0], callback

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
