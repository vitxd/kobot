# Description:
#   Display meme from "The coding love <http://thecodinglove.com>"
#   or "les joies du code <http://lesjoiesducode.tumblr.com>".
#
# Dependencies:
#   "cheerio": "0.7.0"
#   "he": "0.4.1"
#
# Configuration:
#   None
#
# Commands:
#   hubot [give me some] joy [asshole] - Return a random meme (coding love)
#   hubot last joy - Returns last meme (coding love)
#
# Author:
#   Eunomie
#   Based 9gag.coffee by EnriqueVidal

cheerio = require('cheerio')
he = require('he')

module.exports = (robot)->
  robot.respond /(give me some )?joy( asshole)?/i, (message)->
    send_meme message, 'http://thecodinglove.com/random', (text)->
      message.send text
  robot.respond /last joy/i, (message)->
    send_meme message, 'http://thecodinglove.com', (text)->
      message.send text


send_meme = (message, location, response_handler)->
  url = location

  message.http(url).get() (error, response, body)->
    return response_handler "Sorry, something went wrong" if error

    if response.statusCode == 302 || response.statusCode == 301
      location = response.headers['location']
      return send_meme(message, location, response_handler)

    img_src = get_meme_image(body, ".post img").replace '.jpg', '.gif'

    txt = get_meme_txt(body, ".post h3 a")

    response_handler "#{txt} #{img_src}"

get_meme_image = (body, selector)->
  $ = cheerio.load(body)
  $(selector).first().attr('src')

get_meme_txt = (body, selector)->
  $ = cheerio.load(body)
  he.decode $(selector).first().text()