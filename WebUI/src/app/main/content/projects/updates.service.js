(function(){
  angular.module('app.main').factory('updatesService', updatesService);

  updatesService.$inject = ['Restangular'];

  function updatesService(restangular) {
    function getUpdateList(projectId) {
      return restangular.one('projects', projectId).all('updates').getList();
    }

    function getUpdateDetails(projectId, updateId) {
      return restangular.one('projects', projectId).one('updates', updateId).get();
    }

    return {
      getUpdateList: getUpdateList,
      getUpdateDetails: getUpdateDetails

    }
  }
})();