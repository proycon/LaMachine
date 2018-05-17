'use strict'
module.exports = {
  NODE_ENV: '"production"',
  TITLE: '"{{portal_title}}"',
  DESCRIPTION: '"{{portal_description}}"',
  VERSION: '"0.1.0"',
  REGISTRY_URL: '"{{portal_registry_url}}"',
  LOGO_RIGHT: "true",
  LOGO_LEFT: "true",
  ORGANIZATIONS: '{{portal_organizations|to_json}}',
  DOMAINS: '{{portal_domains|to_json}}'
}
