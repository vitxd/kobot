module.exports = (robot) ->
  robot.respond /man (.+)/i, (msg) ->
    url = 'http://explainshell.com/explain?cmd=' + encodeURIComponent(msg.match[1]).split("%20").join("+")
    msg
      .http(url)
      .get() (err, res, body) ->
        $ = require('cheerio').load(body);
        res = $('#help .help-box').text()
        console.log(res)
        if res
          msg.send url
          msg.send res
        else
          msg.send "Not found"