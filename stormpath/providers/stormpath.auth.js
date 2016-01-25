(function() {
  'use strict';
  angular.module('stormpath').provider('$auth', $authProvider);

  function $authProvider() {
    this.$get  = [
      '$http', '$user', '$rootScope', '$spFormEncoder', 'STORMPATH_CONFIG',
      function ($http, $user, $rootScope, $spFormEncoder, STORMPATH_CONFIG) {

        function AuthService() {
          return this;
        }

        AuthService.prototype.authenticate = function authenticate(data) {
          var op = $http($spFormEncoder.formPost({
              url: STORMPATH_CONFIG.getUrl('AUTHENTICATION_ENDPOINT'),
              method: 'POST',
              data: data,
              withCredentials: true/*,

              headers: {
                Authorization: "Basic " + btoa(data.username + ":" + data.password)
              }
*/
            })
          );

          var op2 = op.then(cacheCurrentUser).then(authenticatedEvent);
          op.catch(authenticationFailureEvent);
          return op2;
        };

        function endSessionEvent() {
          $rootScope.$broadcast(STORMPATH_CONFIG.SESSION_END_EVENT);
        }

        AuthService.prototype.endSession = function endSession($log) {
          var op = $http.get(STORMPATH_CONFIG.getUrl('DESTROY_SESSION_ENDPOINT'), {
            headers: {
              'Accept': 'application/json'
            }
          });

          op.then(function () {
            endSessionEvent();
          }, function (response) {
            $log.error('logout error', response);
          });

          return op;
        };

        function cacheCurrentUser() {
          return $user.get();
        }

        function authenticatedEvent(response) {
          $rootScope.$broadcast(STORMPATH_CONFIG.AUTHENTICATION_SUCCESS_EVENT_NAME, response);
        }

        function authenticationFailureEvent(response) {
          $rootScope.$broadcast(STORMPATH_CONFIG.AUTHENTICATION_FAILURE_EVENT_NAME, response);
        }

        return new AuthService();
      }
    ]
  }

})();