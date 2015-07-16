_ = require('underscore')
Backbone = require('backbone')
$ = Backbone.$

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
        <a class="policy-marker">&nbsp;</a>
        <div class="policy-details">
          <h4 class="policy-policy"><%- policy.get('policy') %></h4>
          <div class="policy-party">Promised by <strong><%- policy.get('parties').join(', ') %></strong></div>
          <% if (policy.betterThanPolicies.length) { %>
            <div class="policy-better-than">
              <p>You chose this policy over:</p>
              <ul>
                <% policy.betterThanPolicies.forEach(function(otherPolicy) { %>
                  <li><%- otherPolicy.get('en') %></li>
                <% }) %>
              </ul>
            </div>
          <% } %>
          <% if (policy.worseThanPolicies.length) { %>
            <div class="policy-worse-than">
              <p>You disliked this policy compared to:</p>
              <ul>
                <% policy.worseThanPolicies.forEach(function(otherPolicy) { %>
                  <li><%- otherPolicy.get('en') %></li>
                <% }) %>
              </ul>
            </div>
          <% } %>
        </div>
      </li>
    ''')

  events:
    'click .policy-marker': '_onClickPolicyMarker'
    'click .policy-details': '_onClickPolicyDetails'

  initialize: (options) ->
    throw 'must pass options.policies, a Policies' if !options.policies
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @policies = options.policies
    @votes = options.votes

    $(document).on('click.for-against-view', (e) => @_onClickDocument(e))

  render: ->
    # We'll pass in an Array of parties that look like:
    #
    #     {
    #       name: 'Liberal'
    #       for: [ policy, policy, policy, ... ]
    #       against: [ policy, policy, policy, ... ]
    #     }
    parties = for name in _.uniq(_.flatten(@policies.pluck('parties'))).sort()
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

      partyByName[p].for.push(better) for p in better.get('parties')
      partyByName[p].against.push(worse) for p in worse.get('parties')

    html = @templates.main
      parties: parties
      renderPolicy: @templates.policy

    @$el.html(html)
    @_expandedEl = null # li.policy HTMLElement, or null
    @

  remove: ->
    $(document).off('click.for-against-view')
    super.remove()

  _onClickPolicyMarker: (e) ->
    console.log(e)
    el = $(e.currentTarget).closest('li.policy').get(0)

    @_expandedEl.className = 'policy' if @_expandedEl? # un-expand old one
    if el == @_expandedEl
      # don't expand anything
      @_expandedEl = null
    else
      # expand a new one
      el.className = 'policy expanded'
      @_expandedEl = el

    e.stopPropagation() # don't trigger _onClickDocument

  _onClickPolicyDetails: (e) -> e.stopPropagation() # don't trigger _onClickDocument

  _onClickDocument: (e) ->
    # Hide expanded policy
    if @_expandedEl?
      @_expandedEl.className = 'policy'
      @_expandedEl = null
