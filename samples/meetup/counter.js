let request = require('request')
let apiKey = '606b2a1f247a6e457e2c1a31203e63'

request({ 
    url: 'https://api.meetup.com/members/self',
    method: 'GET',
    json: true,
    qs: { 
        'photo-host': 'public',
        fields: 'stats',
        page: 20,
        key: apiKey,
        json: true
    }
}, function (err, resp, data) { 
    if (err) { return process.exit(-1) }
    console.log(data.stats.rsvps)
})