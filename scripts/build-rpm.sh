#!/bin/sh

set -ex
bin="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# set a default build -> 0 for when it doesn't exist
CIRCLE_BUILD_NUM=${CIRCLE_BUILD_NUM:-0}

# epoch to use for -revision
epoch=$(date +%s)

case $CIRCLE_BRANCH in
"master")
	CHANNEL="release"
	;;
"stage")
	CHANNEL="stage"
	;;
"yolo")
	CHANNEL="yolo"
	;;
*)
	CHANNEL="dev"
	;;
esac

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
else
	# Allow non-clean builds in dev mode; for anything else, fail if there
	# are uncommitted changes.
	if [ "$CHANNEL" != "dev" ]
	then
		echo >&2
		echo "Error: uncommitted changes present. Please commit to continue." >&2
		echo "Git commithash is included in rpm, so working tree must be clean to build." >&2
		exit 1
	fi
fi

# Make sure we start clean
rm -rf $download_dir
mkdir -p $download_dir

# Determine whether we need to install Drush or not
drush=drush
if [ -z "$(which drush)" ] ; then
	drush_dir="$bin/../builds/tools"
	mkdir -p "$drush_dir"
	composer --working-dir="$drush_dir" -n require drush/drush:^8
	drush="$drush_dir/vendor/bin/drush"
fi


# Download the extensions we need; drop them in the directories they belong in
$drush dl -y site_audit-$drupal_8_site_audit_version --destination="$download_dir/drupal-8-drush-commandfiles/extensions"
$drush dl -y registry_rebuild-$drupal_8_registry_rebuild_version --destination="$download_dir/drupal-8-drush-commandfiles/extensions"
$drush dl -y site_audit-$drupal_7_site_audit_version --destination="$download_dir/drupal-7-drush-commandfiles/extensions"
$drush dl -y registry_rebuild-$drupal_7_registry_rebuild_version --destination="$download_dir/drupal-7-drush-commandfiles/extensions"

# Todo: Update to stable release of site-audit-tool
mkdir -p "$download_dir/drush-9-commandfiles/Commands"
git clone https://github.com/greg-1-anderson/site-audit-tool.git "$download_dir/drush-9-commandfiles/Commands/site-audit-tool"

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
