(function() {
  angular.module('app.login').run(runBlock);

  function runBlock($rootScope) {
    $rootScope.user = {};
  }
})();