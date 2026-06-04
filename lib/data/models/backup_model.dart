class BackupManifest {
  final int version;
  final DateTime createdAt;
  final int vaultFileCount;
  final int albumCount;

  BackupManifest({
    required this.version,
    required this.createdAt,
    required this.vaultFileCount,
    required this.albumCount,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'vaultFileCount': vaultFileCount,
    'albumCount': albumCount,
  };

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      version: json['version'],
      createdAt: DateTime.parse(json['createdAt']),
      vaultFileCount: json['vaultFileCount'],
      albumCount: json['albumCount'],
    );
  }
}
