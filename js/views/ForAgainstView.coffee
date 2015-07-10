_ = require('underscore')
Backbone = require('backbone')

module.exports = class ForAgainstView extends Backbone.View
  className: 'for-against'
  templates:
    main: _.template('''
      <h2>Your choices, by party:</h2>
      <table class="parties">
        <thead>
          <tr>
            <th class="party">Party</th>
            <th class="against">nay</th>
            <th class="for">yay</th>
          </tr>
        </thead>
        <tbody>
          <% parties.forEach(function(party) { %>
            <tr>
              <th class="party"><%- party.name %></th>
              <td class="against">
                <ul class="policy-list">
                  <%= party.against.map(function(policy) { return renderPolicy({ policy: policy }); }).join('') %>
                </ul>
              </td>
              <td class="for">
                <ul class="policy-list">
                  <%= party["for"].map(function(policy) { return renderPolicy({ policy: policy }); }).join('') %>
                </ul>
              </td>
            </li>
          <% }) %>
        </tbody>
      </ul>
    ''')

    policy: _.template('''
      <li class="policy">
        <div class="policy-marker"></div>
        <div class="policy-details">
          <h4 class="policy-policy"><%- policy.get('policy') %></h4>
          <div class="policy-party">Proposed by <strong><%- policy.get('party') %></strong></div>
          <% if (policy.betterThanPolicies.length) { %>
            <div class="policy-better-than">
              <p>You chose this policy over:</p>
              <ul>
                <% policy.betterThanPolicies.forEach(function(otherPolicy) { %>
                  <li><%- otherPolicy.get('policy') %></li>
                <% }) %>
              </ul>
            </div>
          <% } %>
          <% if (policy.worseThanPolicies.length) { %>
            <div class="policy-worse-than">
              <p>You disliked this policy compared to:</p>
              <ul>
                <% policy.worseThanPolicies.forEach(function(otherPolicy) { %>
                  <li><%- otherPolicy.get('policy') %></li>
                <% }) %>
              </ul>
            </div>
          <% } %>
        </div>
      </li>
    ''')

  initialize: (options) ->
    throw 'must pass options.policies, a Policies' if !options.policies
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @policies = options.policies
    @votes = options.votes

  render: ->
    # We'll pass in an Array of parties that look like:
    #
    #     {
    #       name: 'Liberal'
    #       for: [ policy, policy, policy, ... ]
    #       against: [ policy, policy, policy, ... ]
    #     }
    parties = for name in _.uniq(@policies.pluck('party')).sort()
      name: name
      against: [] # what the _user_ is against
      for: []     # what the _user_ is for

    partyByName = {}
    (partyByName[party.name] = party) for party in parties

    @policies.forEach (policy) ->
      policy.betterThanPolicies = []
      policy.worseThanPolicies = []

    for [ better, worse ] in @votes
      better.betterThanPolicies.push(worse)
      worse.worseThanPolicies.push(better)

      partyByName[better.get('party')].for.push(better)
      partyByName[worse.get('party')].against.push(worse)

    html = @templates.main
      parties: parties
      renderPolicy: @templates.policy

    @$el.html(html)
    @
