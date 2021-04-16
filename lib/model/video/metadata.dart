import 'dart:async';

import 'package:aves/model/entry.dart';
import 'package:aves/model/video/channel_layouts.dart';
import 'package:aves/model/video/h264.dart';
import 'package:aves/model/video/keys.dart';
import 'package:aves/ref/languages.dart';
import 'package:aves/ref/mp4.dart';
import 'package:aves/utils/file_utils.dart';
import 'package:aves/utils/math_utils.dart';
import 'package:aves/utils/string_utils.dart';
import 'package:aves/utils/time_utils.dart';
import 'package:aves/widgets/common/video/fijkplayer.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/foundation.dart';

class VideoMetadataFormatter {
  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  static final _durationPattern = RegExp(r'(\d+):(\d+):(\d+)(.\d+)');
  static final _locationPattern = RegExp(r'([+-][.0-9]+)');
  static final Map<String, String> _codecNames = {
    'ac3': 'AC-3',
    'eac3': 'E-AC-3',
    'h264': 'AVC (H.264)',
    'hdmv_pgs_subtitle': 'PGS',
    'hevc': 'HEVC (H.265)',
    'matroska': 'Matroska',
    'mpeg4': 'MPEG-4 Visual',
    'mpegts': 'MPEG-TS',
    'subrip': 'SubRip',
    'webm': 'WebM',
  };

  static Future<Map> getVideoMetadata(AvesEntry entry) async {
    final player = FijkPlayer();
    await player.setDataSourceUntilPrepared(entry.uri);
    final info = await player.getInfo();
    await player.release();
    return info;
  }

  // pattern to extract optional language code suffix, e.g. 'location-eng'
  static final keyWithLanguagePattern = RegExp(r'^(.*)-([a-z]{3})$');

  static Map<String, String> formatInfo(Map info) {
    final dir = <String, String>{};
    final streamType = info[Keys.streamType];
    final codec = info[Keys.codecName];
    for (final kv in info.entries) {
      final value = kv.value;
      if (value != null) {
        try {
          String key;
          String keyLanguage;
          // some keys have a language suffix, but they may be duplicates
          // we only keep the root key when they have the same value as the same key with no language
          final languageMatch = keyWithLanguagePattern.firstMatch(kv.key);
          if (languageMatch != null) {
            final code = languageMatch.group(2);
            final native = _formatLanguage(code);
            if (native != code) {
              final root = languageMatch.group(1);
              final rootValue = info[root];
              // skip if it is a duplicate of the same entry with no language
              if (rootValue == value) continue;
              key = root;
              if (info.keys.cast<String>().where((k) => k.startsWith('$root-')).length > 1) {
                // only keep language when multiple languages are present
                keyLanguage = native;
              }
            }
          }
          key = (key ?? (kv.key as String)).toLowerCase();

          void save(String key, String value) {
            if (value != null) {
              dir[keyLanguage != null ? '$key ($keyLanguage)' : key] = value;
            }
          }

          switch (key) {
            case Keys.codecLevel:
            case Keys.fpsNum:
            case Keys.handlerName:
            case Keys.index:
            case Keys.sarNum:
            case Keys.selectedAudioStream:
            case Keys.selectedTextStream:
            case Keys.selectedVideoStream:
            case Keys.statisticsTags:
            case Keys.streams:
            case Keys.streamType:
            case Keys.tbrNum:
            case Keys.tbrDen:
              break;
            case Keys.androidCaptureFramerate:
              final captureFps = double.parse(value);
              save('Capture Frame Rate', '${roundToPrecision(captureFps, decimals: 3).toString()} FPS');
              break;
            case Keys.androidVersion:
              save('Android Version', value);
              break;
            case Keys.bitrate:
            case Keys.bps:
              save('Bit Rate', _formatMetric(value, 'b/s'));
              break;
            case Keys.byteCount:
              save('Size', _formatFilesize(value));
              break;
            case Keys.channelLayout:
              save('Channel Layout', _formatChannelLayout(value));
              break;
            case Keys.codecName:
              save('Format', _formatCodecName(value));
              break;
            case Keys.codecPixelFormat:
              if (streamType == StreamTypes.video) {
                // this is just a short name used by FFmpeg
                // user-friendly descriptions for related enums are defined in libavutil/pixfmt.h
                save('Pixel Format', (value as String).toUpperCase());
              }
              break;
            case Keys.codecProfileId:
              if (codec == 'h264') {
                final profile = int.tryParse(value);
                if (profile != null && profile != 0) {
                  final level = int.tryParse(info[Keys.codecLevel]);
                  save('Codec Profile', H264.formatProfile(profile, level));
                }
              }
              break;
            case Keys.compatibleBrands:
              save('Compatible Brands', RegExp(r'.{4}').allMatches(value).map((m) => _formatBrand(m.group(0))).join(', '));
              break;
            case Keys.creationTime:
              save('Creation Time', _formatDate(value));
              break;
            case Keys.date:
              if (value != '0') {
                final charCount = (value as String)?.length ?? 0;
                save(charCount == 4 ? 'Year' : 'Date', value);
              }
              break;
            case Keys.duration:
              save('Duration', _formatDuration(value));
              break;
            case Keys.durationMicros:
              if (value != 0) save('Duration', formatPreciseDuration(Duration(microseconds: value)));
              break;
            case Keys.fpsDen:
              save('Frame Rate', '${roundToPrecision(info[Keys.fpsNum] / info[Keys.fpsDen], decimals: 3).toString()} FPS');
              break;
            case Keys.frameCount:
              save('Frame Count', value);
              break;
            case Keys.height:
              save('Height', '$value pixels');
              break;
            case Keys.language:
              if (value != 'und') save('Language', _formatLanguage(value));
              break;
            case Keys.location:
              save('Location', _formatLocation(value));
              break;
            case Keys.majorBrand:
              save('Major Brand', _formatBrand(value));
              break;
            case Keys.mediaFormat:
              save('Format', (value as String).splitMapJoin(',', onMatch: (s) => ', ', onNonMatch: _formatCodecName));
              break;
            case Keys.mediaType:
              save('Media Type', value);
              break;
            case Keys.minorVersion:
              if (value != '0') save('Minor Version', value);
              break;
            case Keys.rotate:
              save('Rotation', '$value°');
              break;
            case Keys.sampleRate:
              save('Sample Rate', _formatMetric(value, 'Hz'));
              break;
            case Keys.sarDen:
              final sarNum = info[Keys.sarNum];
              final sarDen = info[Keys.sarDen];
              // skip common square pixels (1:1)
              if (sarNum != sarDen) save('SAR', '$sarNum:$sarDen');
              break;
            case Keys.startMicros:
              if (value != 0) save('Start', formatPreciseDuration(Duration(microseconds: value)));
              break;
            case Keys.statisticsWritingApp:
              save('Stats Writing App', value);
              break;
            case Keys.statisticsWritingDateUtc:
              save('Stats Writing Date', _formatDate(value));
              break;
            case Keys.track:
              if (value != '0') save('Track', value);
              break;
            case Keys.width:
              save('Width', '$value pixels');
              break;
            default:
              save(key.toSentenceCase(), value.toString());
          }
        } catch (error) {
          debugPrint('failed to process video info key=${kv.key} value=${kv.value}, error=$error');
        }
      }
    }
    return dir;
  }

  static String _formatBrand(String value) => Mp4.brands[value] ?? value;

  static String _formatChannelLayout(value) => ChannelLayouts.names[value] ?? 'unknown ($value)';

  static String _formatCodecName(String value) => _codecNames[value] ?? value?.toUpperCase()?.replaceAll('_', ' ');

  // input example: '2021-04-12T09:14:37.000000Z'
  static String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    if (date == _epoch) return null;
    return date.toIso8601String();
  }

  // input example: '00:00:05.408000000'
  static String _formatDuration(String value) {
    final match = _durationPattern.firstMatch(value);
    if (match != null) {
      final h = int.tryParse(match.group(1));
      final m = int.tryParse(match.group(2));
      final s = int.tryParse(match.group(3));
      final millis = double.tryParse(match.group(4));
      if (h != null && m != null && s != null && millis != null) {
        return formatPreciseDuration(Duration(
          hours: h,
          minutes: m,
          seconds: s,
          milliseconds: (millis * 1000).toInt(),
        ));
      }
    }
    return value;
  }

  static String _formatFilesize(String value) {
    final size = int.tryParse(value);
    return size != null ? formatFilesize(size) : value;
  }

  static String _formatLanguage(String value) {
    final language = Language.living639_2.firstWhere((language) => language.iso639_2 == value, orElse: () => null);
    return language?.native ?? value;
  }

  // format ISO 6709 input, e.g. '+37.5090+127.0243/' (Samsung), '+51.3328-000.7053+113.474/' (Apple)
  static String _formatLocation(String value) {
    final matches = _locationPattern.allMatches(value);
    if (matches.isNotEmpty) {
      final coordinates = matches.map((m) => double.tryParse(m.group(0))).toList();
      if (coordinates.every((c) => c == 0)) return null;
      return coordinates.join(', ');
    }
    return value;
  }

  static String _formatMetric(dynamic size, String unit, {int round = 2}) {
    if (size is String) {
      final parsed = int.tryParse(size);
      if (parsed == null) return size;
      size = parsed;
    }
    const divider = 1000;

    if (size < divider) return '$size $unit';

    if (size < divider * divider && size % divider == 0) {
      return '${(size / divider).toStringAsFixed(0)} K$unit';
    }
    if (size < divider * divider) {
      return '${(size / divider).toStringAsFixed(round)} K$unit';
    }

    if (size < divider * divider * divider && size % divider == 0) {
      return '${(size / (divider * divider)).toStringAsFixed(0)} M$unit';
    }
    return '${(size / divider / divider).toStringAsFixed(round)} M$unit';
  }
}

class StreamTypes {
  static const audio = 'audio';
  static const metadata = 'metadata';
  static const subtitle = 'subtitle';
  static const timedText = 'timedtext';
  static const unknown = 'unknown';
  static const video = 'video';
}