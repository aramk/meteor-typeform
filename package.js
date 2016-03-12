// Meteor package definition.
Package.describe({
  name: 'aramk:typeform',
  version: '0.1.0',
  summary: 'Adapter for typeform.io.',
  git: 'https://github.com/aramk/meteor-typeform.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use([
    'coffeescript',
    'http',
    'templating',
    'underscore',
    'aramk:q@1.0.1_1',
    'urbanetic:utility@1.0.1',
    'urbanetic:bismuth-utility@0.2.1',
    'cfs:http-methods@0.0.30',
  ], ['client', 'server']);
  api.export([
    'TypeformResponseConverter',
    'TypeformResponses',
    'Typeform'
  ], ['client', 'server']);
  api.imply('iron:router');
  api.addFiles([
    'src/Typeform.coffee',
    'src/TypeformIO.coffee',
    'src/TypeformResponseConverter.coffee',
    'src/TypeformResponses.coffee'
  ], ['client', 'server']);
  api.addFiles([
    'src/server.coffee'
  ], 'server');
  api.addFiles([
    'src/typeform.html'
  ], 'client');
});
