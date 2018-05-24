//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// Contains the result from a iBeacon request.
/// [id] the identifier specified in the 
/// [timeStamp] specifies when [beacon] was ranged.
class IBeaconResult extends GeolocationResult {

  IBeaconResult._(
      bool isSuccessful, GeolocationResultError error, this.id, this.beacon, this.timeStamp): super._(isSuccessful, error);

  final IBeacon beacon;
  final int id;
  final double timeStamp;

  String dataToString() {
    return '{geofence: $beacon.toString(), didEnter: $timeStamp}';
  }
}
