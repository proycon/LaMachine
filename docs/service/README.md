# LaMachine as a service

A default LaMachine installation offers a single-user environment with little
to no authentication for most services. The services it exposes should
therefore not to be exposed to the public internet.

LaMachine does have all the facilities for a proper multi-user environment, and
this is what you will want in a proper production environment where you aim to
offer it as a service. In that case you will need to set up authentication as
described in this document.

## Encryption Handling and Reverse proxy

LaMachine serves traffic over HTTP by default, this is not secure for
production environments. In production scenarios, you need your own
reverse proxy server that handles HTTPS and forwards the traffic to the HTTP
server in LaMachine. Handling HTTPS within LaMachine itself is not supported.

HTTPS is a prerequisite for authentication. We also assume you have a dedicated
domain/subdomain for your LaMachine installation.

You will need to configure the URL and hostname in your LaMachine instance as follows. You can edit your configuration
interactively through ``lamachine-config --edit``:

```yaml
lm_base_url: https://your.domain
hostname: your.domain
force_https: yes
```

The ``force_https`` setting is crucial to ensure LaMachine knows it is behind a reverse proxy that handles the
encryption, it is also used to indicate to underlying software that they can read the ``X-Forwarded-Host`` header to
find the original requested host.

## OpenID Connect

LaMachine supports OpenID Connect, an extension on top of OAuth2, as a means to authenticate against an *external*
single-sign-on authentication provider. LaMachine itself does not offer any integrated authentication provider (although
some the software in it may).

You can configure OpenID Connect in the LaMachine configuration and
LaMachine will propagate these parameters to all underlying services
that support OpenID Connect.

Below is an example configuration for authentication against CLARIAH's authentication server.

```yaml
#shared oauth2 client ID
oauth_client_id: "<your client id here>"

#shared oauth2 client secret (always keep this private)
oauth_client_secret: "<your client secret here>"

oauth_auth_url: "https://authentication.clariah.nl/Saml2/OIDC/authorization"
oauth_token_url: "https://authentication.clariah.nl/OIDC/token"
oauth_userinfo_url: "https://authentication.clariah.nl/OIDC/userinfo"

#Scope for OpenID Connect
oauth_scope: [ "openid", "email" ]

#Key signing algorithm for OpenID Connect, can be RS256 or HS256
oauth_sign_algo: "RS256"

#used by OpenID Connect to obtain a signing key automatically (usually in combination with RS256 algorithm)
#oauth_jwks_url "https://authentication.clariah.nl/OIDC/jwks"

#Or... specify the key manually:
oauth_sign_key: { "kty": "RSA", "use": "sig", "alg": "RS256", "n": "64Aqjpp25auuL0Sh5vYc0RrqQ_kpLqfcjo6gpzIE_GI3xiJrxygvXvKgADXgRN03PEQFAIDDH-C_STgYXcOPFvrC6Hh48Cd0t21ScLemfx_PJzHPKj94nislYhlMN5v9X_Ol3lKL1uab6UrbPXPyudKiniviiq03H9eJMXeekoD_W-dT8MNxSb9Aj3sjJ0KWHIW6oFcChSaG-EnWrsvi_DO0cpasgtuB6BiR3HMm4CUdj2SM8jq2oLfpT8yWN4KsjYmMBAXQW8xh3fDwzq5DJ789cSwdPYX1Yp-LMxAq1TJM0oJhtrq81h9YFyue6ILvyGvrDALL50T1OxKXNTsEaQ", "e": "AQAB" }
```

You will need to register a client ID and client secret with your authentication provider. You will also need to
register so-called redirect/callback URLs.  All services within a LaMachine installation will share the same ID/Secret,
so it is important that your OpenID Connect provider supports multiple redirect URLs. For LaMachine, the URLs to
register depend a bit on what services you have installed in LaMachine. The following lists the most prominent ones but
is not necessarily exhaustive:

```
https://your.domain/frog/login
https://your.domain/ucto/login
https://your.domain/alpino/login
https://your.domain/piccl/login
https://your.domain/spacy/login
https://your.domain/colibricore/login
https://your.domain/piereling/login
https://your.domain/flat/oidc/callback/
```







