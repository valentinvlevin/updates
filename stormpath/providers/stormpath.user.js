(function() {
  'use strict';

  angular.module('stormpath').provider('$user', $userProvider);

  function $userProvider() {
    function User(data) {
      var self = this;
      Object.keys(data).map(function (k) {
        self[k] = data[k];
      });
    }

    User.prototype.inGroup = function inGroup(groupName) {
      return this.groups.items.filter(function(group){
          return group.name === groupName;
        }).length >0;
    };

    User.prototype.matchesGroupExpression = function matchesGroupExpression(regex) {
      return this.groups.items.filter(function(group){
          return regex.test(group.name);
        }).length >0;
    };

    User.prototype.groupTest = function groupTest(expr) {
      if(expr instanceof RegExp && this.matchesGroupExpression(expr)){
        return true;
      }else if(this.inGroup(expr)){
        return true;
      }else{
        return false;
      }
    };

    this.$get = [
        '$q', '$http', 'STORMPATH_CONFIG', '$rootScope', '$keycloak',
        function ($q, $http, STORMPATH_CONFIG, $rootScope, $keycloak) {
          function UserService() {
            this.cachedUserOp = null;
            this.currentUser = null;
            return this;
          }

          UserService.prototype.get = function get() {
            var op = $q.defer();
            var self = this;

            if (self.cachedUserOp) {
              return self.cachedUserOp.promise;
            }
            else if (self.currentUser !== null && self.currentUser !== false) {
              op.resolve(self.currentUser);
              return op.promise;
            } else {
              self.cachedUserOp = op;

              $http.get(STORMPATH_CONFIG.getUrl('CURRENT_USER_URI'),{withCredentials:true}).then(
                function(response){
                  self.cachedUserOp = null;
                  self.currentUser = new User(response.data);
                  currentUserEvent(self.currentUser);
                  op.resolve(self.currentUser);
                },
                function(response){
                  //self.currentUser = false;
                  if(response.status===401){
                    notLoggedInEvent();
                  }
                  self.cachedUserOp = null;
                  op.reject(response);
                });

              return op.promise;
            }
          };

          function currentUserEvent(user) {
            $rootScope.$broadcast(STORMPATH_CONFIG.GET_USER_EVENT, user);
          }

          function notLoggedInEvent() {
            $rootScope.$broadcast(STORMPATH_CONFIG.NOT_LOGGED_IN_EVENT);
          }

          var userService = new UserService();

          var deRegistrationCallback = $rootScope.$on(STORMPATH_CONFIG.SESSION_END_EVENT, function () {
            userService.currentUser = false;
          });
          $rootScope.$on('$destroy', deRegistrationCallback);

          return userService;
        }
      ];
    }
})();