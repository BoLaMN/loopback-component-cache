debug = require('debug')('loopback:cache:component')

{ defaults } = require 'lodash'

Cache = require './cache'

module.exports = (app, options = {}) ->

  options = defaults
    codec: 'json'
    datastores:
      local:
        type: 'memory'
    policy:
      type: 'standard'
      ttl: 30 # seconds
    interface:
      type: 'redis'
    prefix: ''
  , options

  app.cache = new Cache options

  return