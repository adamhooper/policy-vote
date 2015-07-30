_ = require('underscore')
Backbone = require('backbone')
$ = Backbone.$

ForAgainstView = require('./ForAgainstView')
Policies = require('../../lib/Policies')
PartyScoreView = require('./PartyScoreView')
PolicyScoreView = require('./PolicyScoreView')
ShareView = require('./ShareView')
positionTooltip = require('../positionTooltip')

M = global.Messages.StatisticsView

MaxClickDistance = 20 # ignore clicks that are further than this distance from the center of a policy

module.exports = class StatisticsView extends Backbone.View
  className: 'statistics'

  initialize: (options) ->
    throw 'must pass options.province, the user\'s Province' if 'province' not of options
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @province = options.province
    @votes = options.votes

    @partyScoreView = new PartyScoreView(province: @province, votes: @votes)
    @forAgainstView = new ForAgainstView(province: @province, votes: @votes)
    @policyScoreView = new PolicyScoreView(province: @province)
    @shareView = new ShareView()

    @listenTo(@partyScoreView, 'rendered', => @trigger('rendered'))
    @listenTo(@forAgainstView, 'rendered', => @trigger('rendered'))
    @listenTo(@policyScoreView, 'rendered', => @trigger('rendered'))
    $(document).on('click.statistics', (e) => @_onClickDocument(e))

  remove: ->
    $(document).off('click.statistics')
    super.remove()

  templates:
    main: _.template("""
      <% if (votes.length > 0) { %>
        <div class="user-charts"></div>
      <% } %>
      <div class="back-to-questions">
        <% if (votes.length == 0) { %>
          <p>#{M.backToQuestions['0']}</p>
        <% } else { %>
          <p>#{M.backToQuestions.else}</p>
        <% } %>
        <button type="button"><i class="icon icon-caret-left"></i> #{M.backToQuestions.button}</button>
      </div>
      <div class="all-users-charts"></div>
    """)

    policyDetails: _.template("""
      <div class="policy-details">
        <h4 class="policy-policy"><%- policy.name %></h4>
        <div class="policy-party">
          #{M.promisedBy}
          <ul class="parties">
            <% policy.parties.forEach(function(party) { %>
              <li class="party"><i style="background: <%- party.color %>;"></i> <%- party.name %></li>
            <% }); %>
          </ul>
        <% if (policy.userSaysYayOver.length) { %>
          <div class="policy-better-than">
            <p><strong>#{M.youChoseThisOver}</strong></p>
            <ul>
              <% policy.userSaysYayOver.forEach(function(otherPolicy) { %>
                <li>
                  <% otherPolicy.parties.forEach(function(otherParty) { %>
                    <i style="background: <%- otherParty.color %>;"></i>
                  <% }); %>
                  <%- otherPolicy.name %>
                </li>
              <% }) %>
            </ul>
          </div>
        <% } %>
        <% if (policy.userSaysNayOver.length) { %>
          <div class="policy-worse-than">
            <p><strong>#{M.youDislikedThisComparedTo}</strong></p>
            <ul>
              <% policy.userSaysNayOver.forEach(function(otherPolicy) { %>
                <li>
                  <% otherPolicy.parties.forEach(function(otherParty) { %>
                    <i style="background: <%- otherParty.color %>;"></i>
                  <% }); %>
                  <%- otherPolicy.name %>
                </li>
              <% }) %>
            </ul>
          </div>
        <% } %>
      </div>
    """)

  events:
    'mouseenter [data-policy-id]': '_onMouseenterPolicy'
    'mouseleave [data-policy-id]': '_onMouseleavePolicy'
    'click .back-to-questions button': '_onClickBackToQuestions'

  render: ->
    @$el.html(@templates.main(votes: @votes))
    if @votes.length > 0
      @$('.user-charts')
        .append(@partyScoreView.render().el)
        .append(@forAgainstView.render().el)
    @$('.all-users-charts')
      .append(@policyScoreView.render().el)
    @$el.append(@shareView.render().el)
    @$el.append(@$tooltip = $('<div class="policy-tooltip hide"></div>'))
    @tooltipTarget = null
    @tooltipTargetClassName = null
    @

  _policyTooltipHtml: (policyId) ->
    policy = Policies.byId[policyId]
    return '' if !policy?

    # Return a wrapper with userSaysYayOver and userSaysNayOver
    policy =
      id: policy.id
      name: policy.name
      parties: policy.parties
      userSaysYayOver: []
      userSaysNayOver: []

    for [ yayPolicy, nayPolicy ] in @votes
      policy.userSaysYayOver.push(nayPolicy) if yayPolicy.id == policy.id
      policy.userSaysNayOver.push(yayPolicy) if nayPolicy.id == policy.id

    @templates.policyDetails(policy: policy)

  _setTooltipTarget: (target) ->
    if target != @tooltipTarget
      # Something that works with both SVG and HTML
      @tooltipTarget?.setAttribute('class', @tooltipTargetClassName)
      @tooltipTarget = target
      @tooltipTargetClassName = target.getAttribute('class')
      @tooltipTarget.setAttribute('class', @tooltipTargetClassName + ' hovering')

    policyId = target.getAttribute('data-policy-id')
    @$tooltip
      .html(@_policyTooltipHtml(policyId))
      .attr('class', 'policy-tooltip') # Make it visible so we can calculate the height

    positionTooltip(target, @$tooltip.get(0))

  _hideTooltip: ->
    @tooltipTarget?.setAttribute('class', @tooltipTargetClassName)
    @tooltipTarget = null
    @$tooltip.attr('class', 'policy-tooltip hide')

  _handleTouch: (e) ->
    touch = e.originalEvent.touches[0]
    x = touch.pageX
    y = touch.pageY
    el = document.elementFromPoint?(x, y)
    if el.hasAttribute('data-policy-id')
      @_setTooltipTarget(el)
    else
      @_hideTooltip()

  _onMouseenterPolicy: (e) -> @_setTooltipTarget(e.currentTarget)
  _onMouseleavePolicy: -> @_hideTooltip()

  _onClickDocument: (e) ->
    # If the user clicks _near_ a policy, open it. This is for mobile, where
    # the policies are too small to click.
    minDistance = MaxClickDistance
    bestEl = null

    if $(e.target).closest('table.parties').length
      # Find the policy in the table
      x = e.originalEvent.clientX
      y = e.originalEvent.clientY

      for el in @$('table.parties li.policy')
        bounds = el.getBoundingClientRect()
        cx = bounds.left + bounds.width / 2
        cy = bounds.top + bounds.height / 2
        # Manhattan distance, because who cares?
        distance = Math.abs(cx - x) + Math.abs(cy - y)
        if distance < minDistance
          bestEl = el
          minDistance = distance

    else if $(e.target).closest('.policy-score .chart').length
      # Find the policy in the SVG
      chart = $(e.target).closest('.policy-score .chart').get(0)
      bounds = chart.getBoundingClientRect()
      g = chart.querySelector('svg>g')
      x = e.originalEvent.clientX - bounds.left - g.transform.baseVal[0].matrix.e
      y = e.originalEvent.clientY - bounds.top

      for el in chart.querySelectorAll('.policy')
        cx = el.cx.baseVal.value
        cy = el.cy.baseVal.value
        # Manhattan distance, because who cares?
        distance = Math.abs(cx - x) + Math.abs(cy - y)
        if distance < minDistance
          bestEl = el
          minDistance = distance

    if bestEl?
      @_setTooltipTarget(bestEl)
    else
      @_hideTooltip()

  _onClickBackToQuestions: (e) -> @trigger('clicked-back-to-questions')

  # The element will only be added to the DOM *after* it's rendered, but before
  # we figure out whether the label fits. Whoever owns this view will need to
  # call `tidyRenderGlitches()` right after inserting the element into the DOM,
  # _and_ on window resize.
  tidyRenderGlitches: ->
    @partyScoreView.tidyRenderGlitches()
