(function(){
  angular.module('stormpath')
    .config(function($stateProvider){
      $stateProvider
        .state('login', {
          url: '/login',
          templateUrl: '/app/login/loginForm/loginForm.html',
          controller: 'LoginFormController',
          controllerAs: 'loginFromCtrl',
          resolve: {
            data:
              function() {
                return 1;
              }
          }
        })
        .state('home', {
          url: '/home',
          templateUrl: '/app/login/loginForm/loginForm.html_',
          controller: 'LoginFormController',
          controllerAs: 'loginFromCtrl',
          sp: {
            authenticate: true,
            authorize: {
              group: 'admins'
            }
          }
        })
    })
  ;
})();