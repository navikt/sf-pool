@IsTest
private with sharing class SfPoolHealthCheckTest {
    @IsTest
    private static void checkRecordTypeIdReturnsTrue() {
        Test.startTest();
        Boolean result = SfPoolHealthCheck.checkRecordTypeId();
        Test.stopTest();

        System.Assert.isTrue(
            result,
            'Scratch_pool_org RecordType should exist.'
        );
    }

    @IsTest
    private static void checkPublicGroupsExistReturnsTrue() {
        Test.startTest();
        Boolean result = SfPoolHealthCheck.checkPublicGroupsExist();
        Test.stopTest();

        System.Assert.isTrue(
            result,
            'All public groups should exist when metadata is deployed.'
        );
    }

    @IsTest
    private static void hierarchyIsIncorrectWithoutMembers() {
        clearPoolHierarchy();

        Test.startTest();
        Boolean result = SfPoolHealthCheck.correctPublicGroupHierarcy();
        Test.stopTest();

        System.Assert.isFalse(
            result,
            'Hierarchy should be incorrect when Scratch_Pool has no member groups.'
        );
    }

    @IsTest
    private static void hierarchyIsCorrectWithThreeMembers() {
        insertPoolHierarchy();

        Test.startTest();
        Boolean result = SfPoolHealthCheck.correctPublicGroupHierarcy();
        Test.stopTest();

        System.Assert.isTrue(
            result,
            'Hierarchy should be correct when the 3 member groups belong to Scratch_Pool.'
        );
    }

    @IsTest
    private static void runHealthCheckSucceedsWithCompleteSetup() {
        insertPoolHierarchy();

        Test.startTest();
        Boolean result = SfPoolHealthCheck.runHealthCheck();
        Test.stopTest();

        System.Assert.isTrue(
            result,
            'Health check should pass when record types, groups and hierarchy are correct.'
        );
    }

    @IsTest
    private static void hierarchyIsIncorrectWithWrongMemberCount() {
        clearPoolHierarchy();
        Id scratchPoolGroupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
        );
        insert new GroupMember(
            GroupId = scratchPoolGroupId,
            UserOrGroupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
                SfPoolGroupHelper.SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME
            )
        );

        Test.startTest();
        Boolean result = SfPoolHealthCheck.correctPublicGroupHierarcy();
        Test.stopTest();

        System.Assert.isFalse(
            result,
            'Hierarchy should be incorrect when fewer than 3 member groups belong to Scratch_Pool.'
        );
    }

    @IsTest
    private static void runHealthCheckFailsWithIncompleteHierarchy() {
        clearPoolHierarchy();

        Test.startTest();
        Boolean result = SfPoolHealthCheck.runHealthCheck();
        Test.stopTest();

        System.Assert.isFalse(
            result,
            'Health check should fail when the public group hierarchy is incomplete.'
        );
    }

    @IsTest
    private static void constructorIsCovered() {
        Test.startTest();
        SfPoolHealthCheck instance = new SfPoolHealthCheck();
        Test.stopTest();

        System.Assert.isNotNull(instance, 'Instance should be constructible.');
    }

    private static void clearPoolHierarchy() {
        Id scratchPoolGroupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
        );
        delete [
            SELECT Id
            FROM GroupMember
            WHERE
                GroupId = :scratchPoolGroupId
                AND UserOrGroupId IN :SfPoolGroupHelper.getPublicGroupIds()
        ];
    }

    private static void insertPoolHierarchy() {
        clearPoolHierarchy();

        Id scratchPoolGroupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
        );

        List<GroupMember> members = new List<GroupMember>{
            new GroupMember(
                GroupId = scratchPoolGroupId,
                UserOrGroupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
                    SfPoolGroupHelper.SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME
                )
            ),
            new GroupMember(
                GroupId = scratchPoolGroupId,
                UserOrGroupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
                    SfPoolGroupHelper.SCRATCH_POOL_USERS_PUBLIC_GROUP_DEVELOPER_NAME
                )
            ),
            new GroupMember(
                GroupId = scratchPoolGroupId,
                UserOrGroupId = SfPoolGroupHelper.getGroupIdByDeveloperName(
                    SfPoolGroupHelper.SCRATCH_POOL_ADMIN_PUBLIC_GROUP_DEVELOPER_NAME
                )
            )
        };
        insert members;
    }
}
