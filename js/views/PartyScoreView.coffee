_ = require('underscore')
Backbone = require('backbone')
d3 = require('d3')
$ = Backbone.$

Parties = require('../../lib/Parties')
Policies = require('../../lib/Policies')
positionTooltip = require('../positionTooltip')

M = global.Messages.PartyScoreView

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
    main: _.template("""
      <h2 class="yay">#{M.title}</h2>
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
    """)

    tooltip: _.template("""
      <div class="tooltip"><p><%- message %></p></div>
    """)

  events:
    'mouseenter [data-party-id]': '_onMouseenterParty'
    'mouseleave [data-party-id]': '_onMouseleaveParty'

  initialize: (options) ->
    throw 'must pass options.province, a Province' if 'province' not of options
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @votes = options.votes
    @province = options.province
    @tooltipPartyId = null
    @$tooltip = null

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
    # FIXME resume coding here.
    parties.sort((p1, p2) -> p2.fraction - p1.fraction || p1.name.charCodeAt(0) - p2.name.charCodeAt(0))

    html = @templates.main(parties: parties)
    @$el.html(html)
    @

  _onMouseenterParty: (e) -> @_showTooltip(e.currentTarget)
  _onMouseleaveParty: -> @_showTooltip(null)

  _showTooltip: (target) ->
    partyId = target?.getAttribute('data-party-id')
    return if @tooltipPartyId == partyId

    @$tooltip?.remove()
    @$('li.party').removeClass('hover')
    @tooltipPartyId = partyId
    return if !partyId?

    party = Parties.byId[partyId]
    nYay = 0
    nTotal = 0

    for [ yayPolicy, nayPolicy ] in @votes
      for otherParty in yayPolicy.parties when otherParty == party
        nYay++
        nTotal++
      for otherParty in nayPolicy.parties when otherParty == party
        nTotal++

    return if nTotal == 0 # There's no message when the user didn't choose a single policy

    message = @_getTooltipMessage(nYay, nTotal, party.name)
    html = @templates.tooltip(message: message)
    @$tooltip = $(html)

    @$el.append(@$tooltip)
    positionTooltip($(target).find('.bar')[0], @$tooltip.get())
    $(target).closest('li.party').addClass('hover')

  _getTooltipMessage: (nYay, nTotal, partyName) ->
    m = global.Messages
    nYayText = if nYay < 10 then m.Numeral[String(nYay)] else String(nYay)
    nTotalText = if nTotal < 10 then m.Numeral[String(nTotal)] else String(nTotal)
    policiesText = if nTotal == 1 then m.Policies['1'] else m.Policies.else
    M.tooltip
      .replace('{N}', nYayText)
      .replace('{D}', nTotalText)
      .replace('{party}', partyName)
      .replace('{policies}', policiesText)

  # Make the chart look better. Call this after inserting the element into the
  # DOM, and after window resize.
  tidyRenderGlitches: ->
    # Make all the labels the same width
    maxWidth = 0
    $partyNames = @$('.party-name')
    for el in $partyNames
      w = $(el).width()
      maxWidth = w if w > maxWidth
    $partyNames.width(maxWidth)

    # The "30%" labels ought to be within their bars. If the bars are too thin,
    # place the labels beside the bars.
    for label in @$('.label')
      $label = Backbone.$(label)
      # Undo any previous iteration...
      $label.removeClass('next-to-bar')
      # And then move the label if we need to
      if $label.position().left < 0
        $label.addClass('next-to-bar')
