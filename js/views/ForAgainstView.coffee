_ = require('underscore')
Backbone = require('backbone')
$ = Backbone.$

Parties = require('../Parties')

module.exports = class ForAgainstView extends Backbone.View
  className: 'for-against'
  templates:
    main: _.template('''
      <h2>Your choices, by party:</h2>
      <table class="parties">
        <thead>
          <tr>
            <th class="party">Party</th>
            <th class="user-says-nay">nay</th>
            <th class="user-says-yay">yay</th>
          </tr>
        </thead>
        <tbody>
          <% parties.forEach(function(party) { %>
            <tr>
              <th class="party"><%- party.en %></th>
              <td class="user-says-nay">
                <ul class="policy-list">
                  <%= party.userSaysNay.map(function(policy) { return renderPolicy({ policy: policy }); }).join('') %>
                </ul>
              </td>
              <td class="user-says-yay">
                <ul class="policy-list">
                  <%= party.userSaysYay.map(function(policy) { return renderPolicy({ policy: policy }); }).join('') %>
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
          <h4 class="policy-policy"><%- policy.en %></h4>
          <div class="policy-party">Promised by <strong><%- policy.parties.map(function(p) { return p.en; }).join(', ') %></strong></div>
          <% if (policy.userSaysYayOver.length) { %>
            <div class="policy-better-than">
              <p>You chose this policy over:</p>
              <ul>
                <% policy.userSaysYayOver.forEach(function(otherPolicy) { %>
                  <li><%- otherPolicy.en %></li>
                <% }) %>
              </ul>
            </div>
          <% } %>
          <% if (policy.userSaysNayOver.length) { %>
            <div class="policy-worse-than">
              <p>You disliked this policy compared to:</p>
              <ul>
                <% policy.userSaysNayOver.forEach(function(otherPolicy) { %>
                  <li><%- otherPolicy.en %></li>
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
    throw 'must pass options.province, a Province' if 'province' not of options
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @votes = options.votes
    @province = options.province

    $(document).on('click.for-against-view', (e) => @_onClickDocument(e))

  render: ->
    # We'll build an Array of parties that look like:
    #
    #     {
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
        en: party.en
        fr: party.fr
        userSaysYay: []
        userSaysNay: []

    # The policies we pass will be augmented with vote information:
    #
    #     {
    #       en: 'Do something'
    #       fr: 'faites quelque chose'
    #       userSaysNayOver: [ policy, policy ]
    #       userSaysYayOver: [ policy, policy ]
    #     }
    augmentedPoliciesById = {}

    getOrSetAugmentedPolicy = (policy) ->
      augmentedPoliciesById[policy.id] ||=
        id: policy.id
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

      yayPolicy.userSaysYayOver.push(nayPolicy)
      nayPolicy.userSaysNayOver.push(yayPolicy)

    # Now, turn augmentedPartiesById into an Array
    parties = (party for __, party of augmentedPartiesById)
    parties.sort (a, b) ->
      (
        (b.userSaysYay.length - b.userSaysNay.length) - (a.userSaysYay.length - a.userSaysNay.length) ||
        (b.userSaysYay.length - a.userSaysYay.length) ||
        (if a.id < b.id then -1 else if b.id < a.id then 1 else 0)
      )

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
