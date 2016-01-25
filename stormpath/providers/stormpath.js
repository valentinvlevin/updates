(function(){
  angular.module('stormpath').provider('$stormpath', function $stormpathProvider() {

    this.$get = [
      '$user', '$state', 'STORMPATH_CONFIG', '$rootScope', '$log',
      function ($user, $state, STORMPATH_CONFIG, $rootScope, $log) {

        function StormpathService() {
          return this;
        }

        function stateChangeUnauthenticatedEvent(toState, toParams) {
          $rootScope.$broadcast(STORMPATH_CONFIG.STATE_CHANGE_UNAUTHENTICATED, toState, toParams);
        }

        function stateChangeUnauthorizedEvent(toState, toParams) {
          $rootScope.$broadcast(STORMPATH_CONFIG.STATE_CHANGE_UNAUTHORIZED, toState, toParams);
        }

        StormpathService.prototype.getKeyCloak = function() { return kc;}

        StormpathService.prototype.stateChangeInterceptor = function stateChangeInterceptor(config) {
          var deRegistrationCallback = $rootScope.$on('$stateChangeStart',
            function (e, toState, toParams) {
              if (toState.sp) {
                var sp = toState.sp || {}; // Grab the sp config for this state
                if ((sp.authenticate || sp.authorize) && (!$user.currentUser)) {
                  e.preventDefault();
                  $user.get().then(function () {
                    // The user is authenticated, continue to the requested state
                    if (sp.authorize) {
                      if (authorizeStateConfig(sp)) {
                        $state.go(toState.name, toParams);
                      } else {
                        stateChangeUnauthorizedEvent(toState, toParams);
                      }
                    } else {
                      $state.go(toState.name, toParams);
                    }
                  }, function () {
                    // The user is not authenticated, emit the necessary event
                    stateChangeUnauthenticatedEvent(toState, toParams);
                  });
                } else if (sp.waitForUser && ($user.currentUser === null)) {
                  e.preventDefault();
                  $user.get().finally(function () {
                    $state.go(toState.name, toParams);
                  });
                }
                else if ($user.currentUser && sp.authorize) {
                  if (!authorizeStateConfig(sp)) {
                    e.preventDefault();
                    stateChangeUnauthorizedEvent(toState, toParams);
                  }
                } else if (toState.name === config.loginState) {
                  /*
                   If the user is already logged in, we will redirect
                   away from the login page and send the user to the
                   post login state.
                   */
                  if ($user.currentUser !== false) {
                    e.preventDefault();
                    $user.get().finally(function () {
                      if ($user.currentUser && $user.currentUser.href) {
                        $state.go(config.defaultPostLoginState);
                      } else {
                        $state.go(toState.name, toParams);
                      }
                    });
                  }
                }
              } else {
                //e.preventDefault();
              }
            });
          $rootScope.$on('$destroy', deRegistrationCallback);
        };

        function authorizeStateConfig(spStateConfig) {
          var sp = spStateConfig;
          if (sp && sp.authorize && sp.authorize.group) {
            return $user.currentUser.inGroup(sp.authorize.group);
          } else {
            $log.error('Unknown authorize configuration for spStateConfig', spStateConfig);
            return false;
          }
        }

        StormpathService.prototype.uiRouter = function uiRouter(config) {
          var self = this;
          config = angular.isObject(config) ? config : {};
          this.stateChangeInterceptor(config);

          if (config.loginState) {
            self.unauthenticatedWather = $rootScope.$on(STORMPATH_CONFIG.STATE_CHANGE_UNAUTHENTICATED, function (e, toState, toParams) {
              self.postLogin = {
                toState: toState,
                toParams: toParams
              };
              $state.go(config.loginState);
            });
          }

          var deRegistrationCallback = $rootScope.$on(STORMPATH_CONFIG.AUTHENTICATION_SUCCESS_EVENT_NAME, function () {
            if (self.postLogin && (config.autoRedirect !== false)) {
              $state.go(self.postLogin.toState, self.postLogin.toParams).then(function () {
                self.postLogin = null;
              });
            } else if (config.defaultPostLoginState) {
              $state.go(config.defaultPostLoginState);
            }
          });
          $rootScope.$on('$destroy', deRegistrationCallback);

          if (config.forbiddenState) {
            self.forbiddenWatcher = $rootScope.$on(STORMPATH_CONFIG.STATE_CHANGE_UNAUTHORIZED, function () {
              $state.go(config.forbiddenState);
            });
          }
        };

        StormpathService.prototype.regexAttrParser = function regexAttrParser(value) {
          var expr;
          if (value instanceof RegExp) {
            expr = value;
          } else if (value && /^\/.+\/[gim]?$/.test(value)) {
            expr = new RegExp(value.split('/')[1], value.split('/')[2]);
          } else {
            expr = value;
          }
          return expr;
        };

        return new StormpathService();
      }
    ];
  });
})();