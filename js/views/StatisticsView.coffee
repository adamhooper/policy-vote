_ = require('underscore')
Backbone = require('backbone')
$ = Backbone.$

ForAgainstView = require('./ForAgainstView')
PolicyScoreView = require('./PolicyScoreView')
Policies = require('../../lib/Policies')

module.exports = class StatisticsView extends Backbone.View
  className: 'statistics'

  initialize: (options) ->
    throw 'must pass options.province, the user\'s Province' if 'province' not of options
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @province = options.province
    @votes = options.votes

  templates:
    policyDetails: _.template('''
      <div class="policy-details">
        <h4 class="policy-policy"><%- policy.en %></h4>
        <div class="policy-party">Promised by <strong><%- policy.parties.map(function(p) { return p.en; }).join(', ') %></strong></div>
        <% if (policy.userSaysYayOver.length) { %>
          <div class="policy-better-than">
            <p>You chose this policy over:</p>
            <ul>
              <% policy.userSaysYayOver.forEach(function(otherPolicy) { %>
                <li><%- otherPolicy.en %></li>
              <% }) %>
            </ul>
          </div>
        <% } %>
        <% if (policy.userSaysNayOver.length) { %>
          <div class="policy-worse-than">
            <p>You disliked this policy compared to:</p>
            <ul>
              <% policy.userSaysNayOver.forEach(function(otherPolicy) { %>
                <li><%- otherPolicy.en %></li>
              <% }) %>
            </ul>
          </div>
        <% } %>
      </div>
    ''')

  events:
    'mouseover [data-policy-id]': '_onMouseoverPolicy'
    'mouseout [data-policy-id]': '_onMouseoutPolicy'

  render: ->
    @$el.append(new ForAgainstView(province: @province, votes: @votes).render().el)
    @$el.append(new PolicyScoreView(province: @province).render().el)
    @$el.append(@$tooltip = $('<div class="policy-tooltip"></div>'))
    @tooltipTarget = null
    @tooltipTargetClassName = null
    @

  _policyTooltipHtml: (policyId) ->
    policy = Policies.byId[policyId]
    return '' if !policy?

    # Return a wrapper with userSaysYayOver and userSaysNayOver
    policy =
      id: policy.id
      en: policy.en
      fr: policy.fr
      parties: policy.parties
      userSaysYayOver: []
      userSaysNayOver: []

    for [ yayPolicy, nayPolicy ] in @votes
      policy.userSaysYayOver.push(nayPolicy) if yayPolicy.id == policy.id
      policy.userSaysNayOver.push(yayPolicy) if nayPolicy.id == policy.id

    @templates.policyDetails(policy: policy)

  _onMouseoverPolicy: (e) ->
    target = e.currentTarget
    $target = $(target)

    if target != @tooltipTarget
      # Something that works with both SVG and HTML
      @tooltipTarget?.setAttribute('class', @tooltipTargetClassName)
      @tooltipTarget = target
      @tooltipTargetClassName = target.getAttribute('class')
      @tooltipTarget.setAttribute('class', @tooltipTargetClassName + ' hovering')

    policyId = $target.attr('data-policy-id')
    @$tooltip
      .html(@_policyTooltipHtml(policyId))
      .attr('class', 'policy-tooltip above') # Make it visible so we can calculate the height
    # Show tooltip _above_ the target, if possible -- nicer on mobile
    margin = 10 # 10px between item top and tooltip bottom
    targetTop = $target.offset().top - $(window).scrollTop()
    if @$tooltip.height() < targetTop - margin
      @$tooltip
        .attr('class', 'policy-tooltip above')
        .css(top: $target.position().top - margin - @$tooltip.height())
    else
      targetHeight = if target.hasAttribute('r') # svg <circle>
        +target.getAttribute('r') * 2
      else
        $target.height()
      console.log($target.position().top, targetHeight, margin)
      @$tooltip
        .attr('class', 'policy-tooltip below')
        .css(top: $target.position().top + targetHeight + margin)

  _onMouseoutPolicy: (e) ->
    @tooltipTarget?.setAttribute('class', @tooltipTargetClassName)
    @tooltipTarget = null
    @$tooltip.attr('class', 'policy-tooltip hide')
