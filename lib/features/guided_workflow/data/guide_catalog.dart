import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/workflow.dart';
import 'ride_workflow.dart';

/// One supported app (Ola, Uber, Rapido, Google Pay, PhonePe, WhatsApp).
class AppInfo {
  const AppInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.accent,
  });

  final String id;
  final String name;
  final String category;
  final int color;
  final int accent;
}

class TopicInfo {
  const TopicInfo({
    required this.id,
    required this.app,
    required this.title,
    required this.about,
  });

  final String id;
  final String app;
  final LocalizedText title;
  final String about;
}

/// All guides, loaded from assets/guides/catalog.json. Topics marked `builtin`
/// (ride booking) use the hand-built ride workflows with real screenshots.
class GuideCatalog {
  GuideCatalog._(this.apps, this.categories, this.topics, this.definitions);

  static const asset = 'assets/guides/catalog.json';

  final Map<String, AppInfo> apps;
  final Map<String, LocalizedText> categories;
  final List<TopicInfo> topics;
  final List<WorkflowDefinition> definitions;

  static Future<GuideCatalog> load([AssetBundle? bundle]) async =>
      parse(await (bundle ?? rootBundle).loadString(asset));

  static GuideCatalog parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final apps = <String, AppInfo>{
      for (final e in (json['apps'] as Map<String, dynamic>).entries)
        e.key: AppInfo(
          id: e.key,
          name: e.value['name'] as String,
          category: e.value['category'] as String,
          color: _hex(e.value['color'] as String),
          accent: _hex(e.value['accent'] as String),
        ),
    };
    final categories = <String, LocalizedText>{
      for (final e in (json['categories'] as Map<String, dynamic>).entries)
        e.key: _text(e.value),
    };
    final shared = json['shared_steps'] as Map<String, dynamic>;
    final topics = <TopicInfo>[];
    final definitions = <WorkflowDefinition>[];

    for (final t in json['topics'] as List) {
      final topic = t as Map<String, dynamic>;
      for (final appId in (topic['apps'] as List).cast<String>()) {
        final app = apps[appId]!;
        topics.add(
          TopicInfo(
            id: topic['id'] as String,
            app: appId,
            title: _text(topic['title'], app.name),
            about: topic['about'] as String? ?? '',
          ),
        );
        if (topic['builtin'] == true) continue;
        definitions.add(
          WorkflowDefinition(
            id: '$appId.${topic['id']}',
            app: appId,
            topic: topic['id'] as String,
            title: _text(topic['title'], app.name),
            steps: [
              for (final s in topic['steps'] as List)
                _step(
                  (s as Map<String, dynamic>)['ref'] != null
                      ? {
                          'id': s['ref'],
                          ...(shared[s['ref']] as Map<String, dynamic>),
                        }
                      : s,
                  app.name,
                ),
            ],
          ),
        );
      }
    }
    return GuideCatalog._(apps, categories, topics, definitions);
  }

  List<TopicInfo> topicsFor(String app) =>
      topics.where((t) => t.app == app).toList();

  /// The guide for [topic] in [app]. Ride booking has a new-user variant.
  WorkflowDefinition? definitionFor(
    String app,
    String topic, {
    bool newUser = false,
  }) {
    if (topic == 'book_ride') {
      final ride = RideApp.values.where((r) => r.name == app).firstOrNull;
      return ride == null ? null : rideWorkflow(ride, fromInstall: newUser);
    }
    for (final d in definitions) {
      if (d.id == '$app.$topic') return d;
    }
    return null;
  }

  static WorkflowStep _step(Map<String, dynamic> s, String appName) {
    final visual = s['visual'] as Map<String, dynamic>?;
    return WorkflowStep(
      id: s['id'] as String,
      title: _text(s['title'], appName),
      instruction: _text(s['text'], appName),
      visual: visual == null
          ? null
          : StepVisual(
              visual['kind'] as String,
              focus: visual['focus'] as String?,
            ),
      sensitivity: switch (s['sensitive']) {
        'money' => Sensitivity.money,
        'secret' => Sensitivity.secretCode,
        _ => Sensitivity.none,
      },
    );
  }

  static LocalizedText _text(Object? v, [String app = '']) {
    final m = v as Map<String, dynamic>;
    return LocalizedText(
      en: (m['en'] as String).replaceAll('{app}', app),
      mr: (m['mr'] as String).replaceAll('{app}', app),
    );
  }

  static int _hex(String s) => int.parse('FF${s.substring(1)}', radix: 16);
}
