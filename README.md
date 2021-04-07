# GitHub OpenID Connect Proxy

This is a proxy that exposes team membership information from Github's OAuth 2.0
interface as an OpenID Connect Authorization Server, with the main aim being to
allow AWS IAM Federated Authentication to grant access to IAM roles based on that
information.

It is originally a fork of https://github.com/TimothyJones/github-cognito-openid-wrapper,
with modifications to support this use-case.
