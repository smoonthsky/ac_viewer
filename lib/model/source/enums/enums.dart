enum SourceState { loading, cataloguing, locatingCountries, locatingPlaces, ready }

///size for a total size of an album.
enum ChipSortFactor { date, name, count, size }

///分组依据，importance,层级{相册、截图；应用相册s；其他}，mimeType,类型{图像；混合；视频}，volume,存储卷，跟不分差别不大。
enum AlbumChipGroupFactor { none, importance, mimeType, volume }

///
enum EntrySortFactor { date, name, rating, size }

///按添加月份和日期，相册在搜索结果分类中使用
enum EntryGroupFactor { none, album, month, day }

///布局格式
enum TileLayout { mosaic, grid, list }
