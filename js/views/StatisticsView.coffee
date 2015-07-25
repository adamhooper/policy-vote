_ = require('underscore')
Backbone = require('backbone')
$ = Backbone.$

ForAgainstView = require('./ForAgainstView')
Policies = require('../../lib/Policies')
PartyScoreView = require('./PartyScoreView')
PolicyScoreView = require('./PolicyScoreView')
ShareView = require('./ShareView')

M = global.Messages.StatisticsView

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

  templates:
    main: _.template("""
      <div class="user-charts"></div>
      <div class="back-to-questions">
        <% if (votes.length == 0) { %>
          <p>#{M.backToQuestions['0']}</p>
        <% } else { %>
          <p>#{M.backToQuestions.else}</p>
        <% } %>
        <button type="button">#{M.backToQuestions.button}</button>
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
    'mouseover [data-policy-id]': '_onMouseoverPolicy'
    'mouseout [data-policy-id]': '_onMouseoutPolicy'
    'click .back-to-questions button': '_onClickBackToQuestions'

  render: ->
    @$el.html(@templates.main(votes: @votes))
    @$('.user-charts')
      .append(@partyScoreView.render().el)
      .append(@forAgainstView.render().el)
    @$('.all-users-charts')
      .append(@policyScoreView.render().el)
    @$el.append(@shareView.render().el)
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
      name: policy.name
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

    targetOffset = $target.offset()
    targetSize = if target.hasAttribute('r') # svg <circle>
      d = +target.getAttribute('r') << 1
      width: d
      height: d
    else
      width: $target.width()
      height: $target.height()

    className = null
    css = {}

    # Figure out vertical alignment
    #
    # Go above target if there's space; otherwise, below
    tooltipHeight = @$tooltip.outerHeight()
    if targetOffset.top - $(window).scrollTop() > tooltipHeight
      className = 'above'
      css.top = targetOffset.top - margin - tooltipHeight
    else
      className = 'below'
      css.top = targetOffset.top + targetSize.height + margin

    # Align tooltip horizontally
    #
    # Center over target; ensure margin px from edges
    tooltipWidth = @$tooltip.outerWidth()
    rightLimit = @$el.width()
    left = targetOffset.left + (targetSize.width / 2) - (tooltipWidth / 2)
    if left + tooltipWidth + margin > rightLimit
      left = rightLimit - tooltipWidth - margin
    else if left < margin
      left = margin
    css.left = left

    @$tooltip
      .attr('class', "policy-tooltip #{className}")
      .css(css)

  _onMouseoutPolicy: (e) ->
    @tooltipTarget?.setAttribute('class', @tooltipTargetClassName)
    @tooltipTarget = null
    @$tooltip.attr('class', 'policy-tooltip hide')

  _onClickBackToQuestions: (e) -> @trigger('clicked-back-to-questions')

  # The element will only be added to the DOM *after* it's rendered, but before
  # we figure out whether the label fits. Whoever owns this view will need to
  # call `tidyRenderGlitches()` right after inserting the element into the DOM,
  # _and_ on window resize.
  tidyRenderGlitches: ->
    @partyScoreView.tidyRenderGlitches()
