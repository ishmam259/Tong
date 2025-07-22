import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_state_provider.dart';
import '../providers/identity_provider.dart';
import '../providers/networking_provider.dart';
import '../providers/chat_provider.dart';
import 'networking/socket_service.dart';
import 'networking/bluetooth_service.dart';
import 'networking/ble_service.dart';
import 'storage/local_storage_service.dart';
import 'encryption/encryption_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  try {
    print('Setting up external dependencies...');
    // External dependencies
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);

    print('Registering core services...');
    // Core services
    getIt.registerLazySingleton<LocalStorageService>(
      () => LocalStorageService(),
    );
    getIt.registerLazySingleton<EncryptionService>(() => EncryptionService());
    getIt.registerLazySingleton<SocketService>(() => SocketService());
    getIt.registerLazySingleton<BluetoothService>(() => BluetoothService());
    getIt.registerLazySingleton<BleService>(() => BleService());

    print('Registering providers...');
    // Providers
    getIt.registerLazySingleton<AppStateProvider>(() => AppStateProvider());
    getIt.registerLazySingleton<IdentityProvider>(() => IdentityProvider());
    getIt.registerLazySingleton<NetworkingProvider>(() => NetworkingProvider());
    getIt.registerLazySingleton<ChatProvider>(() => ChatProvider());

    print('Initializing services...');
    // Initialize providers
    await getIt<LocalStorageService>().initialize();
    print('LocalStorageService initialized');

    await getIt<AppStateProvider>().initialize();
    print('AppStateProvider initialized');

    await getIt<IdentityProvider>().initialize();
    print('IdentityProvider initialized');

    await getIt<NetworkingProvider>().initialize();
    print('NetworkingProvider initialized');

    await getIt<ChatProvider>().initialize();
    print('ChatProvider initialized');

    print('All services initialized successfully');
  } catch (e, stackTrace) {
    print('Error in setupServiceLocator: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}
