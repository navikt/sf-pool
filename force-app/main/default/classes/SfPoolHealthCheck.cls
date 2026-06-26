/**
 * Validates that scratch pool metadata is installed and connected correctly.
 */
public with sharing class SfPoolHealthCheck {
    /**
     * Runs all scratch pool health checks.
     *
     * @return True when all checks pass.
     */
    public static Boolean runHealthCheck() {
        Integer numberOfFailedChecks = 0;

        if (!checkRecordTypeId()) {
            numberOfFailedChecks++;
        }

        if (!checkPublicGroupsExist()) {
            numberOfFailedChecks++;
        }

        if (!correctPublicGroupHierarcy()) {
            numberOfFailedChecks++;
        }

        return numberOfFailedChecks == 0;
    }

    /**
     * Checks that the pooled ScratchOrgInfo record type exists.
     *
     * @return True when the Scratch_pool_org record type is available.
     */
    public static Boolean checkRecordTypeId() {
        Id scratchOrgInfoPoolRecordTypeId = SfPoolHelper.getScratchOrgInfoPoolRecordTypeId();
        if (String.isBlank(scratchOrgInfoPoolRecordTypeId)) {
            System.debug(
                LoggingLevel.ERROR,
                'RecordType with DeveloperName "Scratch_pool_org" not found. Please ensure that the RecordType exists.'
            );
            return false;
        }
        return true;
    }

    /**
     * Checks that all required scratch pool public groups exist.
     *
     * @return True when no required public groups are missing.
     */
    public static Boolean checkPublicGroupsExist() {
        List<String> missingGroups = SfPoolGroupHelper.getPublicGroupMissingDeveloperNames();
        if (missingGroups.isEmpty()) {
            return true;
        }
        System.debug(
            LoggingLevel.WARN,
            'The following public groups are missing: ' +
            String.join(missingGroups, ', ')
        );
        return false;
    }

    /**
     * Checks that Scratch_Pool contains the CI, Users, and Admins public groups.
     *
     * @return True when exactly the expected three child groups are members.
     */
    public static Boolean correctPublicGroupHierarcy() {
        List<GroupMember> scratchPoolGroupMember = [
            SELECT Id, UserOrGroupId
            FROM GroupMember
            WHERE
                GroupId = :SfPoolGroupHelper.getGroupIdByDeveloperName(
                    SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
                )
                AND UserOrGroupId IN :SfPoolGroupHelper.getPublicGroupIds()
        ];

        if (scratchPoolGroupMember.isEmpty()) {
            System.debug(
                LoggingLevel.WARN,
                'The public groups are not correctly set up. The Scratch_Pool group should contain the other public groups as members.'
            );
            return false;
        }

        if (scratchPoolGroupMember.size() != 3) {
            List<String> memberDeveloperNames = new List<String>();
            for (GroupMember gm : scratchPoolGroupMember) {
                memberDeveloperNames.add(
                    SfPoolGroupHelper.getDeveloperNameByGroupId(
                        gm.UserOrGroupId
                    )
                );
            }
            SfPoolGroupHelper.getDeveloperNameByGroupId(
                scratchPoolGroupMember[0].UserOrGroupId
            );
            System.debug(
                LoggingLevel.WARN,
                'There should be exactly 3 public groups (Scratch_Pool_CI, Scratch_Pool_Users, Scratch_Pool_Admins) as members of the Scratch_Pool group. Found: ' +
                    scratchPoolGroupMember.size() +
                    '. Members: ' +
                    String.join(memberDeveloperNames, ', ')
            );
            return false;
        }

        return true;
    }
}
