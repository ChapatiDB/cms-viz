


#TODO:
# - some features showing up black - what does this mean? that it is not classified? 
#    or out of classification range?

# - click to zoom: http://bl.ocks.org/mbostock/2206590
#   when click one map's feature, zoom all maps

width = 800
height = 600

color = d3.scale.category10()

projection = d3.geo.albersUsa()
    .scale(800)
    .translate([width / 2, height / 2])

path = d3.geo.path().projection(projection)
svg1 = d3.select("#map1").append("svg")
    .style("width", width)
    .style("height", height)

svg2 = d3.select("#map2").append("svg")
    .style("width", width)
    .style("height", height)

svg3 = d3.select("#map3").append("svg")
    .style("width", width)
    .style("height", height)


centered = null
regions_by_charge = null
regions_by_pmt = null
regions_by_reduct = null



ready = (error, hrr, pmt_info) ->
    #pi is object of form form {hrr_id: {chrg:, pmt:, reduct:}, ...}

    regions = topojson.feature(hrr, hrr.objects.hrr).features

    pmt_info_entries = d3.entries(pmt_info)

    scales = {}
    scales.charge = {}
    scales.charge.jenks = d3.scale.threshold()
        .domain(ss.jenks(pmt_info_entries.map((d) -> +d.value.chrg), 9))
        .range(d3.range(9).map((i) -> "q#{i}-9" ))



    regions_by_charge = svg1.append("g")
            .attr("class", "hrr_charge")
            .selectAll("path")
                .data(regions)
                .enter()
                    .append("path")
                    .attr("d", path)

    regions_by_charge
        .attr("class", (d) -> 
            if d.properties?.HRRNUM? and pmt_info[d.properties.HRRNUM]?
                return scales.charge.jenks(pmt_info[d.properties.HRRNUM]['chrg'])
            return "empty"
        )

    svg1.append("path")
        .datum(topojson.mesh(hrr, hrr.objects.hrr))
        .attr("class", "region")
        .attr("d", path)


    # ----------------------------------

    scales.payment = {}
    scales.payment.jenks = d3.scale.threshold()
        .domain(ss.jenks(pmt_info_entries.map((d) -> +d.value.pmt), 9))
        .range(d3.range(9).map((i) -> "q#{i}-9" ))

    regions_by_pmt = svg2.append("g")
            .attr("class", "hrr_pmt")
            .selectAll("path")
                .data(regions)
                .enter()
                    .append("path")
                    .attr("d", path)

    regions_by_pmt
        .attr("class", (d) -> 
            if d.properties?.HRRNUM? and pmt_info[d.properties.HRRNUM]?
                return scales.payment.jenks(pmt_info[d.properties.HRRNUM]['pmt'])
            return "empty"
        )

    svg2.append("path")
        .datum(topojson.mesh(hrr, hrr.objects.hrr))
        .attr("class", "region")
        .attr("d", path)

    # ----------------------------------

    scales.reduct = {}
    scales.reduct.jenks = d3.scale.threshold()
        .domain(ss.jenks(pmt_info_entries.map((d) -> +d.value.reduct), 9))
        .range(d3.range(9).map((i) -> "q#{i}-9" ))

    regions_by_reduct = svg3.append("g")
            .attr("class", "hrr_reduct")
            .selectAll("path")
                .data(regions)
                .enter()
                    .append("path")
                    .attr("d", path)
                    .on("click", clicked)

    regions_by_reduct
        .attr("class", (d) -> 
            if d.properties?.HRRNUM? and pmt_info[d.properties.HRRNUM]?
                return scales.reduct.jenks(pmt_info[d.properties.HRRNUM]['reduct'])
            return "empty"
        )

    svg3.append("path")
        .datum(topojson.mesh(hrr, hrr.objects.hrr))
        .attr("class", "region")
        .attr("d", path)

    return




clicked = (d) ->
    if d? and centered isnt d
        centroid = path.centroid(d)
        x = centroid[0]
        y = centroid[1]
        k = 4
        centered = d
    else
        x = width/2
        y = height/2
        k = 1
        centered = null

    regions_by_reduct.selectAll("path")
        .classed("active", centered and (d) -> return d is centered )

    regions_by_reduct.transition()
        .duration(750)
        .attr("transform", "translate(#{width/2},#{height/2})scale(#{k})translate(#{-x},#{-y})")
        .attr("stroke-width", 1.5/k+"px")

    #modify - need to move all three maps
    # including the meshes.  just do different selection by each svg

    return

queue()
    .defer(d3.json, "data/hrr.topojson")
    #TODO: load this based on select box (but start with some default)
    .defer(d3.json, "data/procs/drg_948_hrr.json")
    .await(ready)



