_ = require('underscore')
Backbone = require('backbone')
d3 = require('d3')

Parties = require('../../lib/Parties')
Policies = require('../../lib/Policies')

module.exports = class PolicyScoreView extends Backbone.View
  className: 'policy-score'
  templates:
    loading: _.template('''<i class="icon-spinner"></i>''')
    error: _.template('') # Pretend all is well
    main: _.template('''
      <h2>Readers' policy preferences</h2>
      <p class="explanation">A score of <tt>+2</tt> means the policy was chosen twice more than it was <em>not</em> chosen.</p>
      <ul class="parties">
        <% parties.forEach(function(party) { %>
          <li class="party">
            <h4><%- party.en %></h4>
            <ul class="policies">
              <% party.policies.forEach(function(policy) { %>
                <li class="policy" data-policy-id="<%- policy.id %>" style="left: <%- policy.left %>%">
                  <div class="policy-marker"></div>
                </li>
              <% }); %>
            </ul>
          </li>
        <% }); %>
      </ul>
    ''')

  initialize: (options) ->
    throw 'must pass options.province, a Province' if 'province' not of options

    @province = options.province

  render: ->
    @$el.html(@templates.loading())

    Backbone.$.ajax
      url: '/statistics/n-votes-by-policy-id'
      failure: (a, b, c) =>
        console.log('Failure', a, b, c)
        @$el.html(@templates.error())
      success: (json) =>
        @_renderServerResponse(json)

    @

  _renderServerResponse: (json) ->
    # Pass the template an Array of
    #
    #     {
    #       id: <party ID>
    #       en: <party name>
    #       fr: <party name>
    #       policies: [ {
    #         id: <policy ID>
    #         en: <policy description>
    #         fr: <policy description>
    #         score: <policy score>
    #       }, ... ]
    #     }
    parties = for party in Parties.all when !party.onlyInProvince? || party.onlyInProvince == @province
      id: party.id
      en: party.en
      fr: party.fr
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
        en: rawPolicy.en
        fr: rawPolicy.fr
        score: score

      for party in rawPolicy.parties
        partyById[party.id]?.policies?.push(augmentedPolicy)

      augmentedPolicy

    policies.sort((a, b) -> a.score - b.score || a.id - b.id)

    # We'll show one dot per party*policy
    partiesXPolicies = []
    for party in parties
      for policy in party.policies
        partiesXPolicies.push(party: party, policy: policy)

    @$el.html('')
    margin = { top: 20, right: 20, bottom: 20, left: 120 }
    width = @$el.width() - margin.right - margin.left
    height = @$el.height() - margin.top - margin.bottom

    xScale = d3.scale.linear()
      .domain([ policies[0].score - 1, policies[policies.length - 1].score + 1 ])
      .rangeRound([ 0, width ])
    xAxis = d3.svg.axis().scale(xScale).orient('bottom')
      .tickSize(-height, 0, 0)

    yScale = d3.scale.ordinal()
      .domain(party.id for party in parties)
      .rangeRoundPoints([ height, 0 ], 1)
    yAxis = d3.svg.axis().scale(yScale).orient('left')
      .tickFormat((partyId) -> partyById[partyId].en)

    svg = d3.select(@el).append('svg')
      .attr('width', '100%')
      .attr('height', '100%')
      .append('g')
        .attr('transform', "translate(#{margin.left},#{margin.top})")

    # X-axis
    svg.append('g')
      .attr('class', 'x-axis')
      .attr('transform', "translate(0,#{height})")
      .call(xAxis.ticks(4))

    # Y-axis
    svg.append('g')
      .attr('class', 'y-axis')
      .call(yAxis)

    # Dots
    svg.selectAll('.policy')
      .data(partiesXPolicies)
      .enter().append('circle')
        .attr('class', 'policy')
        .attr('data-policy-id', (d) -> d.policy.id)
        .attr('r', 5)
        .attr('cx', (d) -> xScale(d.policy.score))
        .attr('cy', (d) -> yScale(d.party.id))
        .style('fill', '#abcdef')
        .attr('opacity', '.7')
