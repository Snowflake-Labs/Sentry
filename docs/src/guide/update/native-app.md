# Native application

Updating a Native Application needs to be done on both provider account (where
the application package is created) and the consumer side (where the application
is installed).

## Application provider account

1. Use `git pull` to incorporate changes from main source code repository into
   your local copy
2. Use `snow app deploy` to propagate changes to the application package
3. [Create an application version and publish it][doc-version]

## Application consumer account

Run `ALTER APPLICATION <appName> UPGRADE` ([doc][doc-alter-upgrade])

[doc-version]: https://docs.snowflake.com/en/developer-guide/native-apps/versioning
[doc-alter-upgrade]: https://docs.snowflake.com/en/developer-guide/native-apps/versioning#perform-a-manual-upgrade-for-an-installed-app
