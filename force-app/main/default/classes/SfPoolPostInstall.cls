public with sharing class SfPoolPostInstall {
    private SfPoolGroupHelper groupHelper;

    private SfPoolPostInstall() {
        runPostInstall();
    }

    private boolean runPostInstall() {
        List<GroupMember> groupMembersToInsert = new List<GroupMember>();
        groupMembersToInsert.add(
            createGroupMember(
                SfPoolGroupHelper.SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME
            )
        );
        groupMembersToInsert.add(
            createGroupMember(
                SfPoolGroupHelper.SCRATCH_POOL_USERS_PUBLIC_GROUP_DEVELOPER_NAME
            )
        );
        groupMembersToInsert.add(
            createGroupMember(
                SfPoolGroupHelper.SCRATCH_POOL_ADMIN_PUBLIC_GROUP_DEVELOPER_NAME
            )
        );

        insert groupMembersToInsert;
        return true;
    }

    private GroupMember createGroupMember(String publicGroupDeveloperName) {
        Id scratchPoolGroupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
        );
        Id groupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
            publicGroupDeveloperName
        );

        if (scratchPoolGroupId == null || groupId == null) {
            System.debug(
                LoggingLevel.WARN,
                'Cannot create GroupMember. One or both group IDs are null. scratchPoolGroupId: ' +
                    scratchPoolGroupId +
                    ', groupId: ' +
                    groupId
            );
            return null;
        }

        return new GroupMember(
            GroupId = scratchPoolGroupId,
            UserOrGroupId = groupId
        );
    }
}
