fs = require 'fs'
gm = require 'googlemaps'
request = require 'request'
$ = require 'jQuery'
_ = require 'underscore'
_.str = require 'underscore.string'
_.mixin _.str.exports()

class BathParser
  constructor: (@url) ->
  
  fetchBody: (cb) ->
    request @url, (error, response, body) ->
      cb($(body))

  geocode: (address, cb) ->
    gm.geocode address, (error, response) ->
      if not error and response.status == 'OK'
        location = response.results[0].geometry.location
        cb { lat: location.lat, lng: location.lng }
      else
        console.log 'could not geocode', address
        cb()

  run: (cb) ->
    await @fetchBody defer @body
    result =
      address: @address()
      name: @name()
      laneLength: @laneLength()
      openingTimes: @openingTimes()
    await @geocode result.address, defer result.location
    console.log 'finished', result.name
    cb result
  
  address: ->
    lines = @body.find('#content_left p:first b').html().split '<br>'
    lines[1] + ', ' + lines[0]

  name: ->
    @body.find('#content h1:first').text()

  laneLength: ->
    content = @body.find('#content').text()
    if _.str.include content, '50-m-Becken'
      '50m'
    else
      '25m'

  openingTimes: ->
    result = {}
    lastDay = ''
    @body.find('#content_ul > table:first tr').each (index, row) =>
      [day, time, comment] = for node in $(row).find('td')
        _.trim $(node).text()
      day ||= lastDay
      @addTimeTableEntry result, day, time, comment if time
      lastDay = day
    result

  cleanComment: (comment) ->
    if _.str.include comment, 'Parallelbetrieb'
      comment = _.str.insert comment, 'Parallelbetrieb'.length, ' '
      comment = comment.split('/ ').join '/'
    comment = _.trim comment, '*'

  addTimeTableEntry: (openingTimes, day, time, comment) ->  
    [from, to] = time.split ' - '
    comment = @cleanComment(comment)
    if comment
      newEntry = { from, to, comment }
    else
      newEntry = { from, to } # saves 10%
    openingTimes[day] ||= []
    openingTimes[day].push newEntry

baseUrl = 'http://www.berlinerbaederbetriebe.de/'
request baseUrl + '24.html', (error, response, body) ->
  if !error and response.statusCode == 200
    baths = []
    bathLinks = $(body).find 'div#content > p > a'
    console.log 'crawling', bathLinks.length, 'baths'
    await
      for link, i in bathLinks
        url = baseUrl + $(link).attr 'href'
        new BathParser(url).run defer baths[i]
    openedBaths = (bath for bath in baths when not _.isEmpty bath.openingTimes)
    content = 'Baths = ' + JSON.stringify openedBaths
    console.log 'writing to public/baths.json'
    fs.writeFile 'public/baths.json', content, (err) ->
      throw err if err
  else
    console.log "could not access", baseUrl
