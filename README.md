# sf-pool

Salesforce metadata and Apex used to run scratch org pools.

This repository is the source of truth for the pool metadata. It does not publish a shared package version, and the committed `sfdx-project.json` is intentionally package-neutral. Consumers can either deploy the metadata directly or create their own org-dependent unlocked package in their own Dev Hub.

Day-to-day pool operations are handled by [navikt/sf-cli-plugin-pool](https://github.com/navikt/sf-cli-plugin-pool/), which uses the metadata and sharing setup provided by this repository.

## What the repository contains

- `ScratchOrgInfo` metadata for pooled scratch orgs, including record types, pool status fields, claim token support, and auth URL storage.
- Public groups for pool access: `Scratch_Pool`, `Scratch_Pool_CI`, `Scratch_Pool_Users`, and `Scratch_Pool_Admins`.
- Permission sets for pool operations such as fetch, list, prepare, and clean.
- Apex helpers for record type lookup, public group lookup, setup health checks, group hierarchy setup, and sharing recalculation.

## Installation

Choose one installation model per consumer. If you need package versioning and upgrades, create the package in your own Dev Hub. If you only need the metadata in one org, deploy the source directly.

### Option A: Direct source deploy

Use direct deploy when you do not need unlocked package versioning.

```sh
sf org login web --alias pool-host
sf project deploy start --source-dir force-app --target-org pool-host
```

Run the setup Apex after deployment. This creates the public group hierarchy that cannot be fully represented as metadata.

```sh
printf 'SfPoolPostInstall.run();\n' > /tmp/sf-pool-post-install.apex
sf apex run --target-org pool-host --file /tmp/sf-pool-post-install.apex
```

Run the health check and confirm that it returns `true` in the debug output.

```sh
printf 'System.debug(SfPoolHealthCheck.runHealthCheck());\n' > /tmp/sf-pool-health-check.apex
sf apex run --target-org pool-host --file /tmp/sf-pool-health-check.apex
```

### Option B: Consumer-owned unlocked package

Use this model when you want package versioning. The package and all package versions are owned by the Dev Hub where you run `sf package create`. Keep using the same Dev Hub package lineage for upgrades.

```sh
sf org login web --alias consumer-devhub --set-default-dev-hub

sf package create \
	--name sf-pool \
	--package-type Unlocked \
	--path force-app \
	--org-dependent \
	--no-namespace \
	--target-dev-hub consumer-devhub
```

Create a package version from this source. Use an installation key instead of `--installation-key-bypass` if you need to restrict who can install the package.

```sh
sf package version create \
	--package sf-pool \
	--path force-app \
	--definition-file config/project-scratch-def.json \
	--installation-key-bypass \
	--version-name "sf-pool 0.1" \
	--version-number 0.1.0.NEXT \
	--version-description "Scratch org pool metadata" \
	--wait 30 \
	--target-dev-hub consumer-devhub
```

Check the package version create request until it succeeds, then promote the package version.

```sh
sf package version create report --package-create-request-id 08c... --target-dev-hub consumer-devhub
sf package version promote --package 04t... --no-prompt --target-dev-hub consumer-devhub
```

Install the promoted package version into the org that hosts the scratch org pool.

```sh
sf org login web --alias pool-host

sf package install \
	--package 04t... \
	--target-org pool-host \
	--publish-wait 30 \
	--wait 30 \
	--no-prompt
```

Run the setup Apex after package install, then run the health check.

```sh
printf 'SfPoolPostInstall.run();\n' > /tmp/sf-pool-post-install.apex
sf apex run --target-org pool-host --file /tmp/sf-pool-post-install.apex

printf 'System.debug(SfPoolHealthCheck.runHealthCheck());\n' > /tmp/sf-pool-health-check.apex
sf apex run --target-org pool-host --file /tmp/sf-pool-health-check.apex
```

### Package ownership

Do not commit consumer-specific package IDs, package aliases, or package version IDs to this repository. Keep `0Ho...` and `04t...` values in the consumer Dev Hub, consumer pipeline secrets, a private fork, or local configuration. If `sf package create` updates `sfdx-project.json` locally, treat that as consumer-owned state.

This repository does not run packaging from GitHub Actions. Consumers that want package automation should run it in their own pipeline with their own Dev Hub secrets.

## Setup after install or deploy

Run `SfPoolPostInstall.run()` after source deploy or package install.

It creates the public group hierarchy that cannot be fully represented as package metadata by adding these groups as members of `Scratch_Pool`:

- `Scratch_Pool_CI`
- `Scratch_Pool_Users`
- `Scratch_Pool_Admins`

Run `SfPoolHealthCheck.runHealthCheck()` afterward to verify that the record type, public groups, and group hierarchy are available.

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
