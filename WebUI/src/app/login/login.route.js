(function() {
  angular.module('app.login').config(routeConfig);

  function routeConfig($stateProvider) {
    $stateProvider
      .state('login', {
        url: '/login',
        templateUrl: 'login/loginForm/loginForm.html',
        controller: 'LoginFromController',
        controllerAs: 'loginCtrl'
      })
  }
})();