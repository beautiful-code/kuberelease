(function(){
	var app = angular.module('KubeRelease');

	app.controller('ShowServiceCtrl', ['$scope', '$http', function($scope, $http) {
    $scope.service = {};
    $scope.suiteId = PageConfig.suite.id;
    $scope.environmentId = PageConfig.environment.id;
    $scope.serviceId = PageConfig.service.id;
    $scope.serviceCommands = [];
    $scope.serviceVariables = [];

    var getServiceCommands = function() {
      $http({
        method: 'GET',
        url: '/suites/' + $scope.suiteId + '/environments/' + $scope.environmentId + '/service_commands?service_id=' + $scope.serviceId
      }).then(function(response) {
        if (response.data) {
          $scope.serviceCommands = response.data;
        }
      }, function(err) {
        console.log(err);
      });
    };

    var getServiceVariables = function() {
      $http({
        method: 'GET',
        url: '/suites/' + $scope.suiteId + '/environments/' + $scope.environmentId + '/service_variables?service_id=' + $scope.serviceId
      }).then(function(response) {
        if (response.data.length > 0) {
          $scope.serviceVariables = response.data;
        }
      }, function(err) {
        console.log(err);
      });
    };

    var getServiceInfo = function() {
      $http({
        method: 'GET',
        url: '/suites/' + $scope.suiteId + '/environments/' + $scope.environmentId + '/show_service/' + $scope.serviceId + '.json'
      }).then(function(response) {
        if (response.data) {
          $scope.service = response.data;
        }
      }, function(err) {
        console.log(err);
      });
    };

    var getServiceLog = function() {
      $http({
        method: 'GET',
        url: '/suites/' + $scope.suiteId + '/environments/' + $scope.environmentId + '/service_pod_log/' + $scope.serviceId,
        responseType: 'text'
      }).then(function(response) {
        if (response.data) {
          $scope.serviceLog = response.data;
        }
      }, function(err) {
        console.log(err);
      });
    };

    $scope.addNewServiceVariableEntry = function() {
      $scope.serviceVariables.push({});
    };

    $scope.deleteServiceVariableEntry = function(index) {
      $scope.serviceVariables.splice(index, 1);

      if ($scope.serviceVariables.length < 1) {
        $scope.addNewServiceVariableEntry();
      }
    };

    // Initialisations
    getServiceCommands();
    getServiceVariables();
    getServiceInfo();
    getServiceLog();

    if($scope.serviceVariables.length < 1) {
      $scope.addNewServiceVariableEntry();
    }

  }]);

}());
