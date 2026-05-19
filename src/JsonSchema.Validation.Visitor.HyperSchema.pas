unit JsonSchema.Validation.Visitor.HyperSchema;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Interfaces;

type
  /// <summary>
  ///   Base visitor that handles JSON Hyper-Schema link keywords:
  ///   base, links, href, targetSchema, submissionSchema, and hrefSchema.
  /// </summary>
  TBaseHyperSchemaVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseHyperSchemaVisitor<T>)
    [VisitorKeyword('base')]
    procedure VisitBase(const pValue: TJSONString);
    [VisitorKeyword('links')]
    procedure VisitLinks(const pValue: TJSONArray);

    [VisitorKeyword('href')]
    procedure VisitHref(const pValue: TJSONString);
    [VisitorKeyword('targetSchema')]
    procedure VisitTargetSchema(const pValue: TJSONValue);
    [VisitorKeyword('submissionSchema')]
    procedure VisitSubmissionSchema(const pValue: TJSONValue);
    [VisitorKeyword('hrefSchema')]
    procedure VisitHrefSchema(const pValue: TJSONValue);
  end;

implementation

{ TBaseHyperSchemaVisitor<T> }

procedure TBaseHyperSchemaVisitor<T>.VisitBase(const pValue: TJSONString);
begin

end;

procedure TBaseHyperSchemaVisitor<T>.VisitHref(const pValue: TJSONString);
begin

end;

procedure TBaseHyperSchemaVisitor<T>.VisitHrefSchema(const pValue: TJSONValue);
begin

end;

procedure TBaseHyperSchemaVisitor<T>.VisitLinks(const pValue: TJSONArray);
begin

end;

procedure TBaseHyperSchemaVisitor<T>.VisitSubmissionSchema(const pValue: TJSONValue);
begin

end;

procedure TBaseHyperSchemaVisitor<T>.VisitTargetSchema(const pValue: TJSONValue);
begin

end;

end.
