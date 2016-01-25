(function() {
  angular.module('stormpath').provider('$keycloak', $keycloakProvider);

  function $keycloakProvider() {
    var kc = new window.Keycloak('keycloak.json');
    kc.init({}).success(function(data){

    });

/*
    var keycloakConfig = {};
    this.setConfig = function(config) {
      keycloakConfig = config;
    };

*/
    this.$get = function() {

      function KeycloakService() {
        return this;
      }

      KeycloakService.prototype.getKeyCloak = function() {
        return kc;
      }

      return new KeycloakService();
    }
  }
})();