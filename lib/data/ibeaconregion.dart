part of geolocation;

class IBeaconRegion {
  String identifier;
  String proximityUuid;

  IBeaconRegion(String identifier, String proximityUuid) {
    this.identifier = identifier;
    this.proximityUuid = proximityUuid;
  }

  @override
  String toString() {
    return '{identifier: $identifier, UUID: $proximityUuid}';
  }
}