import 'dart:io';
import 'dart:math';

import 'package:aves/image_fullscreen_overlay.dart';
import 'package:aves/model/image_entry.dart';
import 'package:aves/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageFullscreenPage extends StatefulWidget {
  final List<ImageEntry> entries;
  final String initialUri;

  const ImageFullscreenPage({
    Key key,
    this.entries,
    this.initialUri,
  }) : super(key: key);

  @override
  ImageFullscreenPageState createState() => ImageFullscreenPageState();
}

class ImageFullscreenPageState extends State<ImageFullscreenPage> with SingleTickerProviderStateMixin {
  int _currentPage;
  PageController _pageController;
  ValueNotifier<bool> _overlayVisible = ValueNotifier(false);
  AnimationController _overlayAnimationController;
  Animation<Offset> _topOverlayOffset, _bottomOverlayOffset;

  List<ImageEntry> get entries => widget.entries;

  @override
  void initState() {
    super.initState();
    final index = entries.indexWhere((entry) => entry.uri == widget.initialUri);
    _currentPage = max(0, index);
    _pageController = PageController(initialPage: _currentPage);
    _overlayAnimationController = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: this,
    );
    _topOverlayOffset = Tween(begin: Offset(0, 0), end: Offset(0, -1)).animate(CurvedAnimation(parent: _overlayAnimationController, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInQuart));
    _bottomOverlayOffset = Tween(begin: Offset(0, 0), end: Offset(0, 1)).animate(CurvedAnimation(parent: _overlayAnimationController, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInQuart));
    _overlayVisible.addListener(onOverlayVisibleChange);
  }

  @override
  void dispose() {
    _overlayVisible.removeListener(onOverlayVisibleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      scrollDirection: Axis.vertical,
      children: [
        ClipRect(
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                PhotoViewGallery.builder(
                  itemCount: entries.length,
                  builder: (context, index) {
                    final entry = entries[index];
                    return PhotoViewGalleryPageOptions(
                      imageProvider: FileImage(File(entry.path)),
                      heroTag: entry.uri,
                      minScale: PhotoViewComputedScale.contained,
                      initialScale: PhotoViewComputedScale.contained,
                      onTapUp: (tapContext, details, value) => _overlayVisible.value = !_overlayVisible.value,
                    );
                  },
                  loadingChild: Center(
                    child: CircularProgressIndicator(),
                  ),
                  pageController: _pageController,
                  onPageChanged: (index) {
                    debugPrint('onPageChanged: index=$index');
                    setState(() => _currentPage = index);
                  },
                  transitionOnUserGestures: true,
                  scrollPhysics: BouncingScrollPhysics(),
                ),
                if (_currentPage != null) ...[
                  SlideTransition(
                    position: _topOverlayOffset,
                    child: FullscreenTopOverlay(
                      entries: entries,
                      index: _currentPage,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: SlideTransition(
                      position: _bottomOverlayOffset,
                      child: FullscreenBottomOverlay(
                        entries: entries,
                        index: _currentPage,
                      ),
                    ),
                  )
                ]
              ],
            ),
            resizeToAvoidBottomInset: false,
          ),
        ),
        InfoPage(entry: entries[_currentPage]),
      ],
//        Hero(
//          tag: uri,
//          child: Stack(
//            children: [
//              Center(
//                child: widget.thumbnail == null
//                    ? CircularProgressIndicator()
//                    : Image.memory(
//                        widget.thumbnail,
//                        width: requestWidth,
//                        height: requestHeight,
//                        fit: BoxFit.contain,
//                      ),
//              ),
//              Center(
//                child: FadeInImage(
//                  placeholder: MemoryImage(kTransparentImage),
//                  image: FileImage(File(path)),
//                  fadeOutDuration: Duration(milliseconds: 1),
//                  fadeInDuration: Duration(milliseconds: 200),
//                  width: requestWidth,
//                  height: requestHeight,
//                  fit: BoxFit.contain,
//                ),
//              ),
//            ],
//          ),
//        ),
    );
  }

  onOverlayVisibleChange() {
    if (_overlayVisible.value)
      _overlayAnimationController.forward();
    else
      _overlayAnimationController.reverse();
  }
}

class InfoPage extends StatelessWidget {
  final ImageEntry entry;

  const InfoPage({this.entry});

  @override
  Widget build(BuildContext context) {
    final date = entry.getBestDate();
    return Scaffold(
      appBar: AppBar(
        title: Text('Info'),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoRow('Title', entry.title),
            InfoRow('Date', '${DateFormat.yMMMd().format(date)} – ${DateFormat.Hm().format(date)}'),
            InfoRow('Size', formatFilesize(entry.sizeBytes)),
            InfoRow('Resolution', '${entry.width} × ${entry.height} (${entry.getMegaPixels()} MP)'),
            InfoRow('Path', entry.path),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label, value;

  const InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(width: 8),
        Text(value),
      ],
    );
  }
}
