@IsTest
private with sharing class SfPoolSharingControllerTest {
    @IsTest
    private static void sharingForInProgress() {
        ScratchOrgInfo testScratchOrgInfo = createTestScratchOrgInfo(
            'in_progress'
        );
        insert testScratchOrgInfo;

        Test.startTest();
        SfPoolSharingController.recalculateSharing(
            new List<Id>{ testScratchOrgInfo.Id }
        );
        Test.stopTest();

        Map<Id, String> access = shareAccessByGroup(testScratchOrgInfo.Id);
        System.Assert.areEqual(
            'Edit',
            access.get(adminGroupId()),
            'Admins should always have Edit.'
        );
        System.Assert.areEqual(
            'Read',
            access.get(poolGroupId()),
            'Pool should have Read when in_progress.'
        );
        System.Assert.areEqual(
            'Edit',
            access.get(ciGroupId()),
            'CI should have Edit when in_progress.'
        );
    }

    @IsTest
    private static void sharingForassigned() {
        ScratchOrgInfo testScratchOrgInfo = createTestScratchOrgInfo(
            'assigned'
        );
        insert testScratchOrgInfo;

        Test.startTest();
        SfPoolSharingController.recalculateSharing(
            new List<Id>{ testScratchOrgInfo.Id }
        );
        Test.stopTest();

        Map<Id, String> access = shareAccessByGroup(testScratchOrgInfo.Id);
        System.Assert.areEqual(
            'Edit',
            access.get(adminGroupId()),
            'Admins should always have Edit.'
        );
        System.Assert.areEqual(
            'Read',
            access.get(poolGroupId()),
            'Pool should have Read when assigned.'
        );
        System.Assert.isFalse(
            access.containsKey(ciGroupId()),
            'CI should not be shared when assigned.'
        );
    }

    @IsTest
    private static void sharingForAvailable() {
        ScratchOrgInfo testScratchOrgInfo = createTestScratchOrgInfo(
            'available'
        );
        insert testScratchOrgInfo;

        Test.startTest();
        SfPoolSharingController.recalculateSharing(
            new List<Id>{ testScratchOrgInfo.Id }
        );
        Test.stopTest();

        Map<Id, String> access = shareAccessByGroup(testScratchOrgInfo.Id);
        System.Assert.areEqual(
            'Edit',
            access.get(adminGroupId()),
            'Admins should always have Edit.'
        );
        System.Assert.areEqual(
            'Edit',
            access.get(poolGroupId()),
            'Pool should have Edit when available.'
        );
        System.Assert.isFalse(
            access.containsKey(ciGroupId()),
            'CI should not be shared when available.'
        );
    }

    @IsTest
    private static void sharingForUnderUpdate() {
        ScratchOrgInfo testScratchOrgInfo = createTestScratchOrgInfo(
            'under_update'
        );
        insert testScratchOrgInfo;

        Test.startTest();
        SfPoolSharingController.recalculateSharing(
            new List<Id>{ testScratchOrgInfo.Id }
        );
        Test.stopTest();

        Map<Id, String> access = shareAccessByGroup(testScratchOrgInfo.Id);
        System.Assert.areEqual(
            'Edit',
            access.get(adminGroupId()),
            'Admins should always have Edit.'
        );
        System.Assert.areEqual(
            'Read',
            access.get(poolGroupId()),
            'Pool should have Read when under_update.'
        );
        System.Assert.areEqual(
            'Edit',
            access.get(ciGroupId()),
            'CI should have Edit when under_update.'
        );
    }

    @IsTest
    private static void sharingForFailed() {
        ScratchOrgInfo testScratchOrgInfo = createTestScratchOrgInfo('failed');
        insert testScratchOrgInfo;

        Test.startTest();
        SfPoolSharingController.recalculateSharing(
            new List<Id>{ testScratchOrgInfo.Id }
        );
        Test.stopTest();

        Map<Id, String> access = shareAccessByGroup(testScratchOrgInfo.Id);
        System.Assert.areEqual(
            'Edit',
            access.get(adminGroupId()),
            'Admins should always have Edit.'
        );
        System.Assert.areEqual(
            'Read',
            access.get(poolGroupId()),
            'Pool should have Read when failed.'
        );
        System.Assert.areEqual(
            'Edit',
            access.get(ciGroupId()),
            'CI should have Edit when failed.'
        );
    }

    @IsTest
    private static void recalculateWithEmptyListCreatesNoShares() {
        Test.startTest();
        Map<Id, SfPoolSharingController.ShareLog> logs = SfPoolSharingController.recalculateSharing(
            new List<Id>()
        );
        Test.stopTest();

        System.Assert.isTrue(
            logs.isEmpty(),
            'No share logs should be produced for an empty input.'
        );
    }

    @IsTest
    private static void recalculateIsIdempotent() {
        ScratchOrgInfo testScratchOrgInfo = createTestScratchOrgInfo(
            'in_progress'
        );
        insert testScratchOrgInfo;
        SfPoolSharingController.recalculateSharing(
            new List<Id>{ testScratchOrgInfo.Id }
        );
        Integer sharesAfterFirstRun = countPoolShares(testScratchOrgInfo.Id);

        Test.startTest();
        SfPoolSharingController.recalculateSharing(
            new List<Id>{ testScratchOrgInfo.Id }
        );
        Test.stopTest();

        System.Assert.areEqual(
            sharesAfterFirstRun,
            countPoolShares(testScratchOrgInfo.Id),
            'Re-running should replace shares, not duplicate them.'
        );
    }

    @IsTest
    private static void recalculateFromFlowCreatesShares() {
        ScratchOrgInfo testScratchOrgInfo = createTestScratchOrgInfo(
            'in_progress'
        );
        insert testScratchOrgInfo;

        SfPoolSharingController.RecalculateSharingRequest request = new SfPoolSharingController.RecalculateSharingRequest();
        request.scratchOrgInfoId = testScratchOrgInfo.Id;

        Test.startTest();
        SfPoolSharingController.recalculateSharingFromFlow(
            new List<SfPoolSharingController.RecalculateSharingRequest>{
                request
            }
        );
        Test.stopTest();

        Map<Id, String> access = shareAccessByGroup(testScratchOrgInfo.Id);
        System.Assert.areEqual(
            'Edit',
            access.get(adminGroupId()),
            'Admins should always have Edit.'
        );
        System.Assert.areEqual(
            'Read',
            access.get(poolGroupId()),
            'Pool should have Read when in_progress.'
        );
        System.Assert.areEqual(
            'Edit',
            access.get(ciGroupId()),
            'CI should have Edit when in_progress.'
        );
    }

    @IsTest
    private static void recalculateFromFlowIgnoresMissingRecordIds() {
        Test.startTest();
        SfPoolSharingController.recalculateSharingFromFlow(
            new List<SfPoolSharingController.RecalculateSharingRequest>{
                new SfPoolSharingController.RecalculateSharingRequest()
            }
        );
        SfPoolSharingController.recalculateSharingFromFlow(null);
        Test.stopTest();
    }

    private static Map<Id, String> shareAccessByGroup(Id scratchOrgInfoId) {
        Map<Id, String> accessByGroup = new Map<Id, String>();
        for (ScratchOrgInfoShare share : [
            SELECT UserOrGroupId, AccessLevel
            FROM ScratchOrgInfoShare
            WHERE
                ParentId = :scratchOrgInfoId
                AND UserOrGroupId IN :SfPoolGroupHelper.getPublicGroupIds()
        ]) {
            accessByGroup.put(share.UserOrGroupId, share.AccessLevel);
        }
        return accessByGroup;
    }

    private static Integer countPoolShares(Id scratchOrgInfoId) {
        return [
            SELECT COUNT()
            FROM ScratchOrgInfoShare
            WHERE
                ParentId = :scratchOrgInfoId
                AND UserOrGroupId IN :SfPoolGroupHelper.getPublicGroupIds()
        ];
    }

    private static Id adminGroupId() {
        return SfPoolGroupHelper.getGroupIdByDeveloperName(
            SfPoolGroupHelper.SCRATCH_POOL_ADMIN_PUBLIC_GROUP_DEVELOPER_NAME
        );
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

    private static ScratchOrgInfo createTestScratchOrgInfo(
        String poolAllocationStatus
    ) {
        ScratchOrgInfo testScratchOrgInfo = new ScratchOrgInfo(
            RecordTypeId = SfPoolHelper.getScratchOrgInfoPoolRecordTypeId(),
            Pool_allocation_status__c = poolAllocationStatus,
            Edition = 'Developer',
            OrgName = 'Test Org',
            DurationDays = 1,
            ConnectedAppConsumerKey = 'PlatformCLI',
            ConnectedAppCallbackUrl = 'http://localhost:1717/OauthRedirect'
        );
        return testScratchOrgInfo;
    }
}
