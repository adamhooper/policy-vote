_ = require('underscore')
Backbone = require('backbone')
$ = Backbone.$

DotColorLegend = require('./DotColorLegend')
Parties = require('../../lib/Parties')

M = global.Messages.ForAgainstView

module.exports = class ForAgainstView extends Backbone.View
  className: 'for-against'
  template: _.template("""
    <h2>#{M.title}</h2>
    <table class="parties">
      <thead>
        <tr>
          <th class="user-says-nay">#{M.th.rejected}</th>
          <th class="party"></th>
          <th class="user-says-yay">#{M.th.chosen}</th>
        </tr>
      </thead>
      <tbody>
        <% parties.forEach(function(party) { %>
          <tr>
            <td class="user-says-nay">
              <ul class="policy-list">
                <% party.userSaysNay.forEach(function(policy) {
                  %><li class="policy" style="background: <%- policy.color %>" data-policy-id="<%- policy.id %>"></li
                ><% }); %>
              </ul>
            </td>
            <th class="party" style="color: <%- party.color %>" data-party-name="<%- party.name %>" data-party-abbr="<%- party.abbr %>"><%- party.name %></th>
            <td class="user-says-yay">
              <ul class="policy-list">
                <% party.userSaysYay.forEach(function(policy) {
                  %><li class="policy" style="background: <%- policy.color %>" data-policy-id="<%- policy.id %>"></li
                ><% }); %>
              </ul>
            </td>
          </li>
        <% }) %>
      </tbody>
    </table>
  """)

  initialize: (options) ->
    throw 'must pass options.province, a Province' if 'province' not of options
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @votes = options.votes
    @province = options.province

  render: ->
    return @ if !@votes.length

    # We'll build an Array of parties that look like:
    #
    #     {
    #       id: 'L'
    #       color: '#abcdef'
    #       name: 'Liberal'
    #       userSaysYay: [ policy, policy, policy, ... ]
    #       userSaysNay: [ policy, policy, policy, ... ]
    #     }
    #
    # Create an Object for now, hashed by ID. Later, we'll sort it.
    augmentedPartiesById = {}
    for party in Parties.all
      # Skip Bloc in non-QC
      continue if party.onlyInProvince? && party.onlyInProvince != @province
      augmentedPartiesById[party.id] =
        id: party.id
        color: party.color
        name: party.name
        userSaysYay: []
        userSaysNay: []

    # The policies we pass will be augmented with vote information:
    #
    #     {
    #       id: 123
    #       name: 'Do something'
    #       userSaysNayOver: [ policy, policy ]
    #       userSaysYayOver: [ policy, policy ]
    #     }
    augmentedPoliciesById = {}

    getOrSetAugmentedPolicy = (policy) ->
      augmentedPoliciesById[policy.id] ||=
        id: policy.id
        color: policy.color
        name: policy.name
        parties: augmentedPartiesById[party.id] for party in policy.parties when party.id of augmentedPartiesById
        userSaysYayOver: []
        userSaysNayOver: []

    for [ yayPolicy, nayPolicy ] in @votes
      yayPolicy = getOrSetAugmentedPolicy(yayPolicy)
      nayPolicy = getOrSetAugmentedPolicy(nayPolicy)

      party.userSaysYay.push(yayPolicy) for party in yayPolicy.parties
      party.userSaysNay.push(nayPolicy) for party in nayPolicy.parties

    # Now, turn augmentedPartiesById into an Array
    parties = (party for __, party of augmentedPartiesById)
    sortScore = (party) ->
      nPolicies = party.userSaysYay.length + party.userSaysNay.length
      if nPolicies == 0 then 0 else party.userSaysYay.length / nPolicies
    parties.sort (a, b) -> # This is the same order as PartyScore. Important!
      (
        sortScore(b) - sortScore(a) ||
        (if a.id < b.id then -1 else if b.id < a.id then 1 else 0)
      )

    html = @template(parties: parties)

    @$el.html(html)
    @$('h2').after(new DotColorLegend(province: @province).render().el)
    @_expandedEl = null # li.policy HTMLElement, or null
    @
