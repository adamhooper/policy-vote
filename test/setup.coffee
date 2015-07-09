process.env.NODE_ENV = 'test'

global.app = require('../app/app')
global.expect = require('chai').expect
global.sinon = require('sinon')
require('chai').use(require('sinon-chai'))
