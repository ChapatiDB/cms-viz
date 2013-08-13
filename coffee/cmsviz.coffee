
WIDTH = 400
HEIGHT = 300

projection = d3.geo.albersUsa()
    .scale(500)
    .translate([WIDTH / 2, HEIGHT / 2])

path = d3.geo.path().projection(projection)
svg1 = d3.select("#map1").append("svg")
    .style("width", WIDTH)
    .style("height", HEIGHT)

svg2 = d3.select("#map2").append("svg")
    .style("width", WIDTH)
    .style("height", HEIGHT)

svg3 = d3.select("#map3").append("svg")
    .style("width", WIDTH)
    .style("height", HEIGHT)

chrg_regions = null
pmt_regions = null
reduct_regions = null

centered = null



createMap = (name, svg, hrr) ->

    region_feats = topojson.feature(hrr, hrr.objects.HRR_Bdry).features

    regions = svg.append("g")
            .attr("class", "region hrr_#{name}")
            .selectAll("path")
                .data(region_feats)
                .enter()
                    .append("path")
                    .attr("d", path)
                    .on("click", zoomToRegions)

    svg.append("g")
        .append("path")
            .datum(topojson.mesh(hrr, hrr.objects.HRR_Bdry))
            .attr("d", path)
            .attr("class", "region_bdry")

    return regions

fetchAndUpdateRegions = (type, code) ->
    queue()
        .defer(d3.json, "data/procs/#{type}_#{code}_hrr.json")
        .await((err, pmt_info) ->
            
            updateRegions('chrg', chrg_regions, pmt_info)
            updateRegions('pmt', pmt_regions, pmt_info)
            updateRegions('reduct', reduct_regions, pmt_info)
        )
    return

updateRegions = (name, regions, pmt_info) ->
    #pmt_info is object of form {hrr_id: {chrg:, pmt:, reduct:}, ...}
    pmt_info_entries = d3.entries(pmt_info)

    jenks_breaks = d3.scale.threshold()
        .domain(ss.jenks(pmt_info_entries.map((d) -> +d.value[name]), 5))
        .range(d3.range(5).map((i) -> "q#{i}-5" ))

    regions.attr("class", (d) -> 
        if d.properties?.HRRNUM? and pmt_info[d.properties.HRRNUM]?
            return jenks_breaks(pmt_info[d.properties.HRRNUM][name])
        return "empty"
    )

    #need to update selected region with "active" class
    if centered?
        for svg in [svg1, svg2, svg3]
            svg.selectAll("g").selectAll("path")
                .classed("active", (d) ->
                    if d.properties?.HRRNUM is centered.properties?.HRRNUM
                        return true
                    return false
                )

    return

zoomToRegions = (d) ->
    if d? and centered isnt d
        centroid = path.centroid(d)
        x = centroid[0]
        y = centroid[1]
        k = 4
        centered = d

    else
        x = WIDTH/2
        y = HEIGHT/2
        k = 1
        centered = null


    moveMap = (svg, delay=0) ->
        svg.selectAll("g").selectAll("path")
            .classed("active", centered and (d) -> 
                if not centered then return false

                if d is centered
                    return true

                if d.properties?.HRRNUM is centered.properties?.HRRNUM
                    return true

                return false
            )

        paths = svg.selectAll("g").selectAll("path")
        transition = paths.transition()
            .duration(750)
            .attr("transform", "translate(#{WIDTH/2},#{HEIGHT/2})scale(#{k})translate(#{-x},#{-y})")
            .attr("stroke-width", 1.5/k+"px")
            .delay(delay)

        return transition

    moveMap(svg1)
    moveMap(svg2, 250)
    moveMap(svg3, 500)
    return



ready = (error, hrr) ->

    #TODO: Rewrite so that the maps are first created with the regions
    # and colored all gray

    #Then have a method that uses the new data to change the colors.
    #The current operation is that the maps are completely recreated each time,
    # so we don't get any animation.

    chrg_regions = createMap('chrg', svg1, hrr)
    pmt_regions = createMap('pmt', svg2, hrr)
    reduct_regions = createMap('reduct', svg3, hrr)   

    d3.select('#selectDrg').on("change", () ->
        drg_code = this.options[this.selectedIndex].value
        fetchAndUpdateRegions("drg", drg_code)
        return
    )

    d3.select('#selectApc').on("change", () ->
        apc_code = this.options[this.selectedIndex].value
        fetchAndUpdateRegions("apc", apc_code)
        return
    )

    fetchAndUpdateRegions("drg", 39)
    

    return



queue()
    .defer(d3.json, "data/hrr_sp007.topojson")
    .await(ready)



