(function(){
  angular.module('app.main').controller('ContentController', ContentController);

  ContentController.$inject = ['$state'];

  function ContentController($state) {
    var vm = this;
    vm.state = $state;
  }
})();