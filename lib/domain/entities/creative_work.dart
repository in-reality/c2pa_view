import 'package:c2pa_view/domain/entities/custom_field.dart';
import 'package:equatable/equatable.dart';

/// Parsed data from the `stds.schema-org.CreativeWork` assertion.
class CreativeWork extends Equatable {

  const CreativeWork({
    this.author,
    this.copyrightNotice,
    this.copyrightHolder,
    this.producer,
    this.creditText,
    this.website,
    this.socialAccounts = const [],
    this.rawData,
    this.customFields = const [],
  });

  factory CreativeWork.fromAssertionData(final Map<String, dynamic> data) {
    final socialAccounts = <SocialAccount>[];

    if (data['sameAs'] is List) {
      for (final item in data['sameAs'] as List) {
        if (item is Map<String, dynamic>) {
          final platform =
              item['@type'] as String? ?? item['name'] as String? ?? 'Unknown';
          final url = item['url'] as String? ?? '';
          socialAccounts.add(SocialAccount(platform: platform, url: url));
        } else if (item is String) {
          socialAccounts.add(
            SocialAccount(platform: _guessPlatform(item), url: item),
          );
        }
      }
    }

    final customEntries =
        data.entries
            .where((final e) => !_knownKeys.contains(e.key))
            .map(
              (final e) => CustomField(
                key: e.key,
                value: e.value,
                source: 'creative_work_extension',
              ),
            )
            .toList();

    return CreativeWork(
      author: _extractPersonName(data['author']),
      copyrightNotice: data['copyrightNotice'] as String?,
      copyrightHolder: _extractPersonName(data['copyrightHolder']),
      producer: _extractPersonName(data['producer']),
      creditText: data['creditText'] as String?,
      website: data['url'] as String?,
      socialAccounts: socialAccounts,
      rawData: data,
      customFields: customEntries,
    );
  }
  final String? author;
  final String? copyrightNotice;
  final String? copyrightHolder;
  final String? producer;
  final String? creditText;
  final String? website;
  final List<SocialAccount> socialAccounts;
  final Map<String, dynamic>? rawData;
  final List<CustomField> customFields;

  static const _knownKeys = {
    '@context',
    '@type',
    'author',
    'copyrightNotice',
    'copyrightHolder',
    'producer',
    'creditText',
    'url',
    'sameAs',
  };

  static String? _extractPersonName(final value) {
    if (value is String) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      return value['name'] as String? ?? value['@value'] as String?;
    }
    if (value is List && value.isNotEmpty) {
      return _extractPersonName(value.first);
    }
    return null;
  }

  static String _guessPlatform(final String url) {
    final lower = url.toLowerCase();
    if (lower.contains('twitter.com') || lower.contains('x.com')) {
      return 'Twitter/X';
    }
    if (lower.contains('instagram.com')) {
      return 'Instagram';
    }
    if (lower.contains('facebook.com')) {
      return 'Facebook';
    }
    if (lower.contains('linkedin.com')) {
      return 'LinkedIn';
    }
    if (lower.contains('youtube.com')) {
      return 'YouTube';
    }
    if (lower.contains('tiktok.com')) {
      return 'TikTok';
    }
    return 'Website';
  }

  @override
  List<Object?> get props => [
    author,
    copyrightNotice,
    copyrightHolder,
    producer,
    creditText,
    website,
    socialAccounts,
    rawData,
    customFields,
  ];
}

/// A social media account reference.
class SocialAccount extends Equatable {

  const SocialAccount({required this.platform, required this.url});
  final String platform;
  final String url;

  @override
  List<Object?> get props => [platform, url];
}
