const responder = require('./util/responder');
const controllers = require('../controllers');

module.exports.handler = (event, context, callback) => {
  const {
    client_id,
    scope,
    state,
    response_type,
    redirect_uri
  } = event.queryStringParameters;

  controllers(responder(callback)).authorize(
    client_id,
    scope,
    state,
    response_type,
    redirect_uri
  );
};
