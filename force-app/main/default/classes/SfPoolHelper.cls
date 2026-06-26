/**
 * Resolves ScratchOrgInfo record types used by scratch org pooling.
 * Record type IDs are loaded once and cached for the current Apex transaction.
 */
public with sharing class SfPoolHelper {
    private static final String SCRATCH_ORG_INFO_POOL_RECORD_TYPE_NAME = 'Scratch_pool_org';
    private static final String SCRATCH_ORG_RECORD_TYPE_NAME = 'Scratch_org';
    private static Id scratchOrgInfoPoolRecordTypeId;
    private static Id scratchOrgRecordTypeId;
    private static Boolean isScratchOrgInfoRecordTypesLoaded = false;

    private static void loadScratchOrgInfoRecordTypes() {
        if (isScratchOrgInfoRecordTypesLoaded) {
            return;
        }

        for (RecordType rt : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE
                DeveloperName IN :(new List<String>{
                    SCRATCH_ORG_INFO_POOL_RECORD_TYPE_NAME,
                    SCRATCH_ORG_RECORD_TYPE_NAME
                })
        ]) {
            if (rt.DeveloperName == SCRATCH_ORG_INFO_POOL_RECORD_TYPE_NAME) {
                scratchOrgInfoPoolRecordTypeId = rt.Id;
            } else if (rt.DeveloperName == SCRATCH_ORG_RECORD_TYPE_NAME) {
                scratchOrgRecordTypeId = rt.Id;
            }
        }

        isScratchOrgInfoRecordTypesLoaded = true;
    }

    /**
     * Returns the record type ID for pooled scratch org records.
     *
     * @return The Scratch_pool_org record type ID, or null when unavailable.
     */
    public static Id getScratchOrgInfoPoolRecordTypeId() {
        if (!isScratchOrgInfoRecordTypesLoaded) {
            loadScratchOrgInfoRecordTypes();
        }
        return scratchOrgInfoPoolRecordTypeId;
    }

    /**
     * Returns the record type ID for ordinary scratch org records.
     *
     * @return The Scratch_org record type ID, or null when unavailable.
     */
    public static Id getScratchOrgRecordTypeId() {
        if (!isScratchOrgInfoRecordTypesLoaded) {
            loadScratchOrgInfoRecordTypes();
        }
        return scratchOrgRecordTypeId;
    }
}
