// Meteor package definition.
Package.describe({
  name: 'aramk:typeform',
  version: '1.0.0',
  summary: 'Adapter for typeform.io.',
  git: 'https://github.com/aramk/meteor-typeform.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.6.1');
  api.use([
    'coffeescript@2.2.1_1',
    'http',
    'templating',
    'underscore',
    'aramk:q@1.0.1_1',
    'urbanetic:utility@2.0.1',
    'urbanetic:bismuth-utility@1.0.1',
    'cfs:http-methods@0.0.30',
  ], ['client', 'server']);
  api.export([
    'Typeform',
    'TypeformIO',
    'TypeformResponseConverter',
    'TypeformResponses',
    'TypeformIOResponses'
  ], ['client', 'server']);
  api.imply('iron:router');
  api.addFiles([
    'src/Typeform.coffee',
    'src/TypeformIO.coffee',
    'src/TypeformResponseConverter.coffee',
    'src/TypeformResponses.coffee',
    'src/TypeformIOResponses.coffee'
  ], ['client', 'server']);
  api.addFiles([
    'src/server.coffee'
  ], 'server');
  api.addFiles([
    'src/typeform.html'
  ], 'client');
});

Package.onTest(function (api) {
  api.use([
    'coffeescript',
    'tinytest',
    'test-helpers',
    'tracker',

    'urbanetic:utility',
    'practicalmeteor:munit',
    'aramk:typeform'
  ]);

  api.addFiles([
    'tests/initSpec.coffee',
    'tests/fixtures/Fixtures.coffee',
    'tests/fixtures/typeform-io-response.json.js',
    'tests/TypeformIOResponsesSpec.coffee'
  ]);
});
