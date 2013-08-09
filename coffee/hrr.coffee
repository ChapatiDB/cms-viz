


#TODO:
#  - Simplify the HRR boundaries even more


width = 400
height = 300

color = d3.scale.category10()

projection = d3.geo.albersUsa()
    .scale(500)
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

create_map = (name, svg, hrr, pmt_info) ->

    regions = topojson.feature(hrr, hrr.objects.hrr).features

    pmt_info_entries = d3.entries(pmt_info)

    jenks_breaks = d3.scale.threshold()
        .domain(ss.jenks(pmt_info_entries.map((d) -> +d.value[name]), 5))
        .range(d3.range(5).map((i) -> "q#{i}-5" ))

    regions = svg.append("g")
            .attr("class", "hrr_#{name}")
            .selectAll("path")
                .data(regions)
                .enter()
                    .append("path")
                    .attr("d", path)
                    .on("click", clicked)

    regions
        .attr("class", (d) -> 
            if d.properties?.HRRNUM? and pmt_info[d.properties.HRRNUM]?
                return jenks_breaks(pmt_info[d.properties.HRRNUM][name])
            return "empty"
        )

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


    moveMap = (svg) ->
        svg.selectAll("g").selectAll("path")
            .classed("active", centered and (d) -> return d is centered )

        svg.selectAll("g").selectAll("path")
            .transition()
                .duration(750)
                .attr("transform", "translate(#{width/2},#{height/2})scale(#{k})translate(#{-x},#{-y})")
                .attr("stroke-width", 1.5/k+"px")
        return

    moveMap(svg1)
    moveMap(svg2)
    moveMap(svg3)
    return


ready = (error, hrr, pmt_info) ->
    #pi is object of form form {hrr_id: {chrg:, pmt:, reduct:}, ...}
    
    regions = topojson.feature(hrr, hrr.objects.hrr).features

    pmt_info_entries = d3.entries(pmt_info)

    create_map('chrg', svg1, hrr, pmt_info)
    create_map('pmt', svg2, hrr, pmt_info)
    create_map('reduct', svg3, hrr, pmt_info)    

    return


queue()
    .defer(d3.json, "data/hrr.topojson")
    #TODO: load this based on select box (but start with some default)
    .defer(d3.json, "data/procs/drg_948_hrr.json")
    .await(ready)



