Backbone = require('backbone')
$ = Backbone.$
_ = require('underscore')

Policies = require('../../lib/Policies')

M = global.Messages.QuestionView

ClickDelay = 400 # ms after a policy goes away before another comes

module.exports = class QuestionView extends Backbone.View
  className: 'question'
  template: _.template("""
    <header><h1>#{M.title}</h1></header>
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
      <button class="show-statistics">#{M.done} <i class="icon icon-caret-right"></i></button>
    </div>
  """)

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
    if @nVotes < 2
      M.progress['<2']
    else if @nVotes < 13
      M.progress['<13'].replace('{}', String(@nVotes))
    else if @nVotes < 20
      M.progress['<20'].replace('{}', String(@nVotes))
    else
      M.progress.else.replace('{}', String(@nVotes))

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
    @$('.choices')
      .css(opacity: 0)
      .animate({ opacity: 1 }, duration: 100)
    @$('button.show-statistics').prop('disabled', @nVotes < 20)
    @

  _onClickChoice: (e) ->
    $(e.currentTarget).addClass('active')
    policyId = $(e.currentTarget).attr('data-policy-id')
    otherPolicyId = $(e.currentTarget).attr('data-other-policy-id')

    @$('button.choice').prop('disabled', true)

    @$('.choices')
      .animate { opacity: 0 }, duration: ClickDelay, easing: 'linear', complete: =>
        @nVotes++
        @trigger('user-prefers-policy', Policies.byId[policyId], Policies.byId[otherPolicyId])

  _onClickShowStatistics: -> @trigger('show-statistics')
