(function() {
  'use strict';

  angular
    .module('app')
    .config(config);

  /** @ngInject */
  function config($logProvider, toastrConfig, RestangularProvider, $translateProvider, dialogsProvider) {

    $translateProvider.translations('ru-RU',{
      DIALOGS_ERROR: "Ошибка",
      DIALOGS_ERROR_MSG: "Произошла неизвестная ошибка.",
      DIALOGS_CLOSE: "Закрыть",
      DIALOGS_PLEASE_WAIT: "Пожалуйста, ожидайте",
      DIALOGS_PLEASE_WAIT_ELIPS: "Пожалуйста, ожидайте...",
      DIALOGS_PLEASE_WAIT_MSG: "Дождитесь завершения операции.",
      DIALOGS_PERCENT_COMPLETE: "% Завершено",
      DIALOGS_NOTIFICATION: "Сообщение",
      DIALOGS_NOTIFICATION_MSG: "Unknown application notification.",
      DIALOGS_CONFIRMATION: "Подтверждение",
      DIALOGS_CONFIRMATION_MSG: "Требуется подтверждение.",
      DIALOGS_OK: "OK",
      DIALOGS_YES: "Да",
      DIALOGS_NO: "Нет"
    });

    //$translateProvider.useSanitizeValueStrategy('sanitize');
    $translateProvider.preferredLanguage('ru-RU');
    // Enable log
    $logProvider.debugEnabled(true);

    // Set options third-party lib
    toastrConfig.allowHtml = true;
    toastrConfig.timeOut = 3000;
    toastrConfig.positionClass = 'toast-top-right';
    toastrConfig.preventDuplicates = true;
    toastrConfig.progressBar = true;

    RestangularProvider.setBaseUrl('http://localhost:18080/updates/rest/v0');
    RestangularProvider.addRequestInterceptor(function(elem, operation) {
      if (operation === "remove") {
        return null;
      }
      return elem;
    });

    RestangularProvider.setDefaultHeaders({
      Authorization: 'Basic '+btoa('admin:12345'),
      Accept: 'application/json;charset=UTF-8'
    });

    dialogsProvider.setSize('md');
  }

})();
