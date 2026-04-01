//= require d3/dist/d3
//= require @observablehq/plot/dist/plot.umd.min
//= require stats

var initialize_stats_modules = function() {
  "use strict";

  App.Stats.initialize();
};

$(document).on("turbolinks:load", initialize_stats_modules);
$(document).on("ajax:complete", initialize_stats_modules);
