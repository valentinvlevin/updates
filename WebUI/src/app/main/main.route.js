(function() {
  'use strict';
  angular
    .module('app.main')
    .config(routerConfig);

  /** @ngInject */
  function routerConfig($stateProvider) {
    $stateProvider
      .state('main', {
        abstract: true,
        templateUrl: 'app/main/mainForm.html'
      })
      .state('main.content', {
        abstract: true,
        views: {
          'header': {
            templateUrl: 'app/main/header/header.html',
            controller: 'HeaderController'
          },
          '': {
            templateUrl: 'app/main/content/content.html'
          },
          'footer': {
            templateUrl: 'app/main/footer/footer.html'
          }
        }
      })
      .state('main.content.projects', {
          url: '/projects',
          templateUrl: 'app/main/content/projects/projectList/projectList.html',
          controller: 'ProjectListController',
          controllerAs: 'projectsCtrl',
          resolve: {
            projects: function(projectsService) {
              return projectsService.getProjectList();
            }
          },
          auth: {
            restricted: true,
            groups: ['user', 'admin']
          },
          params: {
            editForm: {
              templateUrl: 'app/main/content/projects/projectEdit/projectEdit.html',
              controller: 'ProjectEditController',
              controllerAs: 'projectEditCtrl',
                auth: {
                  restricted: true,
                    groups: ['user', 'admin']
                }
            }
          }
      })
      .state('main.content.updates', {
        url: '/:idProject/updates',
        auth: {
          restricted: true,
          groups: ['user', 'admin']
        }
      })
      .state('main.content.updateDetails', {
        url: '/:idProject/updates/:idUpdate',
        auth: {
          restricted: true,
          groups: ['user', 'admin']
        }
      })
      .state('main.content.users', {
        url: '/users',
        templateUrl: 'app/main/content/users/userList/userList.html'
    });
  }
})();
