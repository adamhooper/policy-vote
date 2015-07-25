_ = require('underscore')
Backbone = require('backbone')
$ = Backbone.$

Parties = require('../../lib/Parties')

module.exports = class ForAgainstView extends Backbone.View
  className: 'for-against'
  template: _.template('''
    <h2>Breakdown by policy</h2>
    <table class="parties">
      <thead>
        <tr>
          <th class="party">Party</th>
          <th class="user-says-nay">you rejected</th>
          <th class="user-says-yay">you chose</th>
        </tr>
      </thead>
      <tbody>
        <% parties.forEach(function(party) { %>
          <tr>
            <th class="party" style="color: <%- party.color %>"><%- party.en %></th>
            <td class="user-says-nay">
              <ul class="policy-list">
                <% party.userSaysNay.forEach(function(policy) { %>
                  <li class="policy" style="background: <%- policy.color %>" data-policy-id="<%- policy.id %>"></li>
                <% }); %>
              </ul>
            </td>
            <td class="user-says-yay">
              <ul class="policy-list">
                <% party.userSaysYay.forEach(function(policy) { %>
                  <li class="policy" style="background: <%- policy.color %>" data-policy-id="<%- policy.id %>"></li>
                <% }); %>
              </ul>
            </td>
          </li>
        <% }) %>
      </tbody>
    </table>
  ''')

  initialize: (options) ->
    throw 'must pass options.province, a Province' if 'province' not of options
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @votes = options.votes
    @province = options.province

  render: ->
    # We'll build an Array of parties that look like:
    #
    #     {
    #       id: 'L'
    #       color: '#abcdef'
    #       en: 'Liberal'
    #       fr: 'libéral'
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
        en: party.en
        fr: party.fr
        userSaysYay: []
        userSaysNay: []

    # The policies we pass will be augmented with vote information:
    #
    #     {
    #       id: 123
    #       en: 'Do something'
    #       fr: 'faites quelque chose'
    #       userSaysNayOver: [ policy, policy ]
    #       userSaysYayOver: [ policy, policy ]
    #     }
    augmentedPoliciesById = {}

    getOrSetAugmentedPolicy = (policy) ->
      augmentedPoliciesById[policy.id] ||=
        id: policy.id
        color: policy.color
        en: policy.en
        fr: policy.fr
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
    parties.sort (a, b) ->
      (
        (b.userSaysYay.length - b.userSaysNay.length) - (a.userSaysYay.length - a.userSaysNay.length) ||
        (b.userSaysYay.length - a.userSaysYay.length) ||
        (if a.id < b.id then -1 else if b.id < a.id then 1 else 0)
      )

    html = @template(parties: parties)

    @$el.html(html)
    @_expandedEl = null # li.policy HTMLElement, or null
    @
