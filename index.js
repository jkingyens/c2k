#!/usr/bin/env node
let fs = require('fs')
let mkdirp = require('mkdirp')
let rimraf = require('rimraf')
let uuid = require('node-uuid')
let ncp = require('ncp')

// commmand line options
let ip = process.argv.length == 4 ? process.argv[2] : '127.0.0.1'
let port = process.argv.length == 4 ? process.argv[3] : 3000 

// remove output if already exists
let cwd = process.cwd()
let outputDir = cwd + '/output'
let p = new Promise((resolve, reject) => {  
  fs.stat(outputDir, (e, stats) => { 
    if (e || !stats) { 
      resolve()
    } else { 
      rimraf(outputDir, () => { 
        resolve()
      })
    }
  });
})

// gather & validate template inputs
p.then(() => {
  fs.readFile(cwd + '/counter.json', 'utf8', (err, data) => { 
    if (err || !data) { 
      return console.error('counter.json not found')
    }
    fs.readFile(cwd + '/counter.js', 'utf8', (err, code) => { 
      if (err || !code) { 
        return console.error('counter.js not found')
      }
      var counter = JSON.parse(data)
      if (!counter.title) { 
        return console.error('missing "title" in counter.json')
      }
      if (!counter.max) { 
        return console.error('missing "max" in counter.json')
      }
      if (!counter.color) { 
        return console.error('missing "color" in counter.json')
      }
      let inputs = {
        counter: { 
          title: counter.title,
          max: counter.max,
          color: counter.color,
          sensor: new Buffer(code).toString('base64')
        },
        auth: { 
          username: 'authtoken',
          password: new Buffer(uuid.v4()).toString('base64')
        },
        toolchain: { 
          params: { 
            host: ip,
            port: port
          },
          timestamp: new Date().toISOString(),
          version: '0.1.0'
        }
      }
      render(cwd, outputDir, inputs)
    })
  })
})

function render(inDir, outDir, inputs) { 
  mkdirp(outDir, (e) => {
    if (e) { 
      return console.error('error creating build output directory')
    }
    ncp(`${__dirname}/template`, outDir, (e) => { 
      if (e) { 
        return console.error('error rendering template into output build directory')
      }
      fs.writeFile(outDir + '/raw.json', JSON.stringify(inputs, null, 2), (err) => { 
        if (err) { 
          return console.error('error writing raw.json to output directory')
        }
        let serverDir = outDir + '/server'
        mkdirp(serverDir, (e) => { 
          if (e) { 
            return console.error('error creating server output directory')
          }
          let envFile = `TITLE=${inputs.counter.title}
MAXVALUE=${inputs.counter.max}
USERNAME=${inputs.auth.username}
PASSWORD=${inputs.auth.password}
RED=${inputs.counter.color.red}
GREEN=${inputs.counter.color.green}
BLUE=${inputs.counter.color.blue}
`
          fs.writeFile(serverDir + '/counter.env', envFile, (e) => { 
            if (e) { 
              return console.error('error rendering environment variable template')
            }
            mkdirp(outDir + '/server/sensor', (e) => { 
              if (e) { 
                return console.error('error creating server counter ouput directory')
              }
              fs.writeFile(outDir + '/server/sensor/server.js', new Buffer(inputs.counter.sensor, 'base64').toString('utf8'), () => { 
                if (e) { 
                  return console.error('error rendering counter function to output file')
                }
                let composeFile = `version: '2'
services:
  c2k:
    build: .
    env_file: counter.env
    ports:
    - "${inputs.toolchain.params.port}:3000"
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock
`
                fs.writeFile(outDir + '/server/docker-compose.yml', composeFile, (e) => { 
                  if (e) { 
                    return console.error('error rendering a docker compose file to build output directory')
                  }
                  
                  let iosConfigFile = `//
//  Config.swift
//  c2k
//
//  Created by Jeff Kingyens on 5/21/17.
//
//

import Foundation

struct Config {
    
    static let host = "${inputs.toolchain.params.host}"
    static let port = ${inputs.toolchain.params.port}
    static let username = "${inputs.auth.username}"
    static let password = "${inputs.auth.password}"
    
}
`
                  fs.writeFile(outDir + '/ios/c2k/Config.swift', iosConfigFile, () => { 
                    
                    if (e) { 
                      return console.error('error rendering swift configuration file for iOS app')
                    }

                  })                 
                })
              })
            })
          })
        })
      })
    })
  })
}