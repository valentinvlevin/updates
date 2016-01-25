(function() {
  'use strict';

  angular.module('stormpath', ['stormpath.contants']);

  angular.module('stormpath').run(function($stormpath, $rootScope, $state){
    $stormpath.uiRouter({
      loginState: 'login',
      defaultPostLoginState: 'home'
    });

    var deRegistrationCallback = $rootScope.$on('$sessionEnd',
      function () {
        $state.transitionTo('login');
      });
    $rootScope.$on('$destroy', deRegistrationCallback);
  });

  angular.module('stormpath').run(function ($rootScope, $user, STORMPATH_CONFIG) {
    $rootScope.user = $user.currentUser || null;
    $user.get().finally(function () {
      $rootScope.user = $user.currentUser;
    });

    var deRegistrationCallback =  $rootScope.$on(STORMPATH_CONFIG.GET_USER_EVENT, function () {
      $rootScope.user = $user.currentUser;
    });
    $rootScope.$on('$destroy', deRegistrationCallback);

    deRegistrationCallback = $rootScope.$on(STORMPATH_CONFIG.SESSION_END_EVENT,
      function () {
        $rootScope.user = $user.currentUser;
      });
    $rootScope.$on('$destroy', deRegistrationCallback);
  });

})();