/**
 * Looks up the public groups used by scratch org pooling.
 * Group data is loaded once and cached for the current Apex transaction.
 */
public with sharing class SfPoolGroupHelper {
    /** Public group that contains all scratch pool access groups. */
    public static final String SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME = 'Scratch_Pool';
    /** Public group used by CI automation. */
    public static final String SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME = 'Scratch_Pool_CI';
    /** Public group used by pool users. */
    public static final String SCRATCH_POOL_USERS_PUBLIC_GROUP_DEVELOPER_NAME = 'Scratch_Pool_Users';
    /** Public group used by pool administrators. */
    public static final String SCRATCH_POOL_ADMIN_PUBLIC_GROUP_DEVELOPER_NAME = 'Scratch_Pool_Admins';

    private static Map<String, Id> groupDeveloperNameToIdMap {
        private get {
            if (!hasLoadedGroupData) {
                loadGroupData();
            }
            return groupDeveloperNameToIdMap;
        }
        private set;
    }
    private static Map<Id, Group> groupMapById;

    private static Boolean hasLoadedGroupData = false;

    private static void loadGroupData() {
        Map<String, Id> tmpMap = new Map<String, Id>();

        setgroupMapById();

        for (Group g : groupMapById.values()) {
            tmpMap.put(g.DeveloperName, g.Id);
        }
        groupDeveloperNameToIdMap = tmpMap;
        hasLoadedGroupData = true;
    }

    private static void setGroupMapById() {
        groupMapById = new Map<Id, Group>(
            [
                SELECT Id, DeveloperName
                FROM Group
                WHERE DeveloperName IN :getPublicGroupDeveloperNames()
            ]
        );
    }

    /**
     * Returns the group ID for a configured public group developer name.
     *
     * @param developerName DeveloperName of the public group.
     * @return The group ID, or null when the group is not found.
     */
    public static Id getGroupIdByDeveloperName(String developerName) {
        if (groupDeveloperNameToIdMap.containsKey(developerName)) {
            return groupDeveloperNameToIdMap.get(developerName);
        }
        return null;
    }

    /**
     * Returns IDs for the scratch pool public groups that exist in the org.
     *
     * @return Public group IDs found for the configured developer names.
     */
    public static List<Id> getPublicGroupIds() {
        return groupDeveloperNameToIdMap.values();
    }

    /**
     * Returns all public group developer names required by scratch pooling.
     *
     * @return Required public group developer names.
     */
    public static Set<String> getPublicGroupDeveloperNames() {
        return new Set<String>{
            SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME,
            SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME,
            SCRATCH_POOL_USERS_PUBLIC_GROUP_DEVELOPER_NAME,
            SCRATCH_POOL_ADMIN_PUBLIC_GROUP_DEVELOPER_NAME
        };
    }

    /**
     * Returns required public group developer names that are missing in the org.
     *
     * @return Missing public group developer names.
     */
    public static List<String> getPublicGroupMissingDeveloperNames() {
        Set<String> developerNames = getPublicGroupDeveloperNames();
        Set<String> existingDeveloperNames = new Set<String>(
            groupDeveloperNameToIdMap.keySet()
        );
        developerNames.removeAll(existingDeveloperNames);
        return new List<String>(developerNames);
    }

    /**
     * Returns the developer name for one of the configured public group IDs.
     *
     * @param groupId Public group ID.
     * @return The group developer name, or null when the group is not found.
     */
    public static String getDeveloperNameByGroupId(Id groupId) {
        if (!hasLoadedGroupData) {
            loadGroupData();
        }
        if (groupMapById.containsKey(groupId)) {
            return groupMapById.get(groupId).DeveloperName;
        }
        return null;
    }
}
