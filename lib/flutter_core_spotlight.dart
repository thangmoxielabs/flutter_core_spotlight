import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

typedef UserActivityCallback = Function(
    FlutterSpotlightUserActivity? userActivity);

class FlutterSpotlightItem {
  FlutterSpotlightItem({
    required this.uniqueIdentifier,
    required this.domainIdentifier,
    required this.attributeTitle,
    required this.attributeDisplayName,
    required this.attributeDescription,
    this.keywords = const [],
    this.addedDate,
  });

  factory FlutterSpotlightItem.fromJson(String source) =>
      FlutterSpotlightItem.fromMap(json.decode(source));

  factory FlutterSpotlightItem.fromMap(Map<String, dynamic> map) {
    return FlutterSpotlightItem(
      uniqueIdentifier: map['uniqueIdentifier'],
      domainIdentifier: map['domainIdentifier'],
      attributeTitle: map['attributeTitle'],
      attributeDisplayName: map['attributeDisplayName'],
      attributeDescription: map['attributeDescription'],
      keywords: map['keywords'] != null
          ? List<String>.from(map['keywords'])
          : const [],
      addedDate: map['addedDate'],
    );
  }

  final String attributeDescription;
  final String attributeTitle;
  final String attributeDisplayName;
  final String domainIdentifier;
  final String uniqueIdentifier;
  final List<String> keywords;
  final String? addedDate;

  Map<String, dynamic> toMap() {
    return {
      'uniqueIdentifier': uniqueIdentifier,
      'domainIdentifier': domainIdentifier,
      'attributeTitle': attributeTitle,
      'attributeDescription': attributeDescription,
      'keywords': keywords,
      'addedDate': addedDate,
    };
  }

  String toJson() => json.encode(toMap());
}

class FlutterSpotlightUserActivity {
  FlutterSpotlightUserActivity({
    this.key,
    this.uniqueIdentifier,
    this.userInfo,
  });

  factory FlutterSpotlightUserActivity.fromJson(String source) =>
      FlutterSpotlightUserActivity.fromMap(json.decode(source));

  factory FlutterSpotlightUserActivity.fromMap(Map<String, dynamic> map) {
    return FlutterSpotlightUserActivity(
      key: map['key'],
      uniqueIdentifier: map['uniqueIdentifier'],
      userInfo: Map<String, dynamic>.from(map['userInfo']),
    );
  }

  final String? key;
  final String? uniqueIdentifier;
  final Map<String, dynamic>? userInfo;

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'uniqueIdentifier': uniqueIdentifier,
      'userInfo': userInfo,
    };
  }

  String toJson() => json.encode(toMap());
}

class FlutterCoreSpotlight {
  FlutterCoreSpotlight._();

  static final FlutterCoreSpotlight instance = FlutterCoreSpotlight._();

  static const MethodChannel _channel =
      const MethodChannel('flutter_core_spotlight');

  UserActivityCallback? _onSearchableItemSelected;

  Future<String> indexSearchableItems(
      List<FlutterSpotlightItem> spotlightItems) async {
    return await _channel.invokeMethod('index_searchable_items',
        spotlightItems.map((e) => e.toMap()).toList());
  }

  Future<String> deleteSearchableItems(List<String> identifiers) async {
    return await _channel.invokeMethod('delete_searchable_items', identifiers);
  }

  Future<String> deleteAllSearchableItems() async {
    return await _channel.invokeMethod('delete_all_searchable_items');
  }

  void configure({required UserActivityCallback onSearchableItemSelected}) {
    _onSearchableItemSelected = onSearchableItemSelected;
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onSearchableItemSelected':
        final Map<String, dynamic> args =
            call.arguments.cast<String, dynamic>();
        _onSearchableItemSelected!(FlutterSpotlightUserActivity.fromMap(args));
        break;
      default:
        throw UnsupportedError('Unrecognized JSON message');
    }
  }
}
