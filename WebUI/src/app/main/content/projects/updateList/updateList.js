(function() {
  angular.module('app.main').controller('UpdateListController', UpdateListController);

  UpdateListController.$inject = ['updateList', 'updatesService'];

  function UpdateListController(updateList, updateService) {
    var vm = this;

    vm.gridOptions = {
      data: updateList,
      enableRowSelection: true,

    }
  }
})();
