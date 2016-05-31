(function() {
  // Load google charts
  google.charts.load('current', {'packages':['corechart']});

  // Form event handler
  document.getElementById("get-tweets").addEventListener("submit", function(event) {
    event.preventDefault();

    var xmlhttp;

    if (window.XMLHttpRequest) {
      // code for IE7+, Firefox, Chrome, Opera, Safari
      xmlhttp = new XMLHttpRequest();
    } else {
      // code for IE6, IE5
      xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
    }

    xmlhttp.onreadystatechange = function() {
      if (xmlhttp.readyState == XMLHttpRequest.DONE ) {
        var error = '';
        if(xmlhttp.status == 200){
          var data = JSON.parse(xmlhttp.responseText);
          console.log(data);

          // Check for errors
          if (!!data.error) {
            error = data.error
          }
          else {
            // Prepare the data
            var values = [['Month', 'Tweets']];

            // Fill values with the results of the ajax request
            for (month in data) {
              var date = new Date(month);
              values.push([(date.getMonth()+1)+'/'+date.getFullYear(), data[month]]);
            }

            // Create the chart
            showChart(values);
          }

        }
        else {
          error = "Bad request"
        }

        // If we got any erros, show the error
        if (!!error) {
          document.getElementById("wrapper").innerHTML = '<h1>An error occurred</h1><p>'+error+'</p>';
        }
      }
    };

    // get the screen name from the input and prepare the request
    var screenName = encodeURIComponent(document.getElementById("screen-name").value);
    var params = "screen_name="+screenName;

    // Make the ajax request to get the results
    xmlhttp.open("POST", "/get_tweets_last_six_months", true);
    xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
    xmlhttp.send(params);
  });

// Function to create and show the chart with the results
function showChart(values) {
  document.getElementById("wrapper").innerHTML = '<h1>Tweets in the last 6 months</h1><div id="chart_div" style="width: 900px; height: 500px;"></div>';

  google.charts.setOnLoadCallback(drawChart);
  function drawChart() {
    var data = google.visualization.arrayToDataTable(values);

    var options = {
      title: 'Tweet in the last 6 months',
      hAxis: {title: 'Month'},
      vAxis: {minValue: 0}
    };

    var chart = new google.visualization.AreaChart(document.getElementById('chart_div'));
    chart.draw(data, options);
  }
}
})();