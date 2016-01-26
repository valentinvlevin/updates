(function() {
  angular.module('app').controller('ProjectListController', ProjectListController);

  ProjectListController.$inject = ['projects', 'projectsService', '$log', '$stateParams', '$state', 'dialogs', '$scope'];

  function ProjectListController(projects, projectsService, $log, $stateParams, $state, dialogs, $scope) {
    var vm = this;
    vm.gridOptions = {
      data: projects,
      columnDefs: [
        {name: 'projectName', width: 200, displayName: 'Проект', pinnedLeft: true,
          cellTemplate: '<div class="ui-grid-cell-contents"><a ui-sref="main.content.updates({\'idProject\': {{row.entity.id}}})">{{row.entity.projectName}}</a></div>'},
        {name: 'description', displayName: 'Описание', pinnedLeft: true},
        {name:' ', width: 90, enableSorting: false, enableColumnMenu: false,
          cellTemplate: '<div><button class="btn btn-default btn-block btn-sm" ng-click="grid.appScope.editProject(row.entity.id)">Изменить</button></div>'},
        {name:'  ', width: 90, enableSorting: false, enableColumnMenu: false,
            cellTemplate: '<div></div><button class="btn btn-default btn-block btn-sm"ng-click="grid.appScope.deleteProject(row.entity)">Удалить</button></div>'}
      ],

      enableRowSelection: true,
      enableRowHeaderSelection: false,
      multiSelect: false,
      modifierKeysToMulriSelect: false,
      noUnselect: true,
      onRegisterApi: onRegisterApi,
      appScopeProvider: vm
    };

    vm.editProject = editProject;
    vm.addProject = addProject;
    vm.deleteProject = deleteProject;

    vm.haveSelectedRow = haveSelectedRow;

    function onRegisterApi(gridApi) {
      vm.gridApi = gridApi;
      gridApi.core.on.rowsRendered($scope, onRowsRendered);
    }

    function onRowsRendered() {
      if (vm.gridApi.grid.rows.length>0) {
        vm.gridApi.selection.selectRow(vm.gridApi.grid.rows[0].entity)
      }
    }

    function haveSelectedRow() {
      return vm.gridApi.selection.getSelectedCount()>0;
    }

    function editProject(projectId) {
      projectsService.getProjectDetails(projectId).then(
        function (projectData) {
          projectData.action = 'edit';

          dialogs.create(
            $stateParams.editForm.templateUrl,
            $stateParams.editForm.controller,
            {projectData: projectData},
            {keyboard: false, backdrop: false, size: 'lg'},
            $stateParams.editForm.controllerAs).result.then(
              function () {
                $state.reload($stateParams.name);
              },
              function (error) {
                $log.log(error);
              })
        },
        function (response) {
          dialogs.error('Error', response, {});
        }
      )
    }

    function addProject() {
      var projectData = { action: 'add' };
      dialogs.create(
        $stateParams.editForm.templateUrl,
        $stateParams.editForm.controller,
        {projectData: projectData},
        {keyboard: false, backdrop: false, size: 'lg'},
        $stateParams.editForm.controllerAs).result.then(
          function() {
            $state.reload($stateParams.name);
          },
          function(error) {
            $log.log(error);
          });
    }

    function deleteProject(project) {
      dialogs.confirm('Подтверждение', 'Удалить проект "'+project.description+"?", {}).result.then(
        function () {
          projectsService.deleteProject(project.id).then(
            function() {
                $state.reload($stateParams.name);
            },
            function(response) {
              dialogs.error('Ошибка', response, {});
            });
        });
    }

  }
})();