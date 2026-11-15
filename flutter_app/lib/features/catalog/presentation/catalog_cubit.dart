import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/entities/catalog.dart';
import '../domain/usecases/get_catalog.dart';

enum CatalogStatus { loading, ready, failed }

final class CatalogState extends Equatable {
  const CatalogState({
    this.status = CatalogStatus.loading,
    this.catalog,
    this.failure,
  });

  final CatalogStatus status;
  final Catalog? catalog;
  final Failure? failure;

  @override
  List<Object?> get props => [status, catalog, failure];
}

/// App-wide content. Loaded once at startup and shared by all screens.
final class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._getCatalog) : super(const CatalogState());

  final GetCatalog _getCatalog;

  Future<void> load() async {
    emit(const CatalogState());
    final result = await _getCatalog(const NoParams());
    if (isClosed) return;
    emit(
      result.fold(
        (failure) =>
            CatalogState(status: CatalogStatus.failed, failure: failure),
        (catalog) =>
            CatalogState(status: CatalogStatus.ready, catalog: catalog),
      ),
    );
  }
}
