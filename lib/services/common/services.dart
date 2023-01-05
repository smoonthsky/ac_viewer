import 'package:aves/model/availability.dart';
import 'package:aves/model/db/db_metadata.dart';
import 'package:aves/model/db/db_metadata_sqflite.dart';
import 'package:aves/model/settings/store/store.dart';
import 'package:aves/model/settings/store/store_shared_pref.dart';
import 'package:aves/services/android_app_service.dart';
import 'package:aves/services/device_service.dart';
import 'package:aves/services/media/embedded_data_service.dart';
import 'package:aves/services/media/media_edit_service.dart';
import 'package:aves/services/media/media_fetch_service.dart';
import 'package:aves/services/media/media_session_service.dart';
import 'package:aves/services/media/media_store_service.dart';
import 'package:aves/services/metadata/metadata_edit_service.dart';
import 'package:aves/services/metadata/metadata_fetch_service.dart';
import 'package:aves/services/storage_service.dart';
import 'package:aves/services/window_service.dart';
import 'package:aves_report/aves_report.dart';
import 'package:aves_report_platform/aves_report_platform.dart';
import 'package:aves_services/aves_services.dart';
import 'package:aves_services_platform/aves_services_platform.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;

final getIt = GetIt.instance;

/// fixed implementation is easier for test driver setup.
/// an instance of SharedPrefSettingsStore class, static, to the settingsStore variable that implements the SettingsStore abstract class.
/// This implementation uses the shared preferences feature in Flutter to persist the settings.
final SettingsStore settingsStore = SharedPrefSettingsStore();

final p.Context pContext = getIt<p.Context>();
final AvesAvailability availability = getIt<AvesAvailability>();
final MetadataDb metadataDb = getIt<MetadataDb>();

final AndroidAppService androidAppService = getIt<AndroidAppService>();
final DeviceService deviceService = getIt<DeviceService>();
final EmbeddedDataService embeddedDataService = getIt<EmbeddedDataService>();
final MediaEditService mediaEditService = getIt<MediaEditService>();
final MediaFetchService mediaFetchService = getIt<MediaFetchService>();
final MediaSessionService mediaSessionService = getIt<MediaSessionService>();
final MediaStoreService mediaStoreService = getIt<MediaStoreService>();
final MetadataEditService metadataEditService = getIt<MetadataEditService>();
final MetadataFetchService metadataFetchService = getIt<MetadataFetchService>();

final MobileServices mobileServices = getIt<MobileServices>();
//Firebase Crashlytics 是一款轻量级的实时崩溃报告器，可帮助您跟踪、确定优先级并修复影响应用质量的稳定性问题。 Crashlytics 通过智能地对崩溃进行分组并突出显示导致它们的情况，可以节省您的故障排除时间。
final ReportService reportService = getIt<ReportService>();

final StorageService storageService = getIt<StorageService>();
final WindowService windowService = getIt<WindowService>();

/// initPlatformServices(): This function is responsible for registering various platform services in GetIt.
///
/// Services are registered as lazy singleton, which means that they are created only the first time they are requested, and the same instance is returned every time afterwards.
void initPlatformServices() {
  getIt.registerLazySingleton<p.Context>(p.Context.new);
  getIt.registerLazySingleton<AvesAvailability>(LiveAvesAvailability.new);
  getIt.registerLazySingleton<MetadataDb>(SqfliteMetadataDb.new);

  getIt.registerLazySingleton<AndroidAppService>(PlatformAndroidAppService.new);
  getIt.registerLazySingleton<DeviceService>(PlatformDeviceService.new);
  getIt.registerLazySingleton<EmbeddedDataService>(PlatformEmbeddedDataService.new);
  getIt.registerLazySingleton<MediaEditService>(PlatformMediaEditService.new);
  getIt.registerLazySingleton<MediaFetchService>(PlatformMediaFetchService.new);
  getIt.registerLazySingleton<MediaSessionService>(PlatformMediaSessionService.new);
  getIt.registerLazySingleton<MediaStoreService>(PlatformMediaStoreService.new);
  getIt.registerLazySingleton<MetadataEditService>(PlatformMetadataEditService.new);
  getIt.registerLazySingleton<MetadataFetchService>(PlatformMetadataFetchService.new);
  getIt.registerLazySingleton<MobileServices>(PlatformMobileServices.new);
  getIt.registerLazySingleton<ReportService>(PlatformReportService.new);
  getIt.registerLazySingleton<StorageService>(PlatformStorageService.new);
  getIt.registerLazySingleton<WindowService>(PlatformWindowService.new);
}
// For Example,
// The line `getIt.registerLazySingleton<AvesAvailability>(LiveAvesAvailability.new);` is registering a singleton of the AvesAvailability type that is created lazily, which means it will only be created the first time it is used or accessed.
// So the first time you access availability, it will use the registered LiveAvesAvailability singleton to create an instance of it and return it.
// In this code, the top-level definition for the AndroidAppService variable is executed before the initPlatformServices function is called.
//This means that at the time the AndroidAppService variable is created, it's corresponding registerLazySingleton call in initPlatformServices function has not yet been executed.
// But it's not an issue, because in this case, you're using a GetIt package that returns a default value when the registerLazySingleton has not been done yet, it will call it only the first time you request the instance.
// So you don't need to worry about it. You can ensure the initPlatformServices function is called before accessing the service, or if you are going to use the service right after initializing the app, you can make sure that the initPlatformServices function is called before main function.