const logger = require('./connectors/logger');
const { NumericDate } = require('./helpers');
const crypto = require('./crypto');
const github = require('./github');

const getJwks = () => ({ keys: [crypto.getPublicKey()] });

const getUserInfo = accessToken =>
  Promise.all([
    github()
      .getUserDetails(accessToken)
      .then(userDetails => {
        logger.debug('Fetched user details: %j', userDetails, {});
        // Here we map the github user response to the standard claims from
        // OpenID. The mapping was constructed by following
        // https://developer.github.com/v3/users/
        // and http://openid.net/specs/openid-connect-core-1_0.html#StandardClaims
        const claims = {
          sub: `${userDetails.id}`, // OpenID requires a string
          name: userDetails.name,
          preferred_username: userDetails.login,
          profile: userDetails.html_url,
          picture: userDetails.avatar_url,
          website: userDetails.blog,
          updated_at: NumericDate(
            // OpenID requires the seconds since epoch in UTC
            new Date(Date.parse(userDetails.updated_at))
          )
        };
        logger.debug('Resolved claims: %j', claims, {});
        return claims;
      }),
    github()
      .getUserEmails(accessToken)
      .then(userEmails => {
        logger.debug('Fetched user emails: %j', userEmails, {});
        const primaryEmail = userEmails.find(email => email.primary);
        if (primaryEmail === undefined) {
          throw new Error('User did not have a primary email address');
        }
        const claims = {
          email: primaryEmail.email,
          email_verified: primaryEmail.verified
        };
        logger.debug('Resolved claims: %j', claims, {});
        return claims;
      }),
   github()
      .getUserTeams(accessToken)
      .then(userTeams => {
        logger.debug('Fetched user teams: %j', userTeams, {});
        const claims = {
          'https://aws.amazon.com/tags': {
            'principal_tags': userTeams.map(({id}) => id).reduce((obj, id) => {
              // why prefix keys with `t`? some minimal namespacing in case we need
              // to cram any other information into this map down the line and also
              // will prevent any systems interpreting the key as an integer and doing
              // funny things with leading zeros etc.
              // eslint-disable-next-line no-param-reassign
              obj[`t${id}`] = ["t"];  // `t` for "true" as we can only have str values
              return obj;
            } , {})
          }
        };
        logger.debug('Resolved claims: %j', claims, {});
        return claims;
      })
  ]).then(claims => {
    const mergedClaims = claims.reduce(
      (acc, claim) => ({ ...acc, ...claim }),
      {}
    );
    logger.debug('Resolved combined claims: %j', mergedClaims, {});
    return mergedClaims;
  });

const getAuthorizeUrl = (client_id, scope, state, response_type, redirect_uri) =>
  github().getAuthorizeUrl(client_id, scope, state, response_type, redirect_uri);

const getTokens = (code, state, host) =>
  github()
    .getToken(code, state)
    .then(githubToken => {
      logger.debug('Got token: %s', githubToken, {});
      // GitHub returns scopes separated by commas
      // But OAuth wants them to be spaces
      // https://tools.ietf.org/html/rfc6749#section-5.1
      // Also, we need to add openid as a scope,
      // since GitHub will have stripped it
      const scope = `openid ${githubToken.scope.replace(',', ' ')}`;

      // ** JWT ID Token required fields **
      // iss - issuer https url
      // aud - audience that this token is valid for (GITHUB_CLIENT_ID)
      // sub - subject identifier - must be unique
      // ** Also required, but provided by jsonwebtoken **
      // exp - expiry time for the id token (seconds since epoch in UTC)
      // iat - time that the JWT was issued (seconds since epoch in UTC)

      return new Promise(async (resolve) => {
        // TODO error handling
        const payload = await getUserInfo(githubToken.access_token);

        const idToken = crypto.makeIdToken(payload, host);
        logger.info('Generated id token for subject %s', payload.sub, {});
        const tokenResponse = {
          ...githubToken,
          scope,
          id_token: idToken
        };

        logger.debug('Resolved token response: %j', tokenResponse, {});

        resolve(tokenResponse);
      });
    });

const getConfigFor = host => ({
  issuer: `https://${host}`,
  authorization_endpoint: `https://${host}/authorize`,
  token_endpoint: `https://${host}/token`,
  token_endpoint_auth_methods_supported: [
    'client_secret_basic',
    'private_key_jwt'
  ],
  token_endpoint_auth_signing_alg_values_supported: ['RS256'],
  userinfo_endpoint: `https://${host}/userinfo`,
  // check_session_iframe: 'https://server.example.com/connect/check_session',
  // end_session_endpoint: 'https://server.example.com/connect/end_session',
  jwks_uri: `https://${host}/.well-known/jwks.json`,
  // registration_endpoint: 'https://server.example.com/connect/register',
  scopes_supported: ['openid', 'read:user', 'user:email', 'read:org'],
  response_types_supported: [
    'code',
    'code id_token',
    'id_token',
    'token id_token'
  ],

  subject_types_supported: ['public'],
  userinfo_signing_alg_values_supported: ['none'],
  id_token_signing_alg_values_supported: ['RS256'],
  request_object_signing_alg_values_supported: ['none'],
  display_values_supported: ['page', 'popup'],
  claims_supported: [
    'sub',
    'name',
    'preferred_username',
    'profile',
    'picture',
    'website',
    'email',
    'email_verified',
    'updated_at',
    'iss',
    'aud',
    'https://aws.amazon.com/tags'
  ]
});

module.exports = {
  getTokens,
  getUserInfo,
  getJwks,
  getConfigFor,
  getAuthorizeUrl
};
