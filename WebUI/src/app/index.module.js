(function() {
  'use strict';

  angular
    .module('app', [
      'ngCookies', 
      'ngSanitize', 
      'restangular', 
      'ui.router', 
      'ui.bootstrap',
      'ui.grid',
      'ui.grid.autoResize',
      'ui.grid.selection',
      'toastr',
      'pascalprecht.translate',
      'dialogs.main',
      'app.login',
      'app.main'
    ]);

})();
