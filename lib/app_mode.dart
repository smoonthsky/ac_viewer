/// main: This is the main screen of the app, where the user can browse, search, and view media in their collections. In this mode, the user can navigate the app, select media, and select filters to apply to the collection being displayed.
///
/// pickCollectionFiltersExternal: This mode is similar to the main mode, but it is specifically used when the app is launched from an external app that wants to pick a collection filter from the app. In this mode, the user can select a filter, but they cannot navigate or select media.
///
/// pickSingleMediaExternal: This mode is used when the app is launched from an external app that wants to pick a single media file from the app. In this mode, the user can browse and search for media, but they cannot navigate or select multiple media files. Once they select a media file, it will be returned to the external app.
///
/// pickMultipleMediaExternal: This mode is similar to the pickSingleMediaExternal mode, but it allows the user to select multiple media files. Once the user has selected the desired media files, they will be returned to the external app.
///
/// pickMediaInternal: This mode is used when the user wants to select media files within the app, but not to return them to an external app. This mode is similar to the pickMultipleMediaExternal mode, but the selected media files will be used within the app rather than being returned to an external app.
///
/// pickFilterInternal: This mode is used when the user wants to select a filter within the app, but not to return it to an external app. In this mode, the user can select a filter, but they cannot navigate or select media.
///
/// screenSaver: This mode is used when the app is being displayed as a screen saver. In this mode, the app will display a slideshow of media files from a specified collection, with various options for how the slideshow is displayed.
///
/// setWallpaper: This mode is used when the user wants to set a media file as the wallpaper for their device. In this mode, the user can browse and search for media, but they cannot navigate or select multiple media files. Once they select a media file, it will be set as the wallpaper.
///
/// slideshow: This mode is similar to the screenSaver mode, but it is used when the user wants to manually initiate a slideshow within the app. In this mode, the app will display a slideshow of media files from a specified collection, with various options for how the slideshow is displayed.
///
/// view: This mode is used when the user wants to view a single media file. In this mode, the user can view the media file, but they cannot navigate or select other media files.
enum AppMode {
  main,
  pickCollectionFiltersExternal,
  pickSingleMediaExternal,
  pickMultipleMediaExternal,
  pickMediaInternal,
  pickFilterInternal,
  screenSaver,
  setWallpaper,
  slideshow,
  view,
}

/// adds some utility methods to the AppMode enum .
extension ExtraAppMode on AppMode {
  /// Returns true if the app mode is main, pickCollectionFiltersExternal, or pickSingleMediaExternal. This means that the app can navigate to other pages in these modes.
  bool get canNavigate => {
        AppMode.main,
        AppMode.pickCollectionFiltersExternal,
        AppMode.pickSingleMediaExternal,
        AppMode.pickMultipleMediaExternal,
      }.contains(this);

  /// Returns true if the app mode is main or pickMultipleMediaExternal. This means that the app can select media in these modes.
  bool get canSelectMedia => {
        AppMode.main,
        AppMode.pickMultipleMediaExternal,
      }.contains(this);

  /// Returns true if the app mode is main. This means that the app can select a filter in this mode,like albumFilter.
  bool get canSelectFilter => this == AppMode.main;

  /// Returns true if the app mode is pickSingleMediaExternal, pickMultipleMediaExternal, or pickMediaInternal. This means that the app is in a mode where it is picking media.
  bool get isPickingMedia => {
        AppMode.pickSingleMediaExternal,
        AppMode.pickMultipleMediaExternal,
        AppMode.pickMediaInternal,
      }.contains(this);
}
