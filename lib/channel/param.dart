//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _LocationUpdatesRequest {
  _LocationUpdatesRequest(
    this.strategy,
    this.permission,
    this.accuracy,
    this.inBackground, [
    this.displacementFilter = 0.0,
  ]) {
    assert(displacementFilter >= 0.0);
  }

  int id;
  final _LocationUpdateStrategy strategy;
  final LocationPermission permission;
  final LocationAccuracy accuracy;
  final bool inBackground;
  final double displacementFilter;
}

enum _LocationUpdateStrategy { current, single, continuous }

class _GeoFenceUpdatesRequest {
  _GeoFenceUpdatesRequest(
    this.id,
    this.geoFence, 
  );
  int id;
  final GeoFence geoFence;
}

class _IBeaconUpdatesRequest {
  _IBeaconUpdatesRequest(
    this.id,
    this.region, 
    this.limit,
    this.includeUnknown,
  );
  int id;
  final IBeaconRegion region;
  int limit;
  bool includeUnknown;
}

