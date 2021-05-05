const responder = require('./util/responder');
const controllers = require('../controllers');

const { GITHUB_CLIENT_ID } = require('../../config');

module.exports.handler = (event, context, callback) => {
  const {
    scope,
    state,
    response_type,
    redirect_uri
  } = event.queryStringParameters;

  controllers(responder(callback)).authorize(
    GITHUB_CLIENT_ID,
    scope,
    state,
    response_type,
    redirect_uri
  );
};
