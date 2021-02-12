'use strict'
module.exports = {
  NODE_ENV: '"production"',
  TITLE: '"{{portal_title}}"',
  DESCRIPTION: '"{{portal_description}}"',
  REGISTRY_URL: '"{{portal_registry_url}}"',
  REMOTE_REGISTRIES: '{{portal_remote_registries|to_json}}',
  REMOTE_INCLUDE: '{{portal_remote_include|to_json}}',
  REMOTE_EXCLUDE: '{{portal_remote_exclude|to_json}}',
  BASE: '"{{portal_base}}"',
  LOGO_RIGHT: "true",
  LOGO_LEFT: "true",
  ORGANIZATIONS: '{{portal_organizations|to_json}}',
  REWRITE_HOST: '"{{hostname}}"',
  FORCE_HTTPS: "{{force_https|bool}}",
  DOMAINS: '{{portal_domains|to_json}}'
}
