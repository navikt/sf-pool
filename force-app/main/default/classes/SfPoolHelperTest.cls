@IsTest
private with sharing class SfPoolHelperTest {
    @IsTest
    private static void returnsScratchOrgInfoPoolRecordTypeId() {
        Test.startTest();
        Id recordTypeId = SfPoolHelper.getScratchOrgInfoPoolRecordTypeId();
        Test.stopTest();

        System.Assert.isNotNull(
            recordTypeId,
            'Scratch_pool_org RecordType Id should be resolved.'
        );
    }

    @IsTest
    private static void returnsScratchOrgRecordTypeId() {
        Test.startTest();
        Id recordTypeId = SfPoolHelper.getScratchOrgRecordTypeId();
        Test.stopTest();

        System.Assert.isNotNull(
            recordTypeId,
            'Scratch_org RecordType Id should be resolved.'
        );
    }

    @IsTest
    private static void recordTypesAreCachedAfterFirstLoad() {
        SfPoolHelper.getScratchOrgInfoPoolRecordTypeId();

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        SfPoolHelper.getScratchOrgInfoPoolRecordTypeId();
        SfPoolHelper.getScratchOrgRecordTypeId();
        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        System.Assert.areEqual(
            queriesBefore,
            queriesAfter,
            'Record types should be cached and not re-queried.'
        );
    }
}
