(function() {
  'use strict';

  angular.module('stormpath')
    .controller('LoginFormController', LoginFormCtrl);

  LoginFormCtrl.$inject = ['$auth', '$user'];

  function LoginFormCtrl($auth, $user) {
    var vm = this;
    vm.formModel = {
      username: '',
      password: ''
    };
    vm.posting = false;

    vm.submit = function () {
      vm.posting = true;
      vm.error = null;
      var op = $auth.authenticate(vm.formModel);
      op.then(
        function() {
          $user.cachedUserOp = op;
        },
        function (response) {
          //vm.posting = false;
          //vm.error = response.data && response.data.error || 'An error occured when communicating with server.';
        });
    };
  }
})();