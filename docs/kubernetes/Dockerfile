FROM proycon/lamachine:core
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>:
LABEL description="A LaMachine Docker container template"
RUN lamachine-config lm_base_url https://your.domain &&\
RUN lamachine-config hostname your.domain &&\
    lamachine-config force_https yes &&\
    lamachine-config maintainer_name "Your name here" &&\
    lamachine-config maintainer_mail "your@mail.here" &&\
    #--- OpenID Connect Configuration ---:
    lamachine-config oauth_client_id "<your client id here>" &&\
    lamachine-config oauth_client_secret "<your client secret here>" &&\
    lamachine-config oauth_auth_url "https://authentication.clariah.nl/Saml2/OIDC/authorization" &&\
    lamachine-config oauth_token_url "https://authentication.clariah.nl/OIDC/token" &&\
    lamachine-config oauth_userinfo_url "https://authentication.clariah.nl/OIDC/userinfo" &&\
    lamachine-config oauth_scope '[ "openid", "email" ]' &&\
    lamachine-config oauth_sign_algo "RS256" &&\
    #lamachine-config oauth_jwks_url "https://authentication.clariah.nl/OIDC/jwks" &&\
    lamachine-config oauth_sign_key '{ "kty": "RSA", "use": "sig", "alg": "RS256", "n": "64Aqjpp25auuL0Sh5vYc0RrqQ_kpLqfcjo6gpzIE_GI3xiJrxygvXvKgADXgRN03PEQFAIDDH-C_STgYXcOPFvrC6Hh48Cd0t21ScLemfx_PJzHPKj94nislYhlMN5v9X_Ol3lKL1uab6UrbPXPyudKiniviiq03H9eJMXeekoD_W-dT8MNxSb9Aj3sjJ0KWHIW6oFcChSaG-EnWrsvi_DO0cpasgtuB6BiR3HMm4CUdj2SM8jq2oLfpT8yWN4KsjYmMBAXQW8xh3fDwzq5DJ789cSwdPYX1Yp-LMxAq1TJM0oJhtrq81h9YFyue6ILvyGvrDALL50T1OxKXNTsEaQ", "e": "AQAB" }' &&\
    #--- Packages to install ---:
    lamachine-add languagemachines-basic languagemachines-python labirinto jupyter
RUN lamachine-update
ENTRYPOINT [ "/usr/local/bin/lamachine-start-webserver", "-f" ]
