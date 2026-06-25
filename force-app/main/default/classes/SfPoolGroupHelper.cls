public with sharing class SfPoolGroupHelper {
    public static final String SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME = 'Scratch_Pool';
    public static final String SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME = 'Scratch_Pool_CI';
    public static final String SCRATCH_POOL_USERS_PUBLIC_GROUP_DEVELOPER_NAME = 'Scratch_Pool_Users';
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

    public static Id getGroupIdByDeveloperName(String developerName) {
        if (groupDeveloperNameToIdMap.containsKey(developerName)) {
            return groupDeveloperNameToIdMap.get(developerName);
        }
        return null;
    }

    public static List<Id> getPublicGroupIds() {
        return groupDeveloperNameToIdMap.values();
    }

    public static Set<String> getPublicGroupDeveloperNames() {
        return new Set<String>{
            SCRATCH_POOL_PUBLIC_GROUP_DEVELOPER_NAME,
            SCRATCH_POOL_CI_PUBLIC_GROUP_DEVELOPER_NAME,
            SCRATCH_POOL_USERS_PUBLIC_GROUP_DEVELOPER_NAME,
            SCRATCH_POOL_ADMIN_PUBLIC_GROUP_DEVELOPER_NAME
        };
    }

    public static List<String> getPublicGroupMissingDeveloperNames() {
        Set<String> developerNames = getPublicGroupDeveloperNames();
        Set<String> existingDeveloperNames = new Set<String>(
            groupDeveloperNameToIdMap.keySet()
        );
        developerNames.removeAll(existingDeveloperNames);
        return new List<String>(developerNames);
    }

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
