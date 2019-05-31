#!/bin/sh

set -ex
bin="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# set a default build -> 0 for when it doesn't exist
CIRCLE_BUILD_NUM=${CIRCLE_BUILD_NUM:-0}

# epoch to use for -revision
epoch=$(date +%s)

shortname="drush-extensions"
arch='noarch'
vendor='Pantheon'
description='drush extensions: Pantheon rpm containing additional Drush commands'

drupal_8_site_audit_version=8.x-2.2
drupal_8_registry_rebuild_version=7.x-2.5
drupal_7_site_audit_version=7.x-1.16
drupal_7_registry_rebuild_version=7.x-2.5

name="$shortname"

iteration="$(date +%Y%m%d%H%M)"
url="https://github.com/pantheon-systems/${shortname}"
install_prefix="/etc/drush"
download_dir="$bin/../builds/$name"
target_dir="$bin/../pkgs/$name"

# Add the git SHA hash to the rpm build if the local working copy is clean
if [ -z "$(git diff-index --quiet HEAD --)" ]
then
	GITSHA=$(git log -1 --format="%h")
	iteration=${iteration}.git${GITSHA}
fi

# Make sure we start clean
rm -rf $download_dir
mkdir -p $download_dir

# Determine whether we need to install Drush or not
drush=drush
if [ -z "$(which drush)" ] ; then
	# Get Drush just to use 'drush dl'
	curl -L -f https://github.com/drush-ops/drush/releases/download/8.2.3/drush.phar --output "$bin/drush"
	chmod +x "$bin/drush"
	drush="$bin/drush"
fi


# Download the extensions we need; drop them in the directories they belong in
$drush dl -y site_audit-$drupal_8_site_audit_version --destination="$download_dir/drupal-8-drush-commandfiles/extensions"
$drush dl -y registry_rebuild-$drupal_8_registry_rebuild_version --destination="$download_dir/drupal-8-drush-commandfiles/extensions"
$drush dl -y site_audit-$drupal_7_site_audit_version --destination="$download_dir/drupal-7-drush-commandfiles/extensions"
$drush dl -y registry_rebuild-$drupal_7_registry_rebuild_version --destination="$download_dir/drupal-7-drush-commandfiles/extensions"

# We need to run 'composer install' on site_audit (d7 and d8).
# Site Audit does not have any dependencies that it autoloads, but it does
# exec binary programs from vendor/bin.
composer --working-dir="$download_dir/drupal-8-drush-commandfiles/extensions/site_audit" install --no-dev --ignore-platform-reqs
composer --working-dir="$download_dir/drupal-7-drush-commandfiles/extensions/site_audit" install --ignore-platform-reqs

# Todo: Update to stable release of site-audit-tool
mkdir -p "$download_dir/drush-9-commandfiles/Commands"
composer create-project pantheon-systems/site-audit-tool:^1.1 --working-dir="$download_dir/drush-9-extensions/Commands/site-audit-tool" install --ignore-platform-reqs

# Remove the .git repositories and test directories; we don't want those in our rpm
rm -rf $(find $download_dir -name .git)
rm -rf $(find $download_dir -iname "tests")

mkdir -p "$target_dir"

# Use the Drupal 8 site audit version as our version number.
# Convert from '8.x-2.0' to '8.2.0'.
version=$(echo $drupal_8_site_audit_version | sed -e 's/x-//')

fpm -s dir -t rpm	 \
	--package "$target_dir/${name}-${version}-${iteration}.${arch}.rpm" \
	--name "${name}" \
	--version "${version}" \
	--iteration "${iteration}" \
	--epoch "${epoch}" \
	--architecture "${arch}" \
	--url "${url}" \
	--vendor "${vendor}" \
	--description "${description}" \
	--prefix "$install_prefix" \
	-C $download_dir \
	$(ls $download_dir)

# Finish up by running our tests.
sh $bin/../tests/confirm-rpm.sh $name
