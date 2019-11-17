/*
  JavaScript for Stata Highcharts Creator
  Ben Southgate (bsouthga@gmail.com)
  08/20/14
*/

$(document).ready(function() {

  var dataArr = csvToArray(stataHC.data);

  // only keep observations that aren't 
  var data =  [];
  for (var r=0, l=dataArr.length; r<l;r++) {
    var add = true;
    for (var v in dataArr[r]) {
      if (
        dataArr[r][v] === undefined || 
        dataArr[r][v] === ""
      ) {
        add = false;
      }
    }
    if (add) data.push(dataArr[r]);
  }

  var series = genSeriesList(data, stataHC.y_variables);

  var x_val_formatter = function(x) {
    return (stataHC.date ? Highcharts.dateFormat('%a %d %b', x) : x);
  }

  var formatter;
  if (stataHC.y_variables.length > 1 && stataHC.type === "line") {
    formatter = function () {
          var s = '<b>' + stataHC.x_var + " : " + x_val_formatter(this.x) + '</b>';
          $.each(this.points, function () {
              s += '<br/>' + this.series.name + ': ' + this.y;
          });
          return s;
      }
  } else {
    formatter = function () {
          var name = (
            this.name || 
            (this.series ? this.series.name :null ) || 
            (this.points && this.points.series ? this.points.series.name : null )
          );
          return '<b>'+ stataHC.x_var + " : " + x_val_formatter(this.x) + '</b><br/>' + name + ': ' + this.y;
      }    
  }


  $('#chart').highcharts({
    "chart" : {
      "zoomType" : 'xy',
      "type" : stataHC.type
    },
    "title" : {
      "text" : stataHC.title
    },
    "series" : series,
    "yAxis" : {
      "title" : {
        "text" : stataHC.yTitle || (stataHC.y_variables.length === 1 ? stataHC.y_variables[0] : undefined)
      }
    },
    "xAxis": (
      stataHC.date ? 
      {
        type: 'datetime',
        title: { text: stataHC.yTitle || 'Date'}
      } : 
      {
        title: { text: stataHC.yTitle || stataHC.x_var}
      }
    ),
    "tooltip" : {
      "shared" : (stataHC.y_variables.length > 1),
      formatter: formatter
    },
    "plotOptions" : {
      "line" : {
        "marker" : {"enabled" : false}
      }
    }
  });         
})

function commas(number) {
  var negative=(number<0);
  number=Math.abs(number);
  var rounded=Math.round(number),n_str=(''+rounded),ln=n_str.length,output='';
  if ( n_str.indexOf("e") !=- 1) return n_str;
  for ( var i=1;i<=ln;i++)output=(i%3==0&&i!=ln?",":"")+n_str.charAt(ln-i)+output;
  return(negative?'-':'')+output;
}

function genSeriesList(data, y) {
  var series = [];
  for (var i=0, l=y.length; i<l; i++) {
    series.push({
      "name" : y[i],
      "data" : HCSeries(data, stataHC.x_var, y[i])
    });
  }
  return series;
}

function HCSeries(data, x_var, y_var) {
  var out = [];
  var converter = function(v) {
    if (stataHC.date) {
      return new Date(v);
    } else {
      return parseFloat(v);
    }
  };
  for (var i=0, l=data.length;i<l;i++) {
    out.push((function(i) {
      return {
        "x" : converter(data[i][x_var]), 
        "y" : parseFloat(data[i][y_var]), 
        name : (stataHC.byvar ? data[i][stataHC.byvar] : undefined)
      }
    })(i));
  }
  return out.sort(function(a,b) {return (a.x > b.x) - (a.x < b.x)});
}

// CSV string parser to list of objects
// ref: http://stackoverflow.com/a/1293163/2343
function csvToArray( strData, strDelimiter ){
  strDelimiter = (strDelimiter || ",");
  var objPattern = new RegExp(
    (
      // Delimiters.
      "(\\" + strDelimiter + "|\\r?\\n|\\r|^)" +
      // Quoted fields.
      "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +
      // Standard fields.
      "([^\"\\" + strDelimiter + "\\r\\n]*))"
    ),
    "gi"
    );
  var arrData = [[]];
  var arrMatches = null;
  while (arrMatches = objPattern.exec( strData )){
    // Get the delimiter that was found.
    var strMatchedDelimiter = arrMatches[ 1 ];
    // Check to see if the given delimiter has a length
    // (is not the start of string) and if it matches
    // field delimiter. If id does not, then we know
    // that this delimiter is a row delimiter.
    if (
      strMatchedDelimiter.length &&
      strMatchedDelimiter !== strDelimiter
      ){
      // Since we have reached a new row of data,
      // add an empty row to our data array.
      arrData.push( [] );
    }
    var strMatchedValue;
    // Now that we have our delimiter out of the way,
    // let's check to see which kind of value we
    // captured (quoted or unquoted).
    if (arrMatches[ 2 ]){
      // We found a quoted value. When we capture
      // this value, unescape any double quotes.
      strMatchedValue = arrMatches[ 2 ].replace(
        new RegExp( "\"\"", "g" ),
        "\""
        );

    } else {
      // We found a non-quoted value.
      strMatchedValue = arrMatches[ 3 ];
    }
    // Now that we have our value string, let's add
    // it to the data array.
    arrData[ arrData.length - 1 ].push( strMatchedValue );
  }
  var headers = arrData[0];
  var output = [];
  for (var i=1,l=arrData.length;i<l;i++) {
    var row = {};
    for (var j=0,m=headers.length;j<m;j++) {
      row[headers[j]] = arrData[i][j];
    }
    output.push(row)
  }
  // Return the parsed data.
  return( output );
}



