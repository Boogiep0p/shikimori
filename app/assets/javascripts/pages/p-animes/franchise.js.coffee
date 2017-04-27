page_load 'animes_franchise', 'mangas_franchise', =>
  try
    ShikiMath.rspec()

    $graph = $('.graph')
    d3.json $graph.data('api-url'), (error, data) =>
      @franchise = new Franchise(data)
      @franchise.render_to $graph[0]

      $('.sticky-tooltip .close').on 'click', ->
        node = $('.node.selected')[0]
        d3.select(node).on('click')(node.__data__)

      #node = $(".node##{$graph.data 'id'}")[0]
      #d3.select(node).on('click')(node.__data__)

  catch e
    document.write e.message || e

class @FranchiseNode
  SELECT_SCALE = 2
  BORDER_OFFSET = 3

  constructor: (data, width, height) ->
    $.extend(@, data)

    @selected = false
    @fixed = false

    @init_w = @w = width
    @init_h = @h = height
    @_calc_rs()

  deselect: (bound_x, bound_y, tick) ->
    @selected = false
    @fixed = @pfixed

    #@_d3_kind().style display: 'none'
    @_hide_tooltip()
    @_animate(@init_w, @init_h, bound_x, bound_y, tick)

  select: (bound_x, bound_y, tick) ->
    @selected = true
    @pfixed = @fixed # prior fixed
    @fixed = true

    #@_d3_kind().style display: 'inline'
    @_load_tooltip()
    @_animate(@init_w * SELECT_SCALE, @init_h * SELECT_SCALE, bound_x, bound_y, tick)

  year_x: (w = @w) ->
    w - 2

  year_y: (h = @h) ->
    h - 2

  _calc_rs: ->
    @rx = @w / 2.0
    @ry = @h / 2.0

  _animate: (new_width, new_height, bound_x, bound_y, tick) ->
    if @selected
      io = d3.interpolate(0, BORDER_OFFSET)
      iw = d3.interpolate(@w, new_width)
      ih = d3.interpolate(@h, new_height)
      @_d3_node().attr class: 'node selected'
    else
      io = d3.interpolate(BORDER_OFFSET, 0)
      iw = d3.interpolate(@w - BORDER_OFFSET*2, new_width)
      ih = d3.interpolate(@h - BORDER_OFFSET*2, new_height)
      @_d3_node().attr class: 'node'

    @_d3_node()
      .transition()
      .duration(500)
      .tween 'animation', =>
        (t) =>
          #t = 1
          o = io(t)
          o2 = o*2
          w = iw(t)
          h = ih(t)

          width_increment = w + o2 - @w
          height_increment = h + o2 - @h

          #@x -= width_increment / 2.0
          #@px -= width_increment / 2.0
          #@y -= height_increment / 2.0
          #@py -= height_increment / 2.0

          @w += width_increment
          @h += height_increment

          @_calc_rs()

          outer_border_path = "M 0,0 #{w + o2},0 #{w + o2},#{h + o2} 0,#{h + o2} 0,0"

          @_d3_node().attr transform: "translate(#{bound_x(@) - @rx}, #{bound_y(@) - @ry})"
          @_d3_outer_border().attr d: outer_border_path
          @_d3_image_container().attr transform: "translate(#{o}, #{o})"
          @_d3_inner_border().attr d: "M 0,0 #{w},0 #{w},#{h} 0,#{h} 0,0"

          @_d3_image().attr width: w, height: h
          @_d3_year().attr x: @year_x(w), y: @year_y(h)
          #@_d3_kind().attr x: @year_x(w)
          tick()

  _hide_tooltip: ->
    $('.sticky-tooltip').hide()

  _load_tooltip: ->
    $('.sticky-tooltip').show().addClass('b-ajax')
    $.get(@url + '/tooltip').success (html) ->
      $('.sticky-tooltip').removeClass('b-ajax')
      $('.sticky-tooltip > .inner').html(html).process()

  _d3_node: ->
    @_node_elem ||= d3.select $(".node##{@id}")[0]

  _d3_image_container: ->
    @_image_container_elem ||= @_d3_node().selectAll('.image-container')

  _d3_image: ->
    @_image_elem ||= @_d3_node().selectAll('image')

  _d3_year: ->
    @_year_elem ||= @_d3_node().selectAll('.year')

  #_d3_kind: ->
    #@_kind_elem ||= @_d3_node().selectAll('.kind')

  _d3_outer_border: ->
    @_outer_border_elem ||= @_d3_node().selectAll('path.border_outer')

  _d3_inner_border: ->
    @_inner_border_elem ||= @_d3_node().selectAll('path.border_inner')


class @Franchise
  START_MARKERS = ['prequel']
  END_MARKERS = ['sequel']

  constructor: (data) ->
    # image sizes
    @image_w = 48
    @image_h = 75

    @links_data = data.links
    @nodes_data = data.nodes.map (data) => new FranchiseNode(data, @image_w, @image_h)

    @_prepare_data()
    @_position_nodes()
    @_prepare_force()

  _prepare_data: ->
    @max_weight = @links_data.map((v) -> v.weight).max() * 1.0
    @size = original_size = @nodes_data.length
    console.log "nodes: #{@size}, max_weight: #{@max_weight}"

    # screen sizes
    @w = if @size < 30
      @_scale @size,
        from_min: 0
        from_max: 30
        to_min: 480
        to_max: 1300
    else
      @_scale @size,
        from_min: 0
        from_max: 100
        to_min: 1300
        to_max: 2000
    @h = @w

    # dates for positioning on Y axis
    min_date = @nodes_data.map((v) -> v.date).min()
    max_date = @nodes_data.map((v) -> v.date).max()

    # do not use min/max dates if they belong to multiple entries
    if @nodes_data.filter((v) -> v.date == min_date).length == 1
      @min_date = min_date * 1.0
    if @nodes_data.filter((v) -> v.date == max_date).length == 1
      @max_date = max_date * 1.0

  # initial nodes positioning
  _position_nodes: ->
    # return unless @min_date && @max_date
    @nodes_data.each (d) =>
      d.y = @_y_by_date(d.date)
      d.x = @w / 2.0 - d.rx

      if d.date == @min_date
        d.fixed = true
        # move it proportionally to its relations count
        d.y += @_scale d.weight, from_min: 4, from_max: 20, to_min: 0, to_max: 700

      if d.date == @max_date
        d.fixed = true
        d.y -= 20
        # move it proportionally to its relations count
        d.y -= @_scale d.weight, from_min: 4, from_max: 9, to_min: 0, to_max: 150

  # configure d3 force object
  _prepare_force: ->
    window.d3_force = @d3_force = d3.layout.force()
      .charge (d) ->
        if d.selected
          -5000
        else if d.weight > 7
          -3000
        else if d.weight > 20
          -4000
        else
          -2000

      .friction 0.9
      .linkDistance (d) =>
        max_width = if @max_weight < 3
          @_scale @size, from_min: 2, from_max: 6, to_min: 100, to_max: 300
        else
          @_scale @max_weight, from_min: 30, from_max: 80, to_min: 300, to_max: 1500

        @_scale 300 * (d.weight / @max_weight),
          from_min: 0
          from_max: 300
          to_min: 150
          to_max: max_width

      .size([@w, @h])
      .nodes(@nodes_data)
      .links(@links_data)

  # scale X which expected to be in [from_min..from_max] to new value in [to_min...to_max]
  _scale: (x, opt) ->
    percent = (x - opt.from_min) / (opt.from_max - opt.from_min)
    percent = Math.min(1, Math.max(percent, 0))
    opt.to_min + (opt.to_max - opt.to_min) * percent

  # bound X coord to be within screen area
  _bound_x: (d, x = d.x) =>
    min = d.rx + 5
    max = @w - d.rx - 5
    Math.max(min, Math.min(max, x))

  # bound Y coord to be within screen area
  _bound_y: (d, y = d.y) =>
    min = d.ry + 5
    max = @w - d.ry - 5
    Math.max(min, Math.min(max, y))

  # determine Y coord by date (oldest to top, newest to bottom)
  _y_by_date: (date) =>
    @_scale date,
      from_min: @min_date
      from_max: @max_date
      to_min: @image_h / 2.0
      to_max: @h - @image_h / 2.0

  render_to: (target) ->
    @_append_svg target
    @_append_markers()
    @_append_links()
    @_append_nodes()

    @d3_force.start().on('tick', @_tick)
    @d3_force.tick() for i in [0..@size*@size]
    @d3_force.stop()

  # handler for node selection
  _node_selected: (d) =>
    if @selected_node
      @selected_node.deselect(@_bound_x, @_bound_y, @_tick)

      if @selected_node == d
        @selected_node = null
        return

    @selected_node = d
    @selected_node.select(@_bound_x, @_bound_y, @_tick)


  # svg tag
  _append_svg: (target) ->
    @d3_svg = d3.select(target)
      .append('svg')
      .attr width: @w, height: @h

  # lines between nodes
  _append_links: ->
    @d3_link = @d3_svg.append('svg:g').selectAll('.link')
      .data(@links_data)
      .enter().append('svg:path')
        .attr
          class: (d) -> 'link ' + d.relation
          'marker-start': (d) -> 'url(#' + d.relation + ')' if START_MARKERS.find(d.relation)
          'marker-end': (d) -> 'url(#' + d.relation + ')' if END_MARKERS.find(d.relation)
          'marker-mid': (d) -> 'url(#' + d.relation + '_label)'

  # nodes (images + borders + year)
  _append_nodes: ->
    @d3_node = @d3_svg.append('.svg:g').selectAll('.node')
      .data(@nodes_data)
      .enter().append('svg:g')
        .attr
          class: 'node'
          id: (d) -> d.id
        .call(@d3_force.drag()
          #.on('dragstart', -> $(@).children('text').hide())
          #.on('dragend', -> $(@).children('text').show())
        )
        .on 'click', (d) =>
          return if d3.event?.defaultPrevented
          @_node_selected(d)
        #.on 'mouseover', (d) ->
          #$(@).children('text').show()
        #.on 'mouseleave', (d) ->
          #$(@).children('text').hide()

    @d3_node.append('svg:path').attr(class: 'border_outer', d: "")
    @d3_image_container = @d3_node.append('svg:g').attr(class: 'image-container')

    @d3_image_container.append('svg:image')
      .attr
        width: @image_w
        height: @image_h
        'xlink:href': (d) -> d.image_url

    @d3_image_container.append('svg:path')
      .attr
        class: 'border_inner'
        d: (d) -> "M 0,0 #{d.w},0 #{d.w},#{d.h} 0,#{d.h} 0,0"

    # year
    @d3_image_container.append('svg:text')
      .attr
        x: (d) -> d.year_x()
        y: (d) -> d.year_y()
        class: 'year shadow'
      .text (d) -> d.year
    @d3_image_container.append('svg:text')
      .attr
        x: (d) -> d.year_x()
        y: (d) -> d.year_y()
        class: 'year'
      .text (d) -> d.year

    # kind
    #@d3_image_container.append('svg:text')
      #.attr x: @image_w - 2, y: 0 , class: 'kind shadow'
      #.text (d) -> d.kind
    #@d3_image_container.append('svg:text')
      #.attr x: @image_w - 2, y: 0, class: 'kind'
      #.text (d) -> d.kind

  # markers for links between nodes
  _append_markers: ->
    @d3_defs = @d3_svg.append('svg:defs')

    # arrow size
    aw = 8
    @d3_defs.append('svg:marker')
      .attr
        id: 'sequel', orient: 'auto'
        refX: aw, refY: aw/2, markerWidth: aw, markerHeight: aw
        stroke: '#123', fill: '#333'
      .append('svg:polyline').attr(points: "0,0 #{aw},#{aw/2} 0,#{aw} #{aw/4},#{aw/2} 0,0")
    @d3_defs.append('svg:marker')
      .attr
        id: 'prequel', orient: 'auto'
        refX: 0, refY: aw/2, markerWidth: aw, markerHeight: aw
        stroke: '#123', fill: '#333'
      .append('svg:polyline').attr(points: "#{aw},#{aw} 0,#{aw/2} #{aw},0 #{aw*3/4},#{aw/2} #{aw},#{aw}")

    #@d3_svg.append('svg:defs').selectAll('marker')
        #.data(['sequel', 'prequel'])
      #.enter().append('svg:marker')
        #.attr
          #refX: 10, refY: 0
          #id: String,
          #markerWidth: 6, markerHeight: 6, orient: 'auto'
          #stroke: '#123', fill: '#123'
          #viewBox: '0 -5 10 10'
      #.append('svg:path')
        #.attr
          #d: (d) ->
            #if START_MARKERS.find(d)
              #"M10,-5L0,0L10,5"
            #else
              #"M0,-5L10,0L0,5"

  # move nodes and links accordingly to coords calculated by d3.force
  _tick: =>
    @d3_node.attr
      transform: (d) =>
        "translate(#{@_bound_x(d) - d.rx}, #{@_bound_y(d) - d.ry})"

    @d3_link.attr
      d: @_link_truncated

    # collistion detection between nodes
    @d3_node.each(@_collide(0.5))

  # math for obtaining coords for links between rectangular nodes
  _link_truncated: (d) =>
    return unless d.source.id < d.target.id

    rx1 = d.source.rx
    ry1 = d.source.ry

    rx2 = d.target.rx
    ry2 = d.target.ry

    x1 = @_bound_x(d.source)
    y1 = @_bound_y(d.source)

    x2 = @_bound_x(d.target)
    y2 = @_bound_y(d.target)

    coords = ShikiMath.square_cutted_line x1,y1, x2,y2, rx1,ry1, rx2,ry2

    if !Object.isNaN(coords.x1) && !Object.isNaN(coords.y1) &&
         !Object.isNaN(coords.x2) && !Object.isNaN(coords.y2)
      "M#{coords.x1},#{coords.y1} L#{coords.x2},#{coords.y2}"
    else
      "M#{x1},#{y1} L#{x2},#{y2}"

  # math for collision detection. originally it was designed for circle
  # nodes so it is not absolutely accurate for rectangular nodes
  _collide: (alpha) =>
    quadtree = d3.geom.quadtree(@nodes_data)

    (d) =>
      nx1 = d.x - d.w
      nx2 = d.x + d.w

      ny1 = d.y - d.h
      ny2 = d.y + d.h

      quadtree.visit (quad, x1, y1, x2, y2) =>
        if quad.point && quad.point != d
          rb = Math.max(d.rx + quad.point.rx, d.ry + quad.point.ry) * 1.15

          x = d.x - quad.point.x
          y = d.y - quad.point.y
          l = Math.sqrt(x * x + y * y)

          if l < rb && l != 0
            l = (l - rb) / l * alpha

            x *= l
            y *= l

            d.x = @_bound_x(d, d.x - x)
            d.y = @_bound_y(d, d.y - y)
            quad.point.x = @_bound_x(quad.point, quad.point.x + x)
            quad.point.y = @_bound_y(quad.point, quad.point.y + y)

        x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1

# some math that i use for graph calculations
class @ShikiMath
  # detecting whether point is above or below a line
  # x,y - point
  # x1,y1 - point 1 of line
  # x2,y2 - point 2 of line
  @is_above: (x,y, x1,y1, x2,y2) ->
    dx = x2 - x1
    dy = y2 - y1

    dy*x - dx*y + dx*y1 - dy*x1 <= 0

  # detecting in which "sector" point x2,y2 is located accordingly to
  # rectangular node with center in x1,y1 and width=rx*2 and height=ry*2
  @sector: (x1,y1, x2,y2, rx,ry) ->
    # left_bottom to right_top
    lb_to_rt = @is_above x2,y2, x1-rx,y1-ry,x1,y1
    # left_top to right_bottom
    lt_to_rb = @is_above x2,y2, x1-rx,y1+ry,x1,y1

    if lb_to_rt && lt_to_rb
      'top'
    else if !lb_to_rt && lt_to_rb
      'right'
    else if !lb_to_rt && !lt_to_rb
      'bottom'
    else
      'left'

  # math for obtaining coords for link between two rectangular nodes
  # with center in xN,yN and width=rxN*2 and height=ryN*2
  @square_cutted_line: (x1,y1, x2,y2, rx1,ry1, rx2,ry2) ->
    dx = x2 - x1
    dy = y2 - y1

    y = (x) -> (dy*x + dx*y1 - dy*x1) / dx
    x = (y) -> (dx*y - dx*y1 + dy*x1) / dy

    target_sector = @sector x1,y1, x2,y2, rx1,ry1

    if target_sector == 'right'
      f_x1 = x1 + rx1
      f_y1 = y(f_x1)

      f_x2 = x2 - rx2
      f_y2 = y(f_x2)

    else if target_sector == 'left'
      f_x1 = x1 - rx1
      f_y1 = y(f_x1)

      f_x2 = x2 + rx2
      f_y2 = y(f_x2)

    if target_sector == 'top'
      f_y1 = y1 + ry1
      f_x1 = x(f_y1)

      f_y2 = y2 - ry2
      f_x2 = x(f_y2)

    if target_sector == 'bottom'
      f_y1 = y1 - ry1
      f_x1 = x(f_y1)

      f_y2 = y2 + ry2
      f_x2 = x(f_y2)

    x1: f_x1
    y1: f_y1
    x2: f_x2
    y2: f_y2
    sector: target_sector

  # tests for math
  @rspec: ->
    # is_above
    @_assert true, @is_above(-1,2, -1,-1, 1,1)
    @_assert true, @is_above(0,2, -1,-1, 1,1)
    @_assert true, @is_above(0,0, -1,-1, 1,1)
    @_assert true, @is_above(1,2, -1,-1, 1,1)
    @_assert false, @is_above(2,1, -1,-1, 1,1)
    @_assert false, @is_above(-1,-2, -1,-1, 1,1)

    # sector test
    @_assert 'top', @sector(0,0, 0,10, 1,1)
    @_assert 'top', @sector(0,0, 10,10, 1,1)
    @_assert 'right', @sector(0,0, 10,0, 1,1)
    @_assert 'right', @sector(0,0, 10,-10, 1,1)
    @_assert 'bottom', @sector(0,0, 0,-10, 1,1)
    @_assert 'left', @sector(0,0, -10,0, 1,1)

    # square_cutted_line
    @_assert {x1: -9, y1: 0, x2: 9, y2: 0, sector: 'right'}, @square_cutted_line(-10,0, 10,0, 1,1, 1,1)
    @_assert {x1: 5, y1: 0, x2: -5, y2: 0, sector: 'left'}, @square_cutted_line(10,0, -10,0, 5,1, 5,1)
    @_assert {x1: 0, y1: 5, x2: 0, y2: -5, sector: 'bottom'}, @square_cutted_line(0,10, 0,-10, 1,5, 1,5)
    @_assert {x1: 0, y1: -5, x2: 0, y2: 5, sector: 'top'}, @square_cutted_line(0,-10, 0,10, 1,5, 1,5)

    @_assert {x1: 5, y1: 5, x2: -5, y2: -5, sector: 'left'}, @square_cutted_line(10,10, -10,-10, 5,5, 5,5)
    @_assert {x1: 0.5, y1: 1, x2: 1.5, y2: 3, sector: 'top'}, @square_cutted_line(0,0, 2,4, 1,1, 1,1)

  @_assert: (left, right) ->
    unless JSON.stringify(left) == JSON.stringify(right)
      throw "math error: expected #{JSON.stringify left}, got #{JSON.stringify right}"
