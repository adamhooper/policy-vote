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
    #   * name
    #   * color
    #   * percent: 0-100 integer describing how much the user agrees/disagrees
    #   * fraction: 0-1 float describing percent/(maximum percent for all parties)
    main: _.template('''
      <h2 class="yay">You agree with</h2>
      <div class="chart">
        <ul class="parties">
          <% parties.forEach(function(party) { %>
            <li data-party-id="<%- party.id %>" class="party party-<%- party.id %>">
              <div class="party-name" style="color: <%- party.color %>;"><%- party.name %></div>
              <div class="bar-container">
                <div class="bar" style="width: <%- 100 * party.fraction %>%; background: <%- party.color %>;">
                  <div class="label"><%- party.percent %>%</div>
                </div>
              </div>
            </li>
          <% }); %>
        </ul>
      </div>
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
      name: party.name
      nYayPolicies: 0
      nPolicies: 0

    idToParty = {}
    (idToParty[party.id] = party) for party in parties

    for [ yayPolicy, nayPolicy ] in @votes
      for party in yayPolicy.parties when party.id of idToParty
        idToParty[party.id].nYayPolicies++
        idToParty[party.id].nPolicies++
      for party in nayPolicy.parties when party.id of idToParty
        idToParty[party.id].nPolicies++

    maxPercent = null
    for party in parties
      percent = if party.nPolicies == 0
        0
      else
        Math.round(100 * party.nYayPolicies / party.nPolicies)
      party.percent = percent
      maxPercent = percent if !maxPercent? || percent > maxPercent

    for party in parties
      party.fraction = party.percent / maxPercent

    parties.sort((p1, p2) -> p2.fraction - p1.fraction || p1.name.charCodeAt(0) - p2.name.charCodeAt(0))

    console.log(parties)

    html = @templates.main(parties: parties)
    @$el.html(html)
    @

  # The element will only be added to the DOM *after* it's rendered, but before
  # we figure out whether the label fits. Whoever owns this view will need to
  # call `tidyRenderGlitches()` right after inserting the element into the DOM,
  # _and_ on window resize.
  tidyRenderGlitches: ->
    for label in @$('.label')
      $label = Backbone.$(label)
      $label.removeClass('next-to-bar')
      console.log($label.position())
      if $label.position().left < 0
        $label.addClass('next-to-bar')
