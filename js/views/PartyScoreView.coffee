_ = require('underscore')
Backbone = require('backbone')
d3 = require('d3')

Parties = require('../../lib/Parties')
Policies = require('../../lib/Policies')

module.exports = class PartyScoreView extends Backbone.View
  className: 'party-score'
  templates:
    # Takes as input:
    #
    # * `parties`: a sorted Array of Parties. Each party has:
    #   * id
    #   * en (or fr)
    #   * color
    #   * yay (see partyStance)
    #   * nay (see partyStance)
    main: _.template('''
      <div class="charts">
        <div class="half">
          <h2 class="yay">You agree with</h2>
          <div class="chart">
            <ul class="parties">
              <% parties.forEach(function(party) { %>
                <li class="party party-<%- party.id %>">
                  <div class="party-stance party-stance-yay"><%= renderPartyStance(party.yay) %></div>
                  <div class="party-name" style="color: <%- party.color %>;"><%- party.en %></div>
                </li>
              <% }); %>
            </ul>
          </div>
        </div>
      </div>
    ''')

    # Renders the stuff a party agrees/disagrees with (just one). Input has:
    #
    # * policies: Array of { id, color } Objects
    # * percent: 0-100 integer describing how much the user agrees/disagrees
    # * height: 0-1 float describing percent/(maximum percent for all parties)
    partyStance: _.template('''
      <div class="bar-container">
        <div class="label"><%- percent %>%</div>
        <div class="bar" style="height: <%- 100 * height %>%; background: <%- color %>;"></div>
      </div>
      <ul class="policies">
        <% policies.forEach(function(policy) { %>
          <li class="policy" data-policy-id="<%- policy.id %>" style="background: <%- policy.color %>;"></li>
        <% }); %>
      </ul>
    ''')

  initialize: (options) ->
    throw 'must pass options.province, a Province' if 'province' not of options
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @votes = options.votes
    @province = options.province

  render: ->
    return @ if @votes.length == 0

    parties = for party in Parties.all
      # Skip Bloc in non-QC
      continue if party.onlyInProvince? && party.onlyInProvince != @province
      id: party.id
      color: party.color
      en: party.en
      fr: party.fr
      yay: { policies: [], color: party.color, labelPosition: 'above' } # lazy, hence copying color
      nay: { policies: [], color: party.color, labelPosition: 'below' }

    idToParty = {}
    (idToParty[party.id] = party) for party in parties

    for [ yayPolicy, nayPolicy ] in @votes
      for party in yayPolicy.parties when party.id of idToParty
        idToParty[party.id].yay.policies.push(yayPolicy)
      for party in nayPolicy.parties when party.id of idToParty
        idToParty[party.id].nay.policies.push(nayPolicy)

    fillStancePercent = (stance, otherStance) ->
      stance.percent = if stance.policies.length == 0
        0
      else
        Math.round(100 * stance.policies.length / (stance.policies.length + otherStance.policies.length))
    for party in parties
      fillStancePercent(party.yay, party.nay)
      fillStancePercent(party.nay, party.yay)

    maxPercentYay = _.max(parties.map((p) -> p.yay.percent))
    maxPercentNay = _.max(parties.map((p) -> p.nay.percent))

    for party in parties
      party.yay.height = party.yay.percent / maxPercentYay
      party.nay.height = party.nay.percent / maxPercentNay

    parties.sort((p1, p2) -> p2.yay.percent - p1.yay.percent || p1.en.charCodeAt(0) - p2.en.charCodeAt(0))

    console.log(parties)

    html = @templates.main(parties: parties, renderPartyStance: @templates.partyStance)
    @$el.html(html)
    @
