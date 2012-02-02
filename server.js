// Generated by IcedCoffeeScript 1.2.0i
(function() {
  var app, express, gm, port, _,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  express = require('express');

  app = express();

  app.use(express["static"](__dirname + '/public'));

  _ = require('underscore');

  gm = require('googlemaps');

  app.get('/proxy/reverseGeocode', function(req, res) {
    return gm.reverseGeocode(req.param('latlng'), function(err, response) {
      var parse, result;
      parse = function(attribute) {
        var component;
        component = _.find(response.results[0].address_components, function(c) {
          return __indexOf.call(c.types, attribute) >= 0;
        });
        return component.long_name;
      };
      result = [parse('postal_code'), parse('route'), parse('street_number')].join(' ');
      console.log('[GET]', req.url, '->', result);
      return res.send(result);
    });
  });

  port = process.env.PORT || 8080;

  app.listen(port, function() {
    return console.log('server listening at port', port);
  });

}).call(this);
