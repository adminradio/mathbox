Primitive = require '../../primitive'
Source    = require '../source'
Util      = require '../../../util'

class Vector extends Primitive
  @traits: ['node', 'object', 'style', 'line', 'arrow', 'geometry', 'position', 'bind']

  constructor: (model, attributes, renderables, shaders, helpers) ->
    super model, attributes, renderables, shaders, helpers

    @line = @arrows = null

  resize: () ->
    return unless @line and @bind.points
    dims = @bind.points.getActive()

    samples = dims.items
    strips  = dims.width
    ribbons = dims.height
    layers  = dims.depth

    @line.geometry.clip samples, strips, ribbons, layers
    arrow.geometry.clip samples, strips, ribbons, layers for arrow in @arrows

  make: () ->
    # Bind to attached data sources
    @_helpers.bind.make
      'geometry.points': Source

    # Build transform chain
    position = @_shaders.shader()
    @_helpers.position.make()

    # Fetch position (swizzle x into items, inv(wxyz) = yzwx)
    position.call Util.GLSL.swizzleVec4 'yzwx'
    @bind.points.shader position

    # Transform position to view
    @_helpers.position.shader position

    # Prepare bound uniforms
    styleUniforms = @_helpers.style.uniforms()
    lineUniforms  = @_helpers.line.uniforms()
    arrowUniforms = @_helpers.arrow.uniforms()

    # Clip start/end for terminating arrow
    start   = @_get 'arrow.start'
    end     = @_get 'arrow.end'

    # Fetch geometry dimensions
    dims    = @bind.points.getDimensions()
    samples = dims.items
    strips  = dims.width
    ribbons = dims.height
    layers  = dims.depth

    # Make line renderable
    uniforms = @_helpers.object.merge arrowUniforms, lineUniforms, styleUniforms
    @line = @_renderables.make 'line',
              uniforms: uniforms
              samples:  samples
              ribbons:  ribbons
              strips:   strips
              layers:   layers
              position: position
              clip:     start or end

    # Make arrow renderables
    @arrows = []
    uniforms = @_helpers.object.merge arrowUniforms, styleUniforms

    if start
      @arrows.push @_renderables.make 'arrow',
                uniforms: uniforms
                flip:     true
                samples:  samples
                ribbons:  ribbons
                strips:   strips
                position: position

    if end
      @arrows.push @_renderables.make 'arrow',
                uniforms: uniforms
                samples:  samples
                ribbons:  ribbons
                strips:   strips
                position: position

    @resize()

    @_helpers.object.make @arrows.concat [@line]

  unmake: () ->
    @_helpers.bind.unmake()
    @_helpers.object.unmake()
    @_helpers.position.unmake()

    @line = @arrows = null

  change: (changed, touched, init) ->
    @rebuild() if changed['geometry.points']? or
                  changed['arrow.start']?     or
                  changed['arrow.end']?

module.exports = Vector
