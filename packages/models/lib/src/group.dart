/// Represents an emergency coordination group (Family, Rescue Team, Building, etc.)
class EmergencyGroup {
  final String groupId; // UUID v4
  final String name; // e.g. "Parya Family Emergency"
  final String? description;
  final String adminDeviceId; // Device ID of the group administrator
  final String? groupKey; // Base64 symmetric group encryption key
  final List<String> memberDeviceIds;
  final int createdAt; // Milliseconds since epoch
  final int? expiresAt; // Milliseconds since epoch or null if indefinite
  final bool isFamilyGroup;

  const EmergencyGroup({
    required this.groupId,
    required this.name,
    this.description,
    required this.adminDeviceId,
    this.groupKey,
    required this.memberDeviceIds,
    required this.createdAt,
    this.expiresAt,
    this.isFamilyGroup = false,
  });

  EmergencyGroup copyWith({
    String? groupId,
    String? name,
    String? description,
    String? adminDeviceId,
    String? groupKey,
    List<String>? memberDeviceIds,
    int? createdAt,
    int? expiresAt,
    bool? isFamilyGroup,
  }) {
    return EmergencyGroup(
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      adminDeviceId: adminDeviceId ?? this.adminDeviceId,
      groupKey: groupKey ?? this.groupKey,
      memberDeviceIds: memberDeviceIds ?? this.memberDeviceIds,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isFamilyGroup: isFamilyGroup ?? this.isFamilyGroup,
    );
  }

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'name': name,
        'description': description,
        'adminDeviceId': adminDeviceId,
        if (groupKey != null) 'groupKey': groupKey,
        'memberDeviceIds': memberDeviceIds,
        'createdAt': createdAt,
        'expiresAt': expiresAt,
        'isFamilyGroup': isFamilyGroup,
      };

  factory EmergencyGroup.fromJson(Map<String, dynamic> json) => EmergencyGroup(
        groupId: json['groupId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        adminDeviceId: json['adminDeviceId'] as String,
        groupKey: json['groupKey'] as String?,
        memberDeviceIds: (json['memberDeviceIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        createdAt: json['createdAt'] as int,
        expiresAt: json['expiresAt'] as int?,
        isFamilyGroup: json['isFamilyGroup'] as bool? ?? false,
      );

  Map<String, dynamic> toSqlite() => {
        'group_id': groupId,
        'name': name,
        'description': description,
        'admin_device_id': adminDeviceId,
        'group_key': groupKey,
        'members_csv': memberDeviceIds.join(','),
        'created_at': createdAt,
        'expires_at': expiresAt,
        'is_family': isFamilyGroup ? 1 : 0,
      };

  factory EmergencyGroup.fromSqlite(Map<String, dynamic> row) => EmergencyGroup(
        groupId: row['group_id'] as String,
        name: row['name'] as String,
        description: row['description'] as String?,
        adminDeviceId: row['admin_device_id'] as String,
        groupKey: row['group_key'] as String?,
        memberDeviceIds: (row['members_csv'] as String?)?.split(',') ?? [],
        createdAt: row['created_at'] as int,
        expiresAt: row['expires_at'] as int?,
        isFamilyGroup: (row['is_family'] as int? ?? 0) == 1,
      );
}

/// Member inside an emergency group.
class GroupMember {
  final String groupId;
  final String deviceId;
  final String? alias;
  final String role; // "admin", "member", "responder"
  final int joinedAt;

  const GroupMember({
    required this.groupId,
    required this.deviceId,
    this.alias,
    this.role = 'member',
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'deviceId': deviceId,
        'alias': alias,
        'role': role,
        'joinedAt': joinedAt,
      };

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        groupId: json['groupId'] as String,
        deviceId: json['deviceId'] as String,
        alias: json['alias'] as String?,
        role: json['role'] as String? ?? 'member',
        joinedAt: json['joinedAt'] as int,
      );

  Map<String, dynamic> toSqlite() => {
        'group_id': groupId,
        'device_id': deviceId,
        'alias': alias,
        'role': role,
        'joined_at': joinedAt,
      };

  factory GroupMember.fromSqlite(Map<String, dynamic> row) => GroupMember(
        groupId: row['group_id'] as String,
        deviceId: row['device_id'] as String,
        alias: row['alias'] as String?,
        role: row['role'] as String? ?? 'member',
        joinedAt: row['joined_at'] as int,
      );
}
