(function() {
  angular.module('app').controller('ProjectListController', ProjectListController);

  ProjectListController.$inject = ['projects', 'projectsService', '$log', '$stateParams', '$state', 'dialogs', '$scope'];

  function ProjectListController(projects, projectsService, $log, $stateParams, $state, dialogs, $scope) {
    var vm = this;
    vm.gridOptions = {
      data: projects,
      columnDefs: [
        {name: 'id', displayName: 'ID', pinnedLeft: true},
        {name: 'projectName', displayName: 'Проект', pinnedLeft: true},
        {name: 'description', displayName: 'Описание', pinnedLeft: true}
      ],

      enableRowSelection: true,
      enableRowHeaderSelection: false,
      multiSelect: false,
      modifierKeysToMulriSelect: false,
      noUnselect: true,
      onRegisterApi: onRegisterApi
    };

    vm.editProject = editProject;
    vm.addProject = addProject;
    vm.selectedRow = {};

    function onRegisterApi(gridApi) {
      vm.gridApi = gridApi;
      gridApi.selection.on.rowSelectionChanged($scope, function(row) {
        vm.selectedRow = row.entity;
      })
    }

    function editProject(idProject) {
      projectsService.getProjectDetails(idProject).then(
        function (projectData) {
          projectData.action = 'edit';

          dialogs.create(
            $stateParams.editForm.templateUrl,
            $stateParams.editForm.controller,
            {projectData: projectData},
            {keyboard: false, backdrop: false},
            $stateParams.editForm.controllerAs).result.then(
            function() {
              $state.reload($stateParams.name);
            },
            function(error) {
              $log.log(error);
            }
          )
        },
        function (response) {
          dialogs('Error', response);
        }
      )
    }

    function addProject() {
      var projectData = { action: 'add' };
      dialogs.create(
        $stateParams.editForm.templateUrl,
        $stateParams.editForm.controller,
        {projectData: projectData},
        {keyboard: false, backdrop: false},
        $stateParams.editForm.controllerAs).result.then(
        function() {
          $state.reload($stateParams.name);
        },
        function(error) {
          $log.log(error);
        }
      )
    }

  }
})();