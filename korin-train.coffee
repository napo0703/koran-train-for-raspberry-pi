fs = require 'fs'
path = require 'path'
dir = '/sys/class/gpio/'

fs.writeFile path.join(dir, 'export'), 2
fs.writeFile path.join(dir, 'export'), 3
gpio2 = path.join dir, 'gpio' + 2
gpio3 = path.join dir, 'gpio' + 3
fs.writeFile path.join(gpio2, 'direction'), 'out'
fs.writeFile path.join(gpio3, 'direction'), 'out'

process.env.LINDA_BASE  ||= 'http://linda-server.herokuapp.com'
process.env.LINDA_SPACE ||= 'delta'

## Linda
LindaClient = require('linda').Client
socket = require('socket.io-client').connect(process.env.LINDA_BASE)
linda = new LindaClient().connect(socket)
ts = linda.tuplespace(process.env.LINDA_SPACE)

linda.io.on 'connect', ->
  console.log "connect!! <#{process.env.LINDA_BASE}/#{ts.name}>"
  last_at = 0

  ts.watch {type: 'move', cmd: 'right'}, (err, tuple) ->
    return console.error err if err
    return if tuple.data.response?
    return if last_at + 2000 > Date.now()  # 5sec interval
    last_at = Date.now()
    console.log tuple
    fs.writeFileSync path.join(gpio2, 'value'), 1
    fs.writeFileSync path.join(gpio3, 'value'), 0

  ts.watch {type: 'move', cmd: 'left'}, (err, tuple) ->
    return console.error err if err
    return if tuple.data.response?
    return if last_at + 2000 > Date.now()  # 5sec interval
    last_at = Date.now()
    console.log tuple
    fs.writeFileSync path.join(gpio2, 'value'), 0
    fs.writeFileSync path.join(gpio3, 'value'), 1

  ts.watch {type: 'move', cmd: 'stop'}, (err, tuple) ->
    return console.error err if err
    return if tuple.data.response?
    return if last_at + 2000 > Date.now()  # 5sec interval
    last_at = Date.now()
    console.log tuple
    fs.writeFileSync path.join(gpio2, 'value'), 0
    fs.writeFileSync path.join(gpio3, 'value'), 0

linda.io.on 'disconnect', ->
  console.log "socket.io disconnect.."
