(function() {
  'use strict';

  angular
    .module('app')
    .run(runBlock);

  /** @ngInject */
  function runBlock($rootScope) {
    $rootScope.useAuth = true;
/*
    var deRegistrationCallback =  $rootScope.$on(STORMPATH_CONFIG.GET_USER_EVENT, function () {
      $rootScope.user = $user.currentUser;
    });
    $rootScope.$on('$destroy', deRegistrationCallback);
*/

  }

})();
