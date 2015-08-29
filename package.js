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
    'underscore',
    'http',
    'aramk:utility@0.10.0'
  ], ['client', 'server']);
  api.imply('iron:router');
  api.export('Routes', 'client');
  api.addFiles([
    'src/Typeform.coffee'
  ], ['client', 'server']);
});
