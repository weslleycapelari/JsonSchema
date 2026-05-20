unit JsonSchema.Visitor.RelativePointer.Stub;

interface

uses
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types;

type
  /// <summary>
  ///   Stub implementation for the Relative JSON Pointer vocabulary.
  ///   This vocabulary is not yet implemented; the stub exists only to satisfy
  ///   the visitor composition pattern without introducing conditional compilation.
  /// </summary>
  TStubRelativeJsonPointer<T: IVisitor<T>> = class(TBase<T>, IBaseRelativeJsonPointer<T>)
    // No methods required by IBaseRelativeJsonPointer<T>
  end;

implementation

end.
