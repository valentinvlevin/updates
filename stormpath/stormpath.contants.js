(function() {
  'use strict';

  angular.module('stormpath.contants', []).constant('STORMPATH_CONFIG',
    {
      ME_ENDPOINT_PREFIX: 'http://localhost:18080/auth',
      ENDPOINT_PREFIX: 'http://localhost:18080/auth',

      CLIENT_ID: 'updates',

      AUTHENTICATION_ENDPOINT: '/login',
      DESTROY_SESSION_ENDPOINT: '/users/logout',
      CURRENT_USER_URI: '/users/me',

      FORM_CONTENT_TYPE: 'application/x-www-form-urlencoded',

      AUTHENTICATION_SUCCESS_EVENT_NAME: '$authenticated',
      AUTHENTICATION_FAILURE_EVENT_NAME: '$authenticationFailure',
      GET_USER_EVENT: '$currentUser',
      NOT_LOGGED_IN_EVENT: '$notLoggedin',
      SESSION_END_EVENT: '$sessionEnd',
      STATE_CHANGE_UNAUTHENTICATED: '$stateChangeUnauthenticated',
      STATE_CHANGE_UNAUTHORIZED: '$stateChangeUnauthorized',

      getUrl: function (key) {
        return this.ENDPOINT_PREFIX + this[key];
      }
    });

})();