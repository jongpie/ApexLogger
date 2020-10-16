# Nebula Logger for Salesforce Apex, Lightning Components, Process Builder & Flow

[![Travis CI](https://img.shields.io/travis/jongpie/NebulaLogger/master.svg)](https://travis-ci.org/jongpie/NebulaLogger)

<a href="https://githubsfdeploy.herokuapp.com" target="_blank">
    <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

Designed for Salesforce admins & developers.

## Features

A robust logger for Salesforce that's simple to implement & configurable at the org, profile & user level.

1. Generates 1 log per transaction that can be permanently stored in Salesforce
2. Supports adding log entries via Apex, Process Builder & Flow
3. Supports adding both debug & exception log entries to the log
4. Supports adding log entries as debug statements in Salesforce's [Debug Log](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_debugging_debug_log.htm)
5. Supports specifying a logging level for each log entry
6. Allows logging to be enabled/disabled for different users & profiles
7. Allows logging level to be configured for each user/profile
8. Allows different debug & exception log entries to be disabled/ignored without making code changes

## Contributing / Development

Contributions to Nebula Logger are welcome, however we ask that Apex Prettier be run on prior to any pull requests being submitted to this repo.

When developing, to get started:

-   run `npm -i` or `npm install` or `yarn` to grab the latest version of our dependencies
-   when using VS Code: ensure that your "Format On Save" editor option is set to `true` (in `settings.json`: `"editor.formatOnSave": true`)
-   all unit tests should be run and passing prior to submitting a PR. We understand that you may be developing on a sandbox / Developer Edition org, and that you may have test classes other than the ones included with Nebula Logger on your org. You can use `npm run test` or `yarn test` to run _only_ the unit tests associated with Nebula Logger in your org
