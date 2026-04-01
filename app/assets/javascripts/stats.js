/* global Plot */
(function() {
  "use strict";
  var buildGraph;

  function parseRows(graphData) {
    var rows = [];
    var dates = graphData.x || [];
    var seriesNames = Object.keys(graphData).filter(function(key) {
      return key !== "x";
    });

    seriesNames.forEach(function(seriesName) {
      var values = graphData[seriesName] || [];
      var maxLength = Math.min(dates.length, values.length);
      var i;

      for (i = 0; i < maxLength; i += 1) {
        if (values[i] === null || values[i] === undefined) {
          continue;
        }

        var parsedDate = new Date(dates[i]);
        var parsedValue = Number(values[i]);

        if (Number.isNaN(parsedDate.getTime()) || Number.isNaN(parsedValue)) {
          continue;
        }

        rows.push({
          date: parsedDate,
          value: parsedValue,
          series: seriesName
        });
      }
    });

    return {
      rows: rows,
      seriesNames: seriesNames
    };
  }

  function buildLegend(el, seriesNames, hiddenSeries, onToggle) {
    var legend = document.createElement("div");
    legend.className = "stats-graph-legend";

    seriesNames.forEach(function(seriesName) {
      var button = document.createElement("button");
      var isHidden = !!hiddenSeries[seriesName];

      button.type = "button";
      button.textContent = seriesName;
      button.className = "stats-graph-legend-item";
      button.setAttribute("aria-pressed", isHidden ? "false" : "true");
      button.style.opacity = isHidden ? "0.4" : "1";
      button.addEventListener("click", function() {
        onToggle(seriesName);
      });

      legend.appendChild(button);
    });

    return legend;
  }

  function renderGraph(el, state) {
    var visibleRows = state.rows.filter(function(row) {
      return !state.hiddenSeries[row.series];
    });
    var chartWidth = Math.max(el.clientWidth || 0, 320);
    var marks = [];
    var plot;

    if (visibleRows.length > 0) {
      marks.push(
        Plot.line(visibleRows, {
          x: "date",
          y: "value",
          stroke: "series"
        })
      );
      marks.push(
        Plot.dot(visibleRows, {
          x: "date",
          y: "value",
          stroke: "series",
          r: 2
        })
      );
      marks.push(
        Plot.tip(
          visibleRows,
          Plot.pointerX({
            x: "date",
            y: "value",
            stroke: "series",
            title: function(d) {
              return d.date.toISOString().slice(0, 10) + "\n" + d.series + ": " + d.value;
            }
          })
        )
      );
    }

    plot = Plot.plot({
      width: chartWidth,
      x: {
        type: "utc",
        tickFormat: "%Y-%m-%d"
      },
      y: {
        grid: true
      },
      color: {
        legend: false
      },
      marginLeft: 48,
      marks: marks
    });

    el.innerHTML = "";
    el.appendChild(plot);
    el.appendChild(
      buildLegend(el, state.seriesNames, state.hiddenSeries, function(seriesName) {
        state.hiddenSeries[seriesName] = !state.hiddenSeries[seriesName];
        renderGraph(el, state);
      })
    );
  }

  buildGraph = function(el) {
    var graphData = $(el).data("graph");
    var parsedData;
    var previousState = el._statsPlotState;
    var state;

    if (!previousState) {
      previousState = { hiddenSeries: {}};
    }

    if (!graphData || !graphData.x) {
      return;
    }

    parsedData = parseRows(graphData);
    state = {
      rows: parsedData.rows,
      seriesNames: parsedData.seriesNames,
      hiddenSeries: previousState.hiddenSeries
    };

    el._statsPlotState = state;
    renderGraph(el, state);
  };

  App.Stats = {
    initialize: function() {
      $("[data-graph]").each(function() {
        buildGraph(this);
      });

      if (!App.Stats._resizeBound) {
        var resizeTimer;
        App.Stats._resizeBound = true;
        $(window).on("resize", function() {
          window.clearTimeout(resizeTimer);
          resizeTimer = window.setTimeout(function() {
            $("[data-graph]").each(function() {
              buildGraph(this);
            });
          }, 120);
        });
      }
    }
  };
}).call(this);
