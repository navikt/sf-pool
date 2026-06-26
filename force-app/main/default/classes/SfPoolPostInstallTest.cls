@IsTest
private with sharing class SfPoolPostInstallTest {
    @IsTest
    private static void runCreatesExpectedPublicGroupHierarchy() {
        clearPoolHierarchy();

        Test.startTest();
        SfPoolPostInstall.run();
        Test.stopTest();

        Set<Id> memberGroupIds = scratchPoolMemberGroupIds();

        System.Assert.areEqual(
            3,
            memberGroupIds.size(),
            'Scratch_Pool should contain exactly the 3 child public groups.'
        );
        System.Assert.isTrue(
            memberGroupIds.contains(ciGroupId()),
            'Scratch_Pool should contain Scratch_Pool_CI.'
        );
        System.Assert.isTrue(
            memberGroupIds.contains(usersGroupId()),
            'Scratch_Pool should contain Scratch_Pool_Users.'
        );
        System.Assert.isTrue(
            memberGroupIds.contains(adminGroupId()),
            'Scratch_Pool should contain Scratch_Pool_Admins.'
        );
    }

    private static void clearPoolHierarchy() {
        delete [
            SELECT Id
            FROM GroupMember
            WHERE
                GroupId = :poolGroupId()
                AND UserOrGroupId IN :SfPoolGroupHelper.getPublicGroupIds()
        ];
    }

    private static Set<Id> scratchPoolMemberGroupIds() {
        Set<Id> memberGroupIds = new Set<Id>();
        for (GroupMember member : [
            SELECT UserOrGroupId
            FROM GroupMember
            WHERE
                GroupId = :poolGroupId()
                AND UserOrGroupId IN :SfPoolGroupHelper.getPublicGroupIds()
        ]) {
            memberGroupIds.add(member.UserOrGroupId);
        }
        return memberGroupIds;
    }

    private static Id poolGroupId() {
        return SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
        );
    }

    private static Id ciGroupId() {
        return SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME
        );
    }

    private static Id usersGroupId() {
        return SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_USERS_PUBLIC_GROUP_DEVELOPER_NAME
        );
    }

    private static Id adminGroupId() {
        return SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_ADMIN_PUBLIC_GROUP_DEVELOPER_NAME
        );
    }
}
