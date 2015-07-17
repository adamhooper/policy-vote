class Province
  constructor: (@code, @en, @fr) ->

all = [
  new Province('ab', 'Alberta', 'Alberta')
  new Province('bc', 'British Columbia', 'Colombie-Britannique')
  new Province('mb', 'Manitoba', 'Manitoba')
  new Province('nb', 'New Brunswick', 'Nouveau-Brunswick')
  new Province('nl', 'Newfoundland and Labrador', 'Terre-Neuve-et-Labrador')
  new Province('ns', 'Nova Scotia', 'Nouvelle-Écosse')
  new Province('nt', 'Northwest Territories', 'Territoires du Nord-Ouest')
  new Province('nu', 'Nunavut', 'Nunavut')
  new Province('on', 'Ontario', 'Ontario')
  new Province('pe', 'Prince Edward Island', 'Île-du-Prince-Édouard')
  new Province('qc', 'Quebec', 'Québec')
  new Province('sk', 'Saskatchewan', 'Saskatchewan')
  new Province('yt', 'Yukon', 'Yukon')
]

byCode = {}
(byCode[province.code] = province) for province in all

module.exports =
  all: all
  byCode: byCode
