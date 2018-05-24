part of geolocation;

class IBeacon {
  String proximityUuid;
  int major;
  int minor;

  IBeacon(String proximityUuid, int major, int minor) {
    this.proximityUuid = proximityUuid;
    this.major = major;
    this.minor = minor;
  }

  @override
  String toString() {
    return '{min: $minor, maj: $major, region: $proximityUuid}';
  }
}