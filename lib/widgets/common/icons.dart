import 'package:aves/model/image_entry.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VideoIcon extends StatelessWidget {
  final ImageEntry entry;
  final double iconSize;

  const VideoIcon({Key key, this.entry, this.iconSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlayIcon(
      icon: Icons.play_circle_outline,
      iconSize: iconSize,
      text: entry.durationText,
    );
  }
}

class GifIcon extends StatelessWidget {
  final double iconSize;

  const GifIcon({Key key, this.iconSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlayIcon(
      icon: Icons.gif,
      iconSize: iconSize,
    );
  }
}

class GpsIcon extends StatelessWidget {
  final double iconSize;

  const GpsIcon({Key key, this.iconSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlayIcon(
      icon: Icons.place,
      iconSize: iconSize,
    );
  }
}

class OverlayIcon extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String text;

  const OverlayIcon({Key key, this.icon, this.iconSize, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(1),
      padding: text != null ? EdgeInsets.only(right: iconSize / 4) : null,
      decoration: BoxDecoration(
        color: Color(0xBB000000),
        borderRadius: BorderRadius.all(
          Radius.circular(iconSize),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
          ),
          if (text != null) ...[
            SizedBox(width: 2),
            Text(text),
          ]
        ],
      ),
    );
  }
}

class IconUtils {
  static Widget getAlbumIcon(BuildContext context, String albumDirectory) {
    if (androidFileUtils.isCameraPath(albumDirectory)) {
      return Icon(Icons.photo_camera);
    } else if (androidFileUtils.isScreenshotsPath(albumDirectory)) {
      return Icon(Icons.smartphone);
    } else if (androidFileUtils.isKakaoTalkPath(albumDirectory)) {
      return SvgPicture.asset('assets/kakaotalk.svg', width: IconTheme.of(context).size);
    } else if (androidFileUtils.isTelegramPath(albumDirectory)) {
      return SvgPicture.asset('assets/telegram.svg', width: IconTheme.of(context).size);
    }
    return null;
  }
}
