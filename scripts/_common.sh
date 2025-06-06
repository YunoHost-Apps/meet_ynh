#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================
nodejs_version=22

dex_ynh_commit=20100712eb168290ca0f34784bf0c2a95fbfa4f2

install_dex() {
  local dex_domain_path
  local dex_domain_path_no_trailing_slash

  oidc_secret=$(ynh_string_random -l 32)
  oidc_name="$app"
  oidc_callback="$domain/api/v1.0/callback/"

  if yunohost app list | grep -q "$dex_domain$dex_path"; then
    ynh_die "The domain provided for Dex is already used by another app. Please choose another one!"
  fi

  # Make sure that the Dex version is compatible
  dex_version=$(yunohost app info $dex --output-as json | jq -r '.version')
  if [ $(dpkg --compare-versions "${dex_version#v}" lt "2.42.1~ynh4") ]; then
    ynh_die "You need to upgrade $dex to v2.42.1~ynh4 and above first."
  fi

  # Prepare the variables
  dex_install_dir="$(ynh_app_setting_get --app $dex --key install_dir)"
  dex_domain="$(ynh_app_setting_get --app $dex --key domain)"
  dex_path="$(ynh_app_setting_get --app $dex --key path)"
  oidc_callback="https://$domain${path%/}/api/v1.0/callback/"

  # Create Dex URIs
  dex_domain_path="${dex_domain}${dex_path}"

  # Doc for the trick below:
  # https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
  dex_domain_path_no_trailing_slash="${dex_domain_path%/}"

  dex_auth_uri="https://${dex_domain_path_no_trailing_slash}/auth"
  dex_token_uri="https://${dex_domain_path_no_trailing_slash}/token"
  dex_keys_uri="https://${dex_domain_path_no_trailing_slash}/keys"
  dex_user_uri="https://${dex_domain_path_no_trailing_slash}/userinfo"

  # Store the variables
  ynh_app_setting_set         --key=dex_install_dir       --value="$dex_install_dir"
  ynh_app_setting_set         --key=dex_user_uri          --value="$dex_user_uri"
  ynh_app_setting_set         --key=dex_auth_uri          --value="$dex_auth_uri"
  ynh_app_setting_set         --key=dex_keys_uri          --value="$dex_keys_uri"
  ynh_app_setting_set         --key=dex_token_uri         --value="$dex_token_uri"
  ynh_app_setting_set_default --key=oidc_name             --value="$app"
  ynh_app_setting_set         --key=oidc_callback         --value="$oidc_callback"
  ynh_app_setting_set_default --key=oidc_secret           --value="$(ynh_string_random --length=32 --filter='A-F0-9')"

  # Add the configuration file for the app in Dex
  bash "$dex_install_dir/add_config.sh" $app $oidc_name $oidc_callback $oidc_secret
}
