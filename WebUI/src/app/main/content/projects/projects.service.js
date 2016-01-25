(function(){

  angular.module('app').factory('projectsService', projectsService);

  projectsService.$inject = ['Restangular'];

  function projectsService(restangular) {

    function getProjectList() {
      return restangular.all('projects').getList();
    }

    function getProjectDetails(projectId) {
      return restangular.one('projects', projectId).get();
    }

    function updateProject(data) {
      return restangular.one('projects', data.id).customPUT(
        $.param({projectName: data.projectName, description: data.description}),
        undefined, undefined,
        {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}
      )
    }

    function addProject(data) {
      return restangular.one('projects', data.id).customPOST(
        $.param({projectName: data.projectName, description: data.description}),
        undefined, undefined,
        {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}
      )
    }

    function getUpdateList(projectId) {
      return restangular.one('projects', projectId).all('updates').getList();
    }

    function getUpdateDetails(projectId, updateId) {
      return restangular.one('projects', projectId).one('updates', updateId).get();
    }

    return {
      getProjectList: getProjectList,
      getProjectDetails: getProjectDetails,
      getUpdateList: getUpdateList,
      getUpdateDetails: getUpdateDetails,

      updateProject: updateProject,
      addProject: addProject
    }
  }
})();