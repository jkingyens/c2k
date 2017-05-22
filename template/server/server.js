var Docker = require('dockerode')
var concat = require('concat-stream')
var express = require('express')
var http = require('http')
var basic = require('basic-auth')

// how do we connect using our server instance
var docker = new Docker({socketPath: '/var/run/docker.sock'});

// environment variables that we configure
var title = process.env.TITLE
var username = process.env.USERNAME
var password = process.env.PASSWORD
var maxvalue = process.env.MAXVALUE
var red = process.env.RED
var green = process.env.GREEN
var blue = process.env.BLUE

// security, for now
var auth = function (req, res, next) {
  function unauthorized(res) {
    res.set('WWW-Authenticate', 'Basic realm=Authorization Required');
    return res.sendStatus(401);
  };
  var user = basic(req);
  if (!user || !user.name || !user.pass) {
    console.error('authentication error')
    return unauthorized(res);
  };
  if (user.name === username && user.pass === password) {
    return next();
  } else {
    console.error('authentication error')
    return unauthorized(res);
  };

};

// server the counter sensor
var app = express()
app.get('/counter', auth, function (req, res) {
  var result = concat(function (captured) { 
    var new_value = Number(captured.toString().trim())
    let result = { 
      max: Number(maxvalue),
      title: title,
      color: { 
        r: Number(red),
        g: Number(green),
        b: Number(blue)
      },
      value: new_value
    }
    console.log(result)
    res.json(result)
  })
  docker.run('sensor', ['node', 'server.js'], [result, process.stderr], {Tty:false}, function (err, data, container) {
    if (err) { 
      console.error('error running sensor image')
    }
  });
})

// rebuild the counter image when we boot the server
console.log('building sensor image')
docker.buildImage({
  context: `${__dirname}/sensor`,
  src: ['Dockerfile', 'package.json', 'server.js']
}, {t: 'sensor' }, function (err, stream) {
  if (err) {
    return console.log('error building image')
  }
  docker.modem.followProgress(stream, function (e) { 
    console.log('sensor image built, starting server')
    var server = http.createServer(app);
    server.listen(3000)
  });  
})