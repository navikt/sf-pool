/**
 * Recalculates manual sharing for pooled ScratchOrgInfo records.
 */
public with sharing class SfPoolSharingController {
    private static final String EDIT_ACCESS_LEVEL = 'Edit';
    private static final String READ_ACCESS_LEVEL = 'Read';

    private List<Id> scratchOrgInfoIds;
    private Id scratchOrgInfoPoolRecordTypeId;
    Map<Id, ActiveScratchOrg> activeScratchOrgsByScratchOrgInfoId;
    Map<Id, ScratchOrgInfo> scratchOrgInfoMap;
    Map<Id, ShareLog> shareLogs;

    private SfPoolSharingController(List<Id> scratchOrgInfoIds) {
        this.scratchOrgInfoIds = scratchOrgInfoIds;
        this.shareLogs = new Map<Id, ShareLog>();
        this.scratchOrgInfoPoolRecordTypeId = SfPoolHelper.getScratchOrgInfoPoolRecordTypeId();
        loadScratchOrgInfos();
    }

    private void recalculate() {
        if (
            this.scratchOrgInfoIds == null || this.scratchOrgInfoIds.isEmpty()
        ) {
            return;
        }
        List<ScratchOrgInfoShare> sharesToInsert = new List<ScratchOrgInfoShare>();
        deleteScratchOrgInfoShares(this.scratchOrgInfoIds);

        for (ScratchOrgInfo scratchOrgInfo : scratchOrgInfoMap.values()) {
            sharesToInsert.addAll(shareScratchOrgInfo(scratchOrgInfo));
        }

        if (!sharesToInsert.isEmpty()) {
            insert sharesToInsert;
        }
    }

    /**
     * Replaces existing pool group shares for the given pooled ScratchOrgInfo records.
     * Admins always receive Edit access. Pool and CI access depends on
     * Pool_allocation_status__c.
     *
     * @param scratchOrgInfoIds ScratchOrgInfo record IDs to recalculate.
     * @return Share logs keyed by ScratchOrgInfo record ID.
     */
    public static Map<Id, ShareLog> recalculateSharing(
        List<Id> scratchOrgInfoIds
    ) {
        SfPoolSharingController ctrl = new SfPoolSharingController(
            scratchOrgInfoIds
        );
        ctrl.recalculate();
        return ctrl.shareLogs;
    }

    private void loadScratchOrgInfos() {
        if (this.scratchOrgInfoPoolRecordTypeId == null) {
            System.debug(
                LoggingLevel.ERROR,
                'RecordType with DeveloperName "Scratch_pool_org" not found. Please ensure that the RecordType exists.'
            );
            return;
        }
        this.scratchOrgInfoMap = new Map<Id, ScratchOrgInfo>(
            [
                SELECT Id, RecordTypeId, Pool_allocation_status__c
                FROM ScratchOrgInfo
                WHERE
                    Id IN :this.scratchOrgInfoIds
                    AND RecordTypeId = :this.scratchOrgInfoPoolRecordTypeId
                ORDER BY CreatedDate DESC
            ]
        );
        for (ScratchOrgInfo scratchOrgInfo : this.scratchOrgInfoMap.values()) {
            this.shareLogs.put(
                scratchOrgInfo.Id,
                new ShareLog(
                    scratchOrgInfo.Id,
                    scratchOrgInfo.Pool_allocation_status__c,
                    new Map<System.LoggingLevel, List<String>>()
                )
            );
        }
    }

    private ScratchOrgInfoShare shareScratchOrgInfoRecord(
        Id recordId,
        Id userOrGroupId,
        String accessLevel
    ) {
        if (recordId == null || userOrGroupId == null || accessLevel == null) {
            shareLogs.get(recordId)
                .addLogMessage(
                    LoggingLevel.WARN,
                    'Invalid parameters for sharing record. recordId: ' +
                        recordId +
                        ', userOrGroupId: ' +
                        userOrGroupId +
                        ', accessLevel: ' +
                        accessLevel
                );
            return null;
        }
        return new ScratchOrgInfoShare(
            ParentId = recordId,
            UserOrGroupId = userOrGroupId,
            AccessLevel = accessLevel
        );
    }

    /**
     * Builds shares for one pooled ScratchOrgInfo based on allocation status.
     * in_progress, under_update, and failed give Pool Read and CI Edit;
     * available gives Pool Edit; assigned gives Pool Read.
     *
     * @param scratchOrgInfo Pooled ScratchOrgInfo record.
     * @return Manual share records to insert.
     */
    private List<ScratchOrgInfoShare> shareScratchOrgInfo(
        ScratchOrgInfo scratchOrgInfo
    ) {
        List<ScratchOrgInfoShare> newShares = new List<ScratchOrgInfoShare>();

        if (scratchOrgInfo.RecordTypeId == scratchOrgInfoPoolRecordTypeId) {
            newShares.add(
                shareScratchOrgInfoRecord(
                    scratchOrgInfo.Id,
                    SfPoolGroupHelper.getGroupIdByDeveloperName(
                        SfPoolGroupHelper.SCRATCH_POOL_ADMIN_PUBLIC_GROUP_DEVELOPER_NAME
                    ),
                    EDIT_ACCESS_LEVEL
                )
            );

            if (scratchOrgInfo.Pool_allocation_status__c == 'in_progress') {
                newShares.add(
                    shareScratchOrgInfoRecord(
                        scratchOrgInfo.Id,
                        SfPoolGroupHelper.getGroupIdByDeveloperName(
                            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
                        ),
                        READ_ACCESS_LEVEL
                    )
                );
                newShares.add(
                    shareScratchOrgInfoRecord(
                        scratchOrgInfo.Id,
                        SfPoolGroupHelper.getGroupIdByDeveloperName(
                            SfPoolGroupHelper.SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME
                        ),
                        EDIT_ACCESS_LEVEL
                    )
                );
            }

            if (scratchOrgInfo.Pool_allocation_status__c == 'available') {
                newShares.add(
                    shareScratchOrgInfoRecord(
                        scratchOrgInfo.Id,
                        SfPoolGroupHelper.getGroupIdByDeveloperName(
                            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
                        ),
                        EDIT_ACCESS_LEVEL
                    )
                );
            }

            if (scratchOrgInfo.Pool_allocation_status__c == 'under_update') {
                newShares.add(
                    shareScratchOrgInfoRecord(
                        scratchOrgInfo.Id,
                        SfPoolGroupHelper.getGroupIdByDeveloperName(
                            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
                        ),
                        READ_ACCESS_LEVEL
                    )
                );
                newShares.add(
                    shareScratchOrgInfoRecord(
                        scratchOrgInfo.Id,
                        SfPoolGroupHelper.getGroupIdByDeveloperName(
                            SfPoolGroupHelper.SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME
                        ),
                        EDIT_ACCESS_LEVEL
                    )
                );
            }

            if (scratchOrgInfo.Pool_allocation_status__c == 'failed') {
                newShares.add(
                    shareScratchOrgInfoRecord(
                        scratchOrgInfo.Id,
                        SfPoolGroupHelper.getGroupIdByDeveloperName(
                            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
                        ),
                        READ_ACCESS_LEVEL
                    )
                );
                newShares.add(
                    shareScratchOrgInfoRecord(
                        scratchOrgInfo.Id,
                        SfPoolGroupHelper.getGroupIdByDeveloperName(
                            SfPoolGroupHelper.SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME
                        ),
                        EDIT_ACCESS_LEVEL
                    )
                );
            }

            if (scratchOrgInfo.Pool_allocation_status__c == 'assigned') {
                newShares.add(
                    shareScratchOrgInfoRecord(
                        scratchOrgInfo.Id,
                        SfPoolGroupHelper.getGroupIdByDeveloperName(
                            SfPoolGroupHelper.SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME
                        ),
                        READ_ACCESS_LEVEL
                    )
                );
            }
        }

        return newShares;
    }

    private void deleteScratchOrgInfoShares(List<Id> scratchOrgInfoIds) {
        List<ScratchOrgInfoShare> sharesToDelete = [
            SELECT Id
            FROM ScratchOrgInfoShare
            WHERE
                ParentId IN :scratchOrgInfoIds
                AND UserOrGroupId IN :SfPoolGroupHelper.getPublicGroupIds()
        ];
        if (!sharesToDelete.isEmpty()) {
            delete sharesToDelete;
        }
    }

    /**
     * Captures sharing recalculation messages for one ScratchOrgInfo record.
     */
    public class ShareLog {
        Id scratchOrgInfoId;
        String poolAllocationStatus;
        Map<System.LoggingLevel, List<String>> logMessages;

        /**
         * Creates a sharing log for one ScratchOrgInfo record.
         *
         * @param scratchOrgInfoId ScratchOrgInfo record ID.
         * @param poolAllocationStatus Allocation status at recalculation time.
         * @param logMessages Existing log message buckets.
         */
        public ShareLog(
            Id scratchOrgInfoId,
            String poolAllocationStatus,
            Map<System.LoggingLevel, List<String>> logMessages
        ) {
            this.scratchOrgInfoId = scratchOrgInfoId;
            this.poolAllocationStatus = poolAllocationStatus;
            this.logMessages = logMessages;
        }

        /**
         * Adds a message to this log and writes it to the debug log.
         *
         * @param level Logging level for the message.
         * @param message Message to record.
         * @return This log instance.
         */
        public ShareLog addLogMessage(
            System.LoggingLevel level,
            String message
        ) {
            System.debug(level, message);
            if (!this.logMessages.containsKey(level)) {
                this.logMessages.put(level, new List<String>());
            }
            this.logMessages.get(level).add(message);
            return this;
        }
    }
}
