'use strict'

module.exports =
  encode: (value, cb) ->
    try
      cb null, JSON.stringify value
    catch e
      cb e

    return

  decode: (value, cb) ->
    try
      if Buffer.isBuffer value
        value = value.toString 'utf8'
      cb null, JSON.parse value
    catch e
      cb e

    return
