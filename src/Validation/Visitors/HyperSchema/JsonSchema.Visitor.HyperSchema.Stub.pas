unit JsonSchema.Visitor.HyperSchema.Stub;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types;

type
  /// <summary>
  ///   Stub implementation for the JSON Hyper-Schema vocabulary.
  ///   This vocabulary is not yet implemented; the stub exists only to satisfy
  ///   the visitor composition pattern without introducing conditional compilation.
  ///   All methods are no‑op.
  /// </summary>
  TStubHyperSchemaVisitor<T: IVisitor<T>> = class(TBase<T>, IBaseHyperSchemaVisitor<T>)
  public
    procedure VisitBase(const pValue: TJSONString);
    procedure VisitLinks(const pValue: TJSONArray);
    procedure VisitHref(const pValue: TJSONString);
    procedure VisitTargetSchema(const pValue: TJSONValue);
    procedure VisitSubmissionSchema(const pValue: TJSONValue);
    procedure VisitHrefSchema(const pValue: TJSONValue);
  end;

implementation

{ TStubHyperSchemaVisitor<T> }

procedure TStubHyperSchemaVisitor<T>.VisitBase(const pValue: TJSONString);
begin
  // No operation – Hyper-Schema not implemented
end;

procedure TStubHyperSchemaVisitor<T>.VisitLinks(const pValue: TJSONArray);
begin
  // No operation – Hyper-Schema not implemented
end;

procedure TStubHyperSchemaVisitor<T>.VisitHref(const pValue: TJSONString);
begin
  // No operation – Hyper-Schema not implemented
end;

procedure TStubHyperSchemaVisitor<T>.VisitTargetSchema(const pValue: TJSONValue);
begin
  // No operation – Hyper-Schema not implemented
end;

procedure TStubHyperSchemaVisitor<T>.VisitSubmissionSchema(const pValue: TJSONValue);
begin
  // No operation – Hyper-Schema not implemented
end;

procedure TStubHyperSchemaVisitor<T>.VisitHrefSchema(const pValue: TJSONValue);
begin
  // No operation – Hyper-Schema not implemented
end;

end.
