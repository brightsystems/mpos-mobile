sealed class Result<T> {
  const Result();

  factory Result.success({String? title, String? message, String? state, required T data}) = Success<T>;

  factory Result.failure({
    String? title,
    String? message,
    String? state,
    required Object error,
    StackTrace? stackTrace,
  }) = Failure<T>;

  String? get title => switch (this) {
    Success(title: final title) => title,
    Failure(title: final title) => title,
  };

  String? get message => switch (this) {
    Success(message: final message) => message,
    Failure(message: final message) => message,
  };

  String? get state => switch (this) {
    Success(state: final state) => state,
    Failure(state: final state) => state,
  };

  T? get data => switch (this) {
    Success(data: final data) => data,
    Failure() => null,
  };

  Object? get error => switch (this) {
    Success() => null,
    Failure(error: final error) => error,
  };

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  R? onSuccess<R>(R Function(Success<T> success) success) => switch (this) {
    Success() => success(this as Success<T>),
    Failure() => null,
  };

  R? onFailure<R>(R Function(Failure<T> failure) failure) => switch (this) {
    Success() => null,
    Failure() => failure(this as Failure<T>),
  };

  R when<R>({required R Function(Success<T> success) success, required R Function(Failure<T> failure) failure}) {
    return switch (this) {
      Success() => success(this as Success<T>),
      Failure() => failure(this as Failure<T>),
    };
  }
}

final class Success<T> extends Result<T> {
  @override
  final String? title;
  @override
  final String? message;
  @override
  final String? state;
  @override
  final T data;

  Success({this.title, this.message, this.state, required this.data});
}

final class Failure<T> extends Result<T> {
  @override
  final String? title;
  @override
  final String? message;
  @override
  final String? state;
  @override
  final Object error;
  final StackTrace? stackTrace;

  Failure({this.title, this.message, this.state, required this.error, this.stackTrace});
}
