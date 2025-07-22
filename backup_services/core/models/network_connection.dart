enum NetworkType { internet, bluetooth, ble, local }

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class NetworkConnection {
  final String id;
  final NetworkType type;
  final String address;
  final String name;
  ConnectionStatus status;
  DateTime? lastConnected;
  int retryCount;
  final Map<String, dynamic> metadata;

  NetworkConnection({
    required this.id,
    required this.type,
    required this.address,
    required this.name,
    this.status = ConnectionStatus.disconnected,
    this.lastConnected,
    this.retryCount = 0,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'address': address,
      'name': name,
      'status': status.name,
      'lastConnected': lastConnected?.toIso8601String(),
      'retryCount': retryCount,
      'metadata': metadata,
    };
  }

  factory NetworkConnection.fromJson(Map<String, dynamic> json) {
    return NetworkConnection(
      id: json['id'],
      type: NetworkType.values.firstWhere((e) => e.name == json['type']),
      address: json['address'],
      name: json['name'],
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      lastConnected:
          json['lastConnected'] != null
              ? DateTime.parse(json['lastConnected'])
              : null,
      retryCount: json['retryCount'] ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}
