
#TODO: LEGENDS:
# see http://www.dashingd3js.com/svg-basic-shapes-and-d3js
# make 6 squares for each map in a separate svg within the same div
# probably better to have vertically-aligned.
# then update when the jenks breaks change

# Make legend 300w x 150h
# 6 divisions of 25px x 25px (plus text to the rigt)

LEGEND_SIZE = [120, 150]
LEGEND_BOX_SIZE = 25 # actually just do height/6

MAPS = {
    'chrg': {
        size: [400, 220]
        display: "Average Charge"
        value_fmt: d3.format('$,.0f')
        geo_path: null
        svg: null
        regions: null
        centered: null
        delay: 250
        leg_svg: null
    }
    'pmt': {
        size: [400, 220]
        display: "Average Payment"
        value_fmt: d3.format('$,.0f')
        geo_path: null
        svg: null
        regions: null
        centered: null
        delay: 250
        leg_svg: null
    }
    'reduct': {
        size: [600, 330]
        display: "Reduction"
        value_fmt: (x) -> return d3.format('.0f')(x) + '%'
        geo_path: null
        svg: null
        regions: null
        centered: null
        delay: 0
        leg_svg: null
    }

}

zoomMaps = (d) ->
    d3.map(MAPS).forEach (name, m) ->
        svg = m.svg

        width = m.size[0]
        height = m.size[1]
        geo_path = m.geo_path

        if d? and m.centered isnt d
            centroid = geo_path.centroid(d)
            x = centroid[0]
            y = centroid[1]
            k = 4
            m.centered = d

        else
            x = width/2
            y = height/2
            k = 1
            m.centered = null


        svg.selectAll("g").selectAll("path")
            .classed("active", m.centered and (d) -> 
                if not m.centered then return false

                if d is m.centered
                    return true

                if d.properties?.HRRNUM is m.centered.properties?.HRRNUM
                    return true

                return false
            )

        paths = svg.selectAll("g").selectAll("path")
        transition = paths.transition()
            .duration(750)
            .attr("transform", "translate(#{width/2},#{height/2})scale(#{k})translate(#{-x},#{-y})")
            .attr("stroke-width", 1/k+"px")
            .delay(m.delay)

    return


fetchAndUpdateRegions = (type, code) ->
    queue()
        .defer(d3.json, "data/procs/#{type}_#{code}_hrr.json")
        .await((err, pmt_info) ->
            if err then alert "Sorry, an error has occurred"
            updateRegions('chrg', pmt_info)
            updateRegions('pmt', pmt_info)
            updateRegions('reduct', pmt_info)
        )
    return

updateLegend = (name, breaks) ->
    svg = MAPS[name].leg_svg

    svg.selectAll('text').remove()

    for i in [5..0] by -1
        if i is 0 
            txt = "No data"
        else
            num = MAPS[name].value_fmt(breaks[i-1])
            txt = ">= #{num}"

        svg.append("text")
            .attr('x', 30)
            .attr('y', (Math.abs(i-5)+1) * 25 - 8)
            .text(txt)


    return

updateRegions = (name, pmt_info) ->
    #pmt_info is object of form {hrr_id: {chrg:, pmt:, reduct:}, ...}
    pmt_info_entries = d3.entries(pmt_info)

    regions = MAPS[name].regions

    vals = pmt_info_entries.map((d) -> Math.ceil(+d.value[name])+1)

    jenks_breaks = ss.jenks(vals, 4)
    jenks_breaks.unshift(0)

    #TODO: This is all screwed up!
    thresholds = d3.scale.threshold()
        .domain(jenks_breaks)
        .range(d3.range(6).map((i) -> "q#{i-1}-5"))

    updateLegend(name, jenks_breaks)

    regions.attr("class", (d) -> 
        if d.properties?.HRRNUM? and pmt_info[d.properties.HRRNUM]?
            return thresholds(pmt_info[d.properties.HRRNUM][name])
        return "empty"
    )

    regions.selectAll("title")
        .text((d) ->
            if d?.properties?
                txt = "HRR for #{d.properties.HRRCITY}"

                value_fmt = MAPS[name].value_fmt
                display_name = MAPS[name].display

                if pmt_info[d.properties.HRRNUM]?
                    n = value_fmt(pmt_info[d.properties.HRRNUM][name])
                    txt += "\n#{display_name}: #{n}"

                return txt

            return null
        )

    if MAPS[name].centered?
        d3.map(MAPS).forEach (n, m) ->
            m.svg.selectAll("g").selectAll("path")
                .classed("active", (d) ->
                    if d.properties?.HRRNUM is m.centered.properties?.HRRNUM
                        return true
                    return false
                )

    return


createMap = (name, hrr) ->

    width = MAPS[name].size[0]
    height = MAPS[name].size[1]

    projection = d3.geo.albersUsa()
        .scale(width+100)
        .translate([width / 2, height / 2])

    MAPS[name].geo_path = d3.geo.path().projection(projection)

    geo_path = MAPS[name].geo_path
    svg = MAPS[name].svg

    region_feats = topojson.feature(hrr, hrr.objects.HRR_Bdry).features

    regions = svg.append("g")
            .attr("class", "region hrr_#{name}")
            .selectAll("path")
                .data(region_feats)
                .enter()
                    .append("path")
                        .attr("d", geo_path)
                        .on("click", zoomMaps)

    regions.append("title")
        .text((d) ->
            if d?.properties?
                return "HRR for #{d.properties.HRRCITY}"
            return null
        )

    svg.append("g")
        .append("path")
            .datum(topojson.mesh(hrr, hrr.objects.HRR_Bdry))
            .attr("d", geo_path)
            .attr("class", "region_bdry")

    return regions

create_map_svg = (name, dom_id) ->
    
    w = MAPS[name].size[0]
    h = MAPS[name].size[1]
    
    svg = d3.select(dom_id).append('svg')
        .style('width', w)
        .style('height', h )

    return svg

create_legend_svg = (dom_id) ->
    w = LEGEND_SIZE[0]
    h = LEGEND_SIZE[1]

    svg = d3.select(dom_id).append('svg')
        .style('width', w)
        .style('height', h)

    for i in [0..5]
        cls = if i is 5 then 'empty' else "q#{Math.abs(i-5+1)}-5"

        svg.append("rect")
            .attr('x', 0)
            .attr('y', i * 25)
            .attr('width', 25)
            .attr('height', 25)
            .attr('class', cls)
    
    return svg

ready = (error, hrr) ->
    #Then have a method that uses the new data to change the colors.
    #The current operation is that the maps are completely recreated each time,
    # so we don't get any animation.

    MAPS.chrg.svg = create_map_svg('chrg', '#chrg_map')
    MAPS.pmt.svg = create_map_svg('pmt', '#pmt_map')
    MAPS.reduct.svg = create_map_svg('reduct', '#reduct_map')

    MAPS.chrg.leg_svg = create_legend_svg('#chrgLegend')
    MAPS.pmt.leg_svg = create_legend_svg('#pmtLegend')
    MAPS.reduct.leg_svg = create_legend_svg('#reductLegend')

    MAPS.chrg.regions = createMap('chrg', hrr)
    MAPS.pmt.regions = createMap('pmt', hrr)
    MAPS.reduct.regions = createMap('reduct', hrr)   

    $selectDrg = d3.select('#selectDrg')
    $selectDrgGroup = d3.select('#selectDrgGroup')
    $selectApc = d3.select('#selectApc')
    $selectApcGroup = d3.select('#selectApcGroup')

    $inpatientBtn = d3.select('#inpatientBtn')
    $outpatientBtn = d3.select('#outpatientBtn')

    $selectDrg.on("change", () ->
        drg_code = this.options[this.selectedIndex].value
        fetchAndUpdateRegions("drg", drg_code)
        return
    )

    $selectApc.on("change", () ->
        apc_code = this.options[this.selectedIndex].value
        fetchAndUpdateRegions("apc", apc_code)
        return
    )



    $inpatientBtn.on("click", () ->
        if $inpatientBtn.classed('pure-button-active') then return

        $outpatientBtn.classed('pure-button-active', false)
        $inpatientBtn.classed('pure-button-active', true)

        $selectDrgGroup.classed('hidden', false)
        $selectApcGroup.classed('hidden', true)

        $selectDrg.node().selectedIndex = 0
        fetchAndUpdateRegions("drg", $selectDrg.node().options[0].value)
        #$selectDrg.selectedIndex = 0
    )

    $outpatientBtn.on("click", () ->
        if $outpatientBtn.classed('pure-button-active') then return

        $inpatientBtn.classed('pure-button-active', false)
        $outpatientBtn.classed('pure-button-active', true)

        $selectApcGroup.classed('hidden', false)
        $selectDrgGroup.classed('hidden', true)

        $selectApc.node().selectedIndex = 0
        fetchAndUpdateRegions("apc", $selectApc.node().options[0].value)
    )

    fetchAndUpdateRegions("drg", $selectDrg.node().options[0].value)
    

    return


queue()
    .defer(d3.json, "data/hrr_sp007.topojson")
    .await(ready)



