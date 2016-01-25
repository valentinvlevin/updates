(function() {
  angular.module('stormpath').directive('ifUser', function ($user, $rootScope) {
    return {
      link: function (scope, element) {
        var deRegistrationCallback = $rootScope.$watch('user', function (user) {
          if (user && user.href) {
            element.removeClass('ng-hide');
          } else {
            element.addClass('ng-hide');
          }
        });

        $rootScope('$destroy', deRegistrationCallback);
      }
    };
  });
  angular.module('stormpath').directive('ifNotUser',function ($user, $rootScope) {
    return {
      link: function (scope, element) {
        var deRegistrationCallback = $rootScope.$watch('user', function (user) {
          if (user && user.href) {
            element.addClass('ng-hide');
          } else {
            element.removeClass('ng-hide');
          }
        });
        $rootScope('$destroy', deRegistrationCallback);
      }
    };
  });
  angular.module('stormpath').directive('ifUserInGroup', function ($user, $rootScope, $parse, $stormpath) {

    return {
      link: function (scope, element, attrs) {

        var expr;
        var attrExpr = attrs.ifUserInGroup;

        function evalElement() {
          var user = $user.currentUser;
          if (user && user.groupTest(expr || attrExpr)) {
            element.removeClass('ng-hide');
          } else {
            element.addClass('ng-hide');
          }
        }

        if (attrExpr) {
          var deRegistrationCallback = scope.$watch($parse(attrExpr), function (value) {
            expr = $stormpath.regexAttrParser(value);
            evalElement();
          });
          scope('$destroy', deRegistrationCallback);

          deRegistrationCallback = $rootScope.$watch('user', function () {
            evalElement();
          });
          $rootScope('$destroy', deRegistrationCallback);
        }
      }
    };
  });
  angular.module('stormpath').directive('ifUserNotInGroup', function ($user, $rootScope, $parse, $stormpath) {
    return {
      link: function (scope, element, attrs) {

        var expr;
        var attrExpr = attrs.ifUserNotInGroup;

        function evalElement() {
          var user = $user.currentUser;
          if (user && user.groupTest(expr || attrExpr)) {
            element.addClass('ng-hide');
          } else {
            element.removeClass('ng-hide');
          }
        }

        if (attrExpr) {
          scope.$watch($parse(attrExpr), function (value) {
            expr = $stormpath.regexAttrParser(value);
            evalElement();
          });
          var deRegistrationCallback = $rootScope.$watch('user', function () {
            evalElement();
          });
          $rootScope('$destroy', deRegistrationCallback);
        }
      }
    };
  });
  angular.module('stormpath').directive('ifUserStateKnown', function ($user, $rootScope) {
    return {
      link: function (scope, element) {
        var deRegistrationCallback = $rootScope.$watch('user', function () {
          if ($user.currentUser || ($user.currentUser === false)) {
            element.removeClass('ng-hide');
          } else {
            element.addClass('ng-hide');
          }
        });
        $rootScope('$destroy', deRegistrationCallback);
      }
    };
  });
  angular.module('stormpath').directive('ifUserStateUnknown', function ($user, $rootScope) {
    return {
      link: function (scope, element) {
        var deRegistrationCallback = $rootScope.$watch('user', function () {
          if ($user.currentUser === null) {
            element.removeClass('ng-hide');
          } else {
            element.addClass('ng-hide');
          }
        });
        $rootScope('$destroy', deRegistrationCallback);
      }
    };
  });
  angular.module('stormpath').directive('spLogout', function ($auth) {
    return {
      link: function (scope, element) {
        element.on('click', function () {
          $auth.endSession();
        });
      }
    };
  });
})();