Backbone = require('backbone')
$ = Backbone.$
_ = require('underscore')

Policies = require('../../lib/Policies')

module.exports = class QuestionView extends Backbone.View
  className: 'question'
  template: _.template('''
    <header><h1>Pick the idea you prefer</h1></header>
    <div class="choices">
      <button class="choice" data-policy-id="<%- policy1.id %>" data-other-policy-id="<%- policy2.id %>">
        <span class="inner">
          <%- policy1.name %>
        </span>
      </button>
      <button class="choice" data-policy-id="<%- policy2.id %>" data-other-policy-id="<%- policy1.id %>">
        <span class="inner">
          <%- policy2.name %>
        </span>
      </button>
    </div>
    <div class="done">
      <p class="explanation"><%- nVotesMessage %></p>
      <button class="show-statistics">I'm done. Party time!</button>
    </div>
  ''')

  events:
    'click button.choice': '_onClickChoice'
    'click button.show-statistics': '_onClickShowStatistics'

  initialize: (options) ->
    throw 'Must pass options.province, the user\'s Province' if 'province' not of options

    @province = options.province
    @nVotes = 0
    @unseenPolicies = []

  _policyAppliesInProvince: (policy) ->
    for party in policy.parties
      return true if !party.onlyInProvince? || party.onlyInProvince == @province
    false

  _buildNVotesMessage: ->
    numbers = [ null, null, 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine' ]
    if @nVotes < 2
      "Pick policies. We'll chart your vision."
    else if @nVotes < 10
      "You picked #{numbers[@nVotes]} policies. Aim for at least 10."
    else if @nVotes < 20
      "You picked #{@nVotes} policies. For nicer charts, pick 20."
    else if @nVotes < 30
      "Great! You picked #{@nVotes} policies. Your charts will be nice."
    else
      "You picked #{@nVotes} policies. Fabulous charts await."

  pick2: ->
    if @unseenPolicies.length < 2
      # More policies!
      @unseenPolicies = @unseenPolicies.concat(_.shuffle(
        Policies.all.slice()
          .filter((p) => @_policyAppliesInProvince(p))
      ))
    [ @unseenPolicies.pop(), @unseenPolicies.pop() ]

  render: ->
    [ policy1, policy2 ] = @pick2()
    @$el.html(@template(policy1: policy1, policy2: policy2, nVotesMessage: @_buildNVotesMessage()))
    @

  _onClickChoice: (e) ->
    policyId = $(e.currentTarget).attr('data-policy-id')
    otherPolicyId = $(e.currentTarget).attr('data-other-policy-id')
    @nVotes++
    @trigger('user-prefers-policy', Policies.byId[policyId], Policies.byId[otherPolicyId])

  _onClickShowStatistics: -> @trigger('show-statistics')
