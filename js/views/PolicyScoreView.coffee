_ = require('underscore')
Backbone = require('backbone')
d3 = require('d3')

Parties = require('../../lib/Parties')
Policies = require('../../lib/Policies')
DotColorLegend = require('./DotColorLegend')

M = global.Messages.PolicyScoreView

module.exports = class PolicyScoreView extends Backbone.View
  className: 'policy-score'
  templates:
    loading: _.template('''<i class="icon-spinner"></i>''')
    error: _.template('') # Pretend all is well
    main: _.template("""
      <h2>#{M.title}</h2>
      <div class="chart"></div>
      <p class="explanation">#{M.explanation}</p>
    """)

  initialize: (options) ->
    throw 'must pass options.province, a Province' if 'province' not of options

    @province = options.province

  render: ->
    @$el.html(@templates.loading())

    Backbone.$.ajax
      url: '/statistics/n-votes-by-policy-id'
      failure: (a, b, c) =>
        @$el.html(@templates.error())
      success: (json) =>
        @_renderServerResponse(json)

    @

  _renderServerResponse: (json) ->
    # Pass the template an Array of
    #
    #     {
    #       id: <party ID>
    #       abbr: <party abbr>
    #       policies: [ {
    #         id: <policy ID>
    #         name: <policy description>
    #         score: <policy score>
    #       }, ... ]
    #     }
    parties = for party in Parties.all when !party.onlyInProvince? || party.onlyInProvince == @province
      id: party.id
      abbr: party.abbr
      color: party.color
      policies: []

    partyById = {}
    (partyById[p.id] = p) for p in parties

    isUsefulPolicyId = (policyId) =>
      # Return false if the client does not have the policy
      if policyId of Policies.byId
        policy = Policies.byId[policyId]
        for party in policy.parties
          # Return true iff one party promoting the policy is valid
          return true if !party.onlyInProvince? || party.onlyInProvince == @province
      false

    policies = for policyId, score of json when isUsefulPolicyId(policyId)
      rawPolicy = Policies.byId[policyId]

      augmentedPolicy =
        id: rawPolicy.id
        abbr: rawPolicy.abbr
        color: rawPolicy.color
        nAye: score.aye
        nNay: score.nay
        fractionAye: score.aye / (score.aye + score.nay) # assume aye+nay is >0, otherwise json wouldn't contain it

      for party in rawPolicy.parties
        partyById[party.id]?.policies?.push(augmentedPolicy)

      augmentedPolicy

    policies.sort((a, b) -> a.fractionAye - b.fractionAye || a.id - b.id)

    # We'll show one dot per party*policy
    partiesXPolicies = []
    for party in parties
      for policy in party.policies
        partiesXPolicies.push(party: party, policy: policy)

    @$el.html(@templates.main())
    @$('h2').after(new DotColorLegend(province: @province).render().el)
    $chart = @$('.chart')
    margin = { top: 0, right: 7, bottom: 15, left: 50 }
    width = $chart.width() - margin.right - margin.left
    height = $chart.height() - margin.top - margin.bottom

    xScale = d3.scale.linear()
      .domain([ 0, 1 ])
      .rangeRound([ 0, width ])
    xAxis = d3.svg.axis().scale(xScale).orient('bottom')
      .tickValues([ 0, 0.5, 1 ])
      .tickSize(-height, 0)
      .tickFormat(d3.format('%'))

    yScale = d3.scale.ordinal()
      .domain(party.id for party in parties)
      .rangeRoundPoints([ height, 0 ], 1)
    yAxis = d3.svg.axis().scale(yScale).orient('left')
      .tickFormat((partyId) -> partyById[partyId].abbr)

    svg = d3.select($chart.get(0)).append('svg')
      .attr('width', '100%')
      .attr('height', '100%')
      .append('g')
        .attr('transform', "translate(#{margin.left},#{margin.top})")

    # X-axis
    svg.append('g')
      .attr('class', 'x-axis')
      .attr('transform', "translate(0,#{height})")
      .call(xAxis.ticks(4))
      .selectAll('text')
        .attr('style', '') # turn off text-anchor: middle and use CSS

    # Y-axis
    svg.append('g')
      .attr('class', 'y-axis')
      .call(yAxis)
      .selectAll('text')
        .attr('style', '') # turn off text-anchor: right and use CSS
        .attr('x', -margin.left)
        .style('fill', (partyId) -> partyById[partyId].color)

    # Dots
    svg.selectAll('.policy')
      .data(partiesXPolicies)
      .enter().append('circle')
        .attr('class', 'policy')
        .attr('data-policy-id', (d) -> d.policy.id)
        .attr('r', 7)
        .attr('cx', (d) -> xScale(d.policy.fractionAye))
        .attr('cy', (d) -> yScale(d.party.id))
        .style('fill', (d) -> d.policy.color)

    @trigger('rendered')
