/// Base contract for synchronous-result use cases.
/// [Type] is the return type; [Params] is the input parameter type.
abstract interface class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// Use this when a use case takes no parameters.
class NoParams {
  const NoParams();
}
