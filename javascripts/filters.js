document$.subscribe(function() {
  var tables = document.querySelectorAll("article table:not([class])");
  
  tables.forEach(function(table) {

      $(table).tablesorter({
          theme: 'blue',
          widthFixed : true,
          widgets: ["zebra", "filter"],
          widgetOptions : {
              filter_cssFilter   : '',
              filter_childRows   : false,
              filter_hideFilters : false,
              filter_ignoreCase  : true,
              filter_reset : '.reset',
              filter_saveFilters : true,
              filter_searchDelay : 300,
              filter_startsWith  : false,
              
              // add your other options here...
          }
      });

  });
})
