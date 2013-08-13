(function() {
  var HEIGHT, WIDTH, centered, chrg_regions, createMap, fetchAndUpdateRegions, path, pmt_regions, projection, ready, reduct_regions, svg1, svg2, svg3, updateRegions, zoomToRegions;

  WIDTH = 400;

  HEIGHT = 300;

  projection = d3.geo.albersUsa().scale(500).translate([WIDTH / 2, HEIGHT / 2]);

  path = d3.geo.path().projection(projection);

  svg1 = d3.select("#map1").append("svg").style("width", WIDTH).style("height", HEIGHT);

  svg2 = d3.select("#map2").append("svg").style("width", WIDTH).style("height", HEIGHT);

  svg3 = d3.select("#map3").append("svg").style("width", WIDTH).style("height", HEIGHT);

  chrg_regions = null;

  pmt_regions = null;

  reduct_regions = null;

  centered = null;

  createMap = function(name, svg, hrr) {
    var region_feats, regions;
    region_feats = topojson.feature(hrr, hrr.objects.HRR_Bdry).features;
    regions = svg.append("g").attr("class", "region hrr_" + name).selectAll("path").data(region_feats).enter().append("path").attr("d", path).on("click", zoomToRegions);
    svg.append("g").append("path").datum(topojson.mesh(hrr, hrr.objects.HRR_Bdry)).attr("d", path).attr("class", "region_bdry");
    return regions;
  };

  fetchAndUpdateRegions = function(type, code) {
    queue().defer(d3.json, "data/procs/" + type + "_" + code + "_hrr.json").await(function(err, pmt_info) {
      updateRegions('chrg', chrg_regions, pmt_info);
      updateRegions('pmt', pmt_regions, pmt_info);
      return updateRegions('reduct', reduct_regions, pmt_info);
    });
  };

  updateRegions = function(name, regions, pmt_info) {
    var jenks_breaks, pmt_info_entries;
    pmt_info_entries = d3.entries(pmt_info);
    jenks_breaks = d3.scale.threshold().domain(ss.jenks(pmt_info_entries.map(function(d) {
      return +d.value[name];
    }), 5)).range(d3.range(5).map(function(i) {
      return "q" + i + "-5";
    }));
    regions.attr("class", function(d) {
      var _ref;
      if ((((_ref = d.properties) != null ? _ref.HRRNUM : void 0) != null) && (pmt_info[d.properties.HRRNUM] != null)) {
        return jenks_breaks(pmt_info[d.properties.HRRNUM][name]);
      }
      return "empty";
    });
  };

  zoomToRegions = function(d) {
    var centroid, k, moveMap, x, y;
    if ((d != null) && centered !== d) {
      centroid = path.centroid(d);
      x = centroid[0];
      y = centroid[1];
      k = 4;
      centered = d;
    } else {
      x = WIDTH / 2;
      y = HEIGHT / 2;
      k = 1;
      centered = null;
    }
    moveMap = function(svg, delay) {
      var paths, transition;
      if (delay == null) {
        delay = 0;
      }
      svg.selectAll("g").selectAll("path").classed("active", centered && function(d) {
        var _ref, _ref1;
        if (!centered) {
          return false;
        }
        if (d === centered) {
          return true;
        }
        if (((_ref = d.properties) != null ? _ref.HRRNUM : void 0) === ((_ref1 = centered.properties) != null ? _ref1.HRRNUM : void 0)) {
          return true;
        }
        return false;
      });
      paths = svg.selectAll("g").selectAll("path");
      transition = paths.transition().duration(750).attr("transform", "translate(" + (WIDTH / 2) + "," + (HEIGHT / 2) + ")scale(" + k + ")translate(" + (-x) + "," + (-y) + ")").attr("stroke-width", 1.5 / k + "px").delay(delay);
      return transition;
    };
    moveMap(svg1);
    moveMap(svg2, 250);
    moveMap(svg3, 500);
  };

  ready = function(error, hrr) {
    chrg_regions = createMap('chrg', svg1, hrr);
    pmt_regions = createMap('pmt', svg2, hrr);
    reduct_regions = createMap('reduct', svg3, hrr);
    d3.select('#selectDrg').on("change", function() {
      var drg_code;
      drg_code = this.options[this.selectedIndex].value;
      fetchAndUpdateRegions("drg", drg_code);
    });
    d3.select('#selectApc').on("change", function() {
      var apc_code;
      apc_code = this.options[this.selectedIndex].value;
      fetchAndUpdateRegions("apc", apc_code);
    });
    fetchAndUpdateRegions("drg", 39);
  };

  queue().defer(d3.json, "data/hrr_sp007.topojson").await(ready);

}).call(this);
