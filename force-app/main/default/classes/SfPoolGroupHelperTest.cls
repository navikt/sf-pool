@IsTest
private with sharing class SfPoolGroupHelperTest {
    @IsTest
    private static void returnsAllPublicGroupDeveloperNames() {
        Set<String> developerNames = SfPoolGroupHelper.getPublicGroupDeveloperNames();

        System.Assert.areEqual(
            4,
            developerNames.size(),
            'There should be 4 public group developer names.'
        );
        System.Assert.isTrue(
            developerNames.contains(
                SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
            ),
            'Should contain Scratch_Pool.'
        );
        System.Assert.isTrue(
            developerNames.contains(
                SfPoolGroupHelper.SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME
            ),
            'Should contain Scratch_Pool_CI.'
        );
        System.Assert.isTrue(
            developerNames.contains(
                SfPoolGroupHelper.SCRATCH_POOL_USERS_PUBLIC_GROUP_DEVELOPER_NAME
            ),
            'Should contain Scratch_Pool_Users.'
        );
        System.Assert.isTrue(
            developerNames.contains(
                SfPoolGroupHelper.SCRATCH_POOL_ADMIN_PUBLIC_GROUP_DEVELOPER_NAME
            ),
            'Should contain Scratch_Pool_Admins.'
        );
    }

    @IsTest
    private static void resolvesGroupIdByDeveloperName() {
        Test.startTest();
        Id groupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
        );
        Test.stopTest();

        System.Assert.isNotNull(
            groupId,
            'Scratch_Pool group Id should be resolved.'
        );
    }

    @IsTest
    private static void returnsNullForUnknownDeveloperName() {
        Id groupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
            'Not_A_Real_Group'
        );

        System.Assert.isNull(
            groupId,
            'Unknown developer name should resolve to null.'
        );
    }

    @IsTest
    private static void returnsAllPublicGroupIds() {
        List<Id> groupIds = SfPoolGroupHelper.getPublicGroupIds();

        System.Assert.areEqual(
            4,
            groupIds.size(),
            'All 4 public groups should be deployed and resolved.'
        );
    }

    @IsTest
    private static void hasNoMissingPublicGroups() {
        List<String> missing = SfPoolGroupHelper.getPublicGroupMissingDeveloperNames();

        System.Assert.isTrue(
            missing.isEmpty(),
            'No public groups should be missing when metadata is deployed.'
        );
    }

    @IsTest
    private static void resolvesDeveloperNameByGroupId() {
        Id groupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME
        );

        String developerName = SfPoolGroupHelper.getDeveloperNameByGroupId(
            groupId
        );

        System.Assert.areEqual(
            SfPoolGroupHelper.SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME,
            developerName,
            'Group Id should round-trip to its developer name.'
        );
    }

    @IsTest
    private static void returnsNullForUnknownGroupId() {
        String developerName = SfPoolGroupHelper.getDeveloperNameByGroupId(
            UserInfo.getUserId()
        );

        System.Assert.isNull(
            developerName,
            'Unknown group Id should resolve to null.'
        );
    }
}
