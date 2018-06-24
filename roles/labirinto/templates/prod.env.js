'use strict'
module.exports = {
  NODE_ENV: '"production"',
  TITLE: '"{{portal_title}}"',
  DESCRIPTION: '"{{portal_description}}"',
  REGISTRY_URL: '"{{portal_registry_url}}"',
  BASE: '"{{portal_base}}"',
  LOGO_RIGHT: "true",
  LOGO_LEFT: "true",
  ORGANIZATIONS: '{{portal_organizations|to_json}}',
  REWRITE_HOST: '"{{hostname}}"',
  DOMAINS: '{{portal_domains|to_json}}'
}
