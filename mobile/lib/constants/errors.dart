/// Base class which is used to check if an Exception is a custom exception
sealed class GreatMemoriesErrors {
  const GreatMemoriesErrors();
}

class NoResponseDtoError extends GreatMemoriesErrors implements Exception {
  const NoResponseDtoError();

  @override
  String toString() => "Response Dto is null";
}
