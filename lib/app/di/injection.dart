import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/locale/locale_cubit.dart';
import 'package:mpos_mobile/core/media/fake_media_service.dart';
import 'package:mpos_mobile/core/media/media_service.dart';
import 'package:mpos_mobile/core/media/supabase_media_service.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/core/theme/theme_cubit.dart';
import 'package:mpos_mobile/features/admin/data/datasources/admin_datasource.dart';
import 'package:mpos_mobile/features/admin/data/datasources/fake/fake_admin_datasource.dart';
import 'package:mpos_mobile/features/admin/data/datasources/remote/admin_remote_datasource.dart';
import 'package:mpos_mobile/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mpos_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:mpos_mobile/features/auth/data/datasources/fake/fake_auth_datasource.dart';
import 'package:mpos_mobile/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:mpos_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mpos_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mpos_mobile/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/pos/data/datasources/fake/fake_invoice_datasource.dart';
import 'package:mpos_mobile/features/pos/data/datasources/fake/fake_menu_datasource.dart';
import 'package:mpos_mobile/features/pos/data/datasources/fake/fake_order_datasource.dart';
import 'package:mpos_mobile/features/pos/data/datasources/invoice_datasource.dart';
import 'package:mpos_mobile/features/pos/data/datasources/menu_datasource.dart';
import 'package:mpos_mobile/features/pos/data/datasources/order_datasource.dart';
import 'package:mpos_mobile/features/pos/data/datasources/remote/invoice_remote_datasource.dart';
import 'package:mpos_mobile/features/pos/data/datasources/remote/menu_remote_datasource.dart';
import 'package:mpos_mobile/features/pos/data/datasources/remote/order_remote_datasource.dart';
import 'package:mpos_mobile/features/pos/data/repositories/invoice_repository_impl.dart';
import 'package:mpos_mobile/features/pos/data/repositories/menu_repository_impl.dart';
import 'package:mpos_mobile/features/pos/data/repositories/order_repository_impl.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/invoice_repository.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/menu_repository.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/order_repository.dart';
import 'package:mpos_mobile/features/pos/domain/usecases/invoice_usecases.dart';
import 'package:mpos_mobile/features/pos/domain/usecases/menu_usecases.dart';
import 'package:mpos_mobile/features/pos/domain/usecases/order_usecases.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/onboarding/data/datasources/fake/fake_onboarding_datasource.dart';
import 'package:mpos_mobile/features/onboarding/data/datasources/onboarding_datasource.dart';
import 'package:mpos_mobile/features/onboarding/data/datasources/remote/onboarding_remote_datasource.dart';
import 'package:mpos_mobile/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:mpos_mobile/features/onboarding/domain/repositories/onboarding_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies(SharedPreferences sharedPreferences) async {
  if (!getIt.isRegistered<SharedPreferences>()) {
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  }

  if (!getIt.isRegistered<SessionStorage>()) {
    getIt.registerLazySingleton(() => SessionStorage(getIt<SharedPreferences>()));
  }

  if (MposConfig.mockMode) {
    _registerMockDataLayer();
  } else {
    _registerApiDataLayer();
  }

  if (!getIt.isRegistered<MediaService>()) {
    getIt.registerLazySingleton<MediaService>(
      () => MposConfig.mockMode ? FakeMediaService() : SupabaseMediaService(),
    );
  }

  if (!getIt.isRegistered<ThemeCubit>()) {
    getIt.registerLazySingleton(() => ThemeCubit(getIt<SharedPreferences>()));
  }

  if (!getIt.isRegistered<LocaleCubit>()) {
    getIt.registerLazySingleton(() => LocaleCubit(getIt<SharedPreferences>()));
  }

  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDatasource: getIt<AuthDatasource>(), sessionStorage: getIt<SessionStorage>()),
    );
  }

  if (!getIt.isRegistered<AdminRepository>()) {
    getIt.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(getIt<AdminDatasource>()));
  }

  if (!getIt.isRegistered<OnboardingRepository>()) {
    getIt.registerLazySingleton<OnboardingRepository>(() => OnboardingRepositoryImpl(getIt<OnboardingDatasource>()));
  }

  if (!getIt.isRegistered<MenuRepository>()) {
    getIt.registerLazySingleton<MenuRepository>(
      () => MenuRepositoryImpl(remoteDatasource: getIt<MenuDatasource>(), sessionStorage: getIt<SessionStorage>()),
    );
  }

  if (!getIt.isRegistered<OrderRepository>()) {
    getIt.registerLazySingleton<OrderRepository>(
      () => OrderRepositoryImpl(remoteDatasource: getIt<OrderDatasource>(), sessionStorage: getIt<SessionStorage>()),
    );
  }

  if (!getIt.isRegistered<InvoiceRepository>()) {
    getIt.registerLazySingleton<InvoiceRepository>(() => InvoiceRepositoryImpl(datasource: getIt<InvoiceDatasource>()));
  }

  if (!getIt.isRegistered<ShiftLoginUsecase>()) {
    getIt.registerLazySingleton(() => ShiftLoginUsecase(getIt<AuthRepository>()));
    getIt.registerLazySingleton(() => LoadSessionUsecase(getIt<AuthRepository>()));
    getIt.registerLazySingleton(() => LogoutUsecase(getIt<AuthRepository>()));
    getIt.registerLazySingleton(() => RequestOtpUsecase(getIt<AuthRepository>()));
    getIt.registerLazySingleton(() => VerifyOtpUsecase(getIt<AuthRepository>()));
    getIt.registerLazySingleton(() => RefreshSessionUsecase(getIt<AuthRepository>()));
    getIt.registerLazySingleton(() => SaveSessionUsecase(getIt<AuthRepository>()));
  }

  if (!getIt.isRegistered<SyncBranchMenuUsecase>()) {
    getIt.registerLazySingleton(() => SyncBranchMenuUsecase(getIt<MenuRepository>()));
    getIt.registerLazySingleton(() => LoadOpenOrdersUsecase(getIt<OrderRepository>()));
    getIt.registerLazySingleton(() => CreateTicketUsecase(getIt<OrderRepository>()));
    getIt.registerLazySingleton(() => AddItemToTicketUsecase(getIt<OrderRepository>()));
    getIt.registerLazySingleton(() => UpdateTicketLineQuantityUsecase(getIt<OrderRepository>()));
    getIt.registerLazySingleton(() => UpdateTicketLineDiscountUsecase(getIt<OrderRepository>()));
    getIt.registerLazySingleton(() => RemoveTicketLineUsecase(getIt<OrderRepository>()));
    getIt.registerLazySingleton(() => UpdateTicketTableNumberUsecase(getIt<OrderRepository>()));
    getIt.registerLazySingleton(() => SettleTicketUsecase(getIt<OrderRepository>()));
    getIt.registerLazySingleton(() => SubmitOrderInvoiceUsecase(getIt<InvoiceRepository>()));
    getIt.registerLazySingleton(() => PollOrderInvoiceUsecase(getIt<InvoiceRepository>()));
  }

  if (!getIt.isRegistered<AuthBloc>()) {
    getIt.registerFactory(
      () => AuthBloc(
        loadSessionUsecase: getIt<LoadSessionUsecase>(),
        requestOtpUsecase: getIt<RequestOtpUsecase>(),
        verifyOtpUsecase: getIt<VerifyOtpUsecase>(),
        shiftLoginUsecase: getIt<ShiftLoginUsecase>(),
        saveSessionUsecase: getIt<SaveSessionUsecase>(),
        logoutUsecase: getIt<LogoutUsecase>(),
      ),
    );
  }

  if (!getIt.isRegistered<PosBloc>()) {
    getIt.registerFactory(
      () => PosBloc(
        syncBranchMenuUsecase: getIt<SyncBranchMenuUsecase>(),
        loadOpenOrdersUsecase: getIt<LoadOpenOrdersUsecase>(),
        createTicketUsecase: getIt<CreateTicketUsecase>(),
        addItemToTicketUsecase: getIt<AddItemToTicketUsecase>(),
        updateTicketLineQuantityUsecase: getIt<UpdateTicketLineQuantityUsecase>(),
        updateTicketLineDiscountUsecase: getIt<UpdateTicketLineDiscountUsecase>(),
        removeTicketLineUsecase: getIt<RemoveTicketLineUsecase>(),
        updateTicketTableNumberUsecase: getIt<UpdateTicketTableNumberUsecase>(),
        settleTicketUsecase: getIt<SettleTicketUsecase>(),
        orderRepository: getIt<OrderRepository>(),
        sessionStorage: getIt<SessionStorage>(),
        submitOrderInvoiceUsecase: getIt<SubmitOrderInvoiceUsecase>(),
        pollOrderInvoiceUsecase: getIt<PollOrderInvoiceUsecase>(),
      ),
    );
  }
}

void _registerMockDataLayer() {
  if (!getIt.isRegistered<AuthDatasource>()) {
    getIt.registerLazySingleton<AuthDatasource>(FakeAuthDatasource.new);
  }

  if (!getIt.isRegistered<MenuDatasource>()) {
    getIt.registerLazySingleton<MenuDatasource>(FakeMenuDatasource.new);
  }

  if (!getIt.isRegistered<OrderDatasource>()) {
    getIt.registerLazySingleton<OrderDatasource>(FakeOrderDatasource.new);
  }

  if (!getIt.isRegistered<InvoiceDatasource>()) {
    getIt.registerLazySingleton<InvoiceDatasource>(FakeInvoiceDatasource.new);
  }

  if (!getIt.isRegistered<AdminDatasource>()) {
    getIt.registerLazySingleton<AdminDatasource>(FakeAdminDatasource.new);
  }

  if (!getIt.isRegistered<OnboardingDatasource>()) {
    getIt.registerLazySingleton<OnboardingDatasource>(FakeOnboardingDatasource.new);
  }
}

void _registerApiDataLayer() {
  if (!getIt.isRegistered<http.Client>()) {
    getIt.registerLazySingleton<http.Client>(http.Client.new);
  }

  if (!getIt.isRegistered<MposApiClient>()) {
    getIt.registerLazySingleton(
      () => MposApiClient(httpClient: getIt<http.Client>(), sessionStorage: getIt<SessionStorage>()),
    );
  }

  if (!getIt.isRegistered<AuthDatasource>()) {
    getIt.registerLazySingleton<AuthDatasource>(() => AuthRemoteDatasource(getIt<MposApiClient>()));
  }

  if (!getIt.isRegistered<MenuDatasource>()) {
    getIt.registerLazySingleton<MenuDatasource>(() => MenuRemoteDatasource(getIt<MposApiClient>()));
  }

  if (!getIt.isRegistered<OrderDatasource>()) {
    getIt.registerLazySingleton<OrderDatasource>(() => OrderRemoteDatasource(getIt<MposApiClient>()));
  }

  if (!getIt.isRegistered<InvoiceDatasource>()) {
    getIt.registerLazySingleton<InvoiceDatasource>(() => InvoiceRemoteDatasource(getIt<MposApiClient>()));
  }

  if (!getIt.isRegistered<AdminDatasource>()) {
    getIt.registerLazySingleton<AdminDatasource>(() => AdminRemoteDatasource(getIt<MposApiClient>()));
  }

  if (!getIt.isRegistered<OnboardingDatasource>()) {
    getIt.registerLazySingleton<OnboardingDatasource>(() => OnboardingRemoteDatasource(getIt<MposApiClient>()));
  }
}
