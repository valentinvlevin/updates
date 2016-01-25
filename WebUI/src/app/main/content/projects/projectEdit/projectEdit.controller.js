(function(){
  angular.module('app.main').controller('ProjectEditController', ProjectEditController);

  ProjectEditController.$inject = ['$uibModalInstance', 'projectsService', 'data'];

  function ProjectEditController($uibModalInstance, projectsService, data) {
    var vm = this;

    vm.projectData = data.projectData;

    vm.save = save;
    vm.cancel = cancel;

    if (vm.projectData.action == 'add') {
      vm.actionName = 'Добавить новый';
    } else {
      vm.actionName = 'Изменить';
    }

    function save() {
      var pm;
      if (vm.projectData.action == 'edit') {
        pm = projectsService.updateProject(vm.projectData);
      } else {
        pm = projectsService.addProject(vm.projectData);
      }
      pm.then(function(id) {
        $uibModalInstance.close(id);
      });
    }

    function cancel() {
      $uibModalInstance.dismiss('Canceled');
    }
  }
})();