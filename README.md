# sf-pool

Unlocked package with Salesforce metadata and Apex used to run scratch org pools.

This package is meant to be installed in the Salesforce org that hosts the pool. Day-to-day pool operations are handled by [navikt/sf-cli-plugin-pool](https://github.com/navikt/sf-cli-plugin-pool/), which uses the metadata and sharing setup provided by this repository.

## What the package contains

- `ScratchOrgInfo` metadata for pooled scratch orgs, including record types, pool status fields, claim token support, and auth URL storage.
- Public groups for pool access: `Scratch_Pool`, `Scratch_Pool_CI`, `Scratch_Pool_Users`, and `Scratch_Pool_Admins`.
- Permission sets for pool operations such as fetch, list, prepare, and clean.
- Apex helpers for record type lookup, public group lookup, install health checks, post-install setup, and sharing recalculation.

## Post install

The post-install step runs `SfPoolPostInstall.run()`.

It creates the public group hierarchy that cannot be fully represented as package metadata by adding these groups as members of `Scratch_Pool`:

- `Scratch_Pool_CI`
- `Scratch_Pool_Users`
- `Scratch_Pool_Admins`

Run `SfPoolHealthCheck.runHealthCheck()` after install if you need to verify that the record type, public groups, and group hierarchy are available.

## What the code does

`SfPoolGroupHelper` resolves the package public groups by developer name and caches the lookups for the current Apex transaction.

`SfPoolHelper` resolves the `Scratch_pool_org` and `Scratch_org` record type IDs for `ScratchOrgInfo`.

`SfPoolHealthCheck` validates that the package metadata needed by the pool is available in the org.

`SfPoolPostInstall` connects the child public groups to the parent `Scratch_Pool` group.

`SfPoolSharingController` recalculates manual shares for pooled `ScratchOrgInfo` records based on `Pool_allocation_status__c`:

| Status         | Scratch_Pool_Admins | Scratch_Pool | Scratch_Pool_CI |
| -------------- | ------------------- | ------------ | --------------- |
| `in_progress`  | Edit                | Read         | Edit            |
| `available`    | Edit                | Edit         | -               |
| `under_update` | Edit                | Read         | Edit            |
| `failed`       | Edit                | Read         | Edit            |
| `assigned`     | Edit                | Read         | -               |

## Development

Prerequisites:

- Node.js LTS
- pnpm
- Salesforce CLI (`sf`)

Install dependencies:

```sh
pnpm install
```

Check formatting:

```sh
pnpm prettier:check
```

Run JavaScript unit tests:

```sh
pnpm test
```

Run Apex tests in an org where the package metadata is deployed:

```sh
sf apex run test --test-level RunSpecifiedTests --tests SfPoolGroupHelperTest,SfPoolHealthCheckTest,SfPoolHelperTest,SfPoolPostInstallTest,SfPoolSharingControllerTest --result-format human --wait 10
```

## Henvendelser

Spørsmål knyttet til koden eller prosjektet kan stilles som issues her på GitHub.

## For NAV-ansatte

Interne henvendelser kan sendes via Slack i kanalen `#platforce`.
