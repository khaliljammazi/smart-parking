import 'package:flutter/foundation.dart';

/// Base class for all repositories providing common functionality
/// and standardized error handling
abstract class BaseRepository {
  /// Executes an async operation with standardized error handling
  /// 
  /// Returns a Result<T> containing either success data or error message
  @protected
  Future<Result<T>> executeOperation<T>(
    Future<T> Function() operation, {
    String? errorMessage,
  }) async {
    try {
      final data = await operation();
      return Result.success(data);
    } catch (e) {
      final message = errorMessage ?? 'An error occurred: ${e.toString()}';
      if (kDebugMode) {
        print('Repository Error: $message');
      }
      return Result.failure(message);
    }
  }

  /// Executes an async operation that returns bool
  @protected
  Future<Result<bool>> executeBoolOperation(
    Future<bool> Function() operation, {
    String? errorMessage,
  }) async {
    try {
      final success = await operation();
      if (success) {
        return Result.success(true);
      } else {
        return Result.failure(errorMessage ?? 'Operation failed');
      }
    } catch (e) {
      final message = errorMessage ?? 'An error occurred: ${e.toString()}';
      if (kDebugMode) {
        print('Repository Error: $message');
      }
      return Result.failure(message);
    }
  }
}

/// Result wrapper for repository operations
/// Provides type-safe success/failure handling
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result.success(this.data)
      : error = null,
        isSuccess = true;

  Result.failure(this.error)
      : data = null,
        isSuccess = false;

  /// Execute callback on success
  void onSuccess(void Function(T data) callback) {
    if (isSuccess && data != null) {
      callback(data);
    }
  }

  /// Execute callback on failure
  void onFailure(void Function(String error) callback) {
    if (!isSuccess && error != null) {
      callback(error);
    }
  }

  /// Map the result data to another type
  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        return Result.success(mapper(data));
      } catch (e) {
        return Result.failure(e.toString());
      }
    }
    return Result.failure(error ?? 'Unknown error');
  }

  /// Get data or throw error
  T getOrThrow() {
    if (isSuccess && data != null) {
      return data!;
    }
    throw Exception(error ?? 'Unknown error');
  }

  /// Get data or return default value
  T getOrDefault(T defaultValue) {
    return data ?? defaultValue;
  }
}
