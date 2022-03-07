# RPMs for Drush Extensions

[![Deprecated](https://img.shields.io/badge/Pantheon-Deprecated-yellow?logo=pantheon&color=FFDC28)](https://pantheon.io/docs/oss-support-levels#deprecated)

This repository builds RPMs for the drush extensions used at Pantheon.

The RPM filenames built by this repository are formatted:
```
drush-extensions-201607081150.gitc14c267.noarch.rpm
{     name     }-{iteration }.{ commit }.{arch}.rpm
```
The iteration number is a timestamp (year month day hour minute). The build script will refuse to make an RPM when there are uncommitted changes to the working tree, since the commit hash is included in the RPM name.

This rpm contains:

- Drupal 8 extensions
  - Site audit
    - drush dl site_audit-8.x-2.0
  - Registry rebuild
    - drush dl registry_rebuild-7.x-2.3
- Drupal 7 extensions (also used by Drupal 6)
  - Site audit
    - drush dl site_audit-7.x-1.15
  - Registry rebuild
    - drush dl registry_rebuild-7.x-2.3

For Drush 8, these extensions are placed in an installation directory that varies by the Drupal version:

- /etc/drush/drupal-8-drush-commandfiles/extensions
- /etc/drush/drupal-7-drush-commandfiles/extensions

The site audit tool is also placed in locations specific to Drush 9 / Drush 10:

- /etc/drush/drush-9-extensions/Commands
- /etc/drush/drush-10-extensions/Commands

Note that for historic reasons, the extensions for Drush 5 are included in the RPM for Drush 5, and are inserted directly into Drush 5's `commands` directory (/opt/drush5/commands). No further updates are anticipated to Drush 5, or the Drush 5 extensions.

## Releasing to Package Cloud

Any time a commit is merged on a tracked branch, then a drush extensions RPM is built and pushed up to Package Cloud.

Branch       | Target
------------ | ---------------
master       | pantheon/internal/fedora/#
PR           | pantheon/internal-staging/fedora/#

In the table above, # is the fedora build number (22). Note that drush is only installed on app servers, and there are no app servers on anything prior to f22; therefore, at the moment, we are only publishing for f22. Note also that these are noarch RPMs.

To release new versions of drush extensions, simply update the VERSIONS.txt file and commit. Run `make all`. Push to one of the branches above to have an official RPM built and pushed to Package Cloud via Circle CI.

## Provisioning drush on Pantheon

Pantheon will automatically install any new RPM that is deployed to Package Cloud. This is controlled by [pantheon-cookbooks/drush](https://github.com/pantheon-cookbooks/drush/blob/master/recipes/default.rb).
