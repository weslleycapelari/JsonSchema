unit Schema2REST.Templates;

(*
--------------------------------------------------------------------------------
Pascal source templates for generating Horse and DMVC REST endpoints.
--------------------------------------------------------------------------------
*)

interface

const
  HORSE_TEMPLATE =
    'unit %0:sRouter;' + sLineBreak +
    sLineBreak +
    'interface' + sLineBreak +
    sLineBreak +
    'uses' + sLineBreak +
    '  Horse, System.JSON, System.SysUtils, JsonSchema.Validator, JsonSchema.Core.Interfaces;' + sLineBreak +
    sLineBreak +
    'procedure Registry%0:sRoutes;' + sLineBreak +
    sLineBreak +
    'implementation' + sLineBreak +
    sLineBreak +
    'var' + sLineBreak +
    '  FSchemaJson: string = %1:s;' + sLineBreak +
    sLineBreak +
    'procedure ValidatePayload(Req: THorseRequest; Res: THorseResponse; Next: TProc);' + sLineBreak +
    'var' + sLineBreak +
    '  lValidator: TJsonSchemaValidator;' + sLineBreak +
    '  lSchema, lInstance: TJSONValue;' + sLineBreak +
    'begin' + sLineBreak +
    '  lSchema := TJSONObject.ParseJSONValue(FSchemaJson);' + sLineBreak +
    '  lInstance := TJSONObject.ParseJSONValue(Req.Body);' + sLineBreak +
    '  try' + sLineBreak +
    '    if not Assigned(lInstance) then' + sLineBreak +
    '    begin' + sLineBreak +
    '      Res.Send(TJSONObject.Create(TJSONPair.Create(''error'', ''Request body is not a valid JSON''))).Status(400);' + sLineBreak +
    '      Exit;' + sLineBreak +
    '    end;' + sLineBreak +
    '    ' + sLineBreak +
    '    lValidator := TJsonSchemaValidator.Create;' + sLineBreak +
    '    try' + sLineBreak +
    '      lValidator.Validate(lSchema, lInstance);' + sLineBreak +
    '      if not lValidator.IsValid then' + sLineBreak +
    '      begin' + sLineBreak +
    '        Res.Send(lValidator.Errors.Clone as TJSONArray).Status(400);' + sLineBreak +
    '        Exit;' + sLineBreak +
    '      end;' + sLineBreak +
    '    finally' + sLineBreak +
    '      lValidator.Free;' + sLineBreak +
    '    end;' + sLineBreak +
    '  finally' + sLineBreak +
    '    lSchema.Free;' + sLineBreak +
    '    lInstance.Free;' + sLineBreak +
    '  end;' + sLineBreak +
    '  Next;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure GetEntities(Req: THorseRequest; Res: THorseResponse; Next: TProc);' + sLineBreak +
    'begin' + sLineBreak +
    '  Res.Send(TJSONArray.Create).Status(200);' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure GetEntity(Req: THorseRequest; Res: THorseResponse; Next: TProc);' + sLineBreak +
    'begin' + sLineBreak +
    '  Res.Send(TJSONObject.Create(TJSONPair.Create(''id'', Req.Params[''id'']))).Status(200);' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure CreateEntity(Req: THorseRequest; Res: THorseResponse; Next: TProc);' + sLineBreak +
    'begin' + sLineBreak +
    '  Res.Send(TJSONObject.ParseJSONValue(Req.Body)).Status(201);' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure UpdateEntity(Req: THorseRequest; Res: THorseResponse; Next: TProc);' + sLineBreak +
    'begin' + sLineBreak +
    '  Res.Send(TJSONObject.ParseJSONValue(Req.Body)).Status(200);' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure DeleteEntity(Req: THorseRequest; Res: THorseResponse; Next: TProc);' + sLineBreak +
    'begin' + sLineBreak +
    '  Res.Status(204);' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure Registry%0:sRoutes;' + sLineBreak +
    'begin' + sLineBreak +
    '  THorse.Get(''/%2:s'', GetEntities);' + sLineBreak +
    '  THorse.Get(''/%2:s/:id'', GetEntity);' + sLineBreak +
    '  THorse.AddCallback(''/%2:s'', ValidatePayload).Post(''/%2:s'', CreateEntity);' + sLineBreak +
    '  THorse.AddCallback(''/%2:s/:id'', ValidatePayload).Put(''/%2:s/:id'', UpdateEntity);' + sLineBreak +
    '  THorse.Delete(''/%2:s/:id'', DeleteEntity);' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'end.';

  DMVC_TEMPLATE =
    'unit %0:sController;' + sLineBreak +
    sLineBreak +
    'interface' + sLineBreak +
    sLineBreak +
    'uses' + sLineBreak +
    '  MVCFramework, MVCFramework.Commons, System.JSON, System.SysUtils,' + sLineBreak +
    '  JsonSchema.Validator, JsonSchema.Core.Interfaces;' + sLineBreak +
    sLineBreak +
    'type' + sLineBreak +
    '  [MVCPath(''/%2:s'')]' + sLineBreak +
    '  [MVCProduces(''application/json'')]' + sLineBreak +
    '  T%0:sController = class(TMVCController)' + sLineBreak +
    '  private' + sLineBreak +
    '    FSchemaJson: string;' + sLineBreak +
    '    function ValidatePayload(const pBody: string; out pErrorsJson: string): Boolean;' + sLineBreak +
    '  public' + sLineBreak +
    '    constructor Create; override;' + sLineBreak +
    '    ' + sLineBreak +
    '    [MVCPath]' + sLineBreak +
    '    [MVCHTTPMethod([httpGET])]' + sLineBreak +
    '    procedure GetEntities;' + sLineBreak +
    sLineBreak +
    '    [MVCPath(''(/($id)'')]' + sLineBreak +
    '    [MVCHTTPMethod([httpGET])]' + sLineBreak +
    '    procedure GetEntity(const id: string);' + sLineBreak +
    sLineBreak +
    '    [MVCPath]' + sLineBreak +
    '    [MVCHTTPMethod([httpPOST])]' + sLineBreak +
    '    procedure CreateEntity;' + sLineBreak +
    sLineBreak +
    '    [MVCPath(''(/($id)'')]' + sLineBreak +
    '    [MVCHTTPMethod([httpPUT])]' + sLineBreak +
    '    procedure UpdateEntity(const id: string);' + sLineBreak +
    sLineBreak +
    '    [MVCPath(''(/($id)'')]' + sLineBreak +
    '    [MVCHTTPMethod([httpDELETE])]' + sLineBreak +
    '    procedure DeleteEntity(const id: string);' + sLineBreak +
    '  end;' + sLineBreak +
    sLineBreak +
    'implementation' + sLineBreak +
    sLineBreak +
    'constructor T%0:sController.Create;' + sLineBreak +
    'begin' + sLineBreak +
    '  inherited Create;' + sLineBreak +
    '  FSchemaJson := %1:s;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'function T%0:sController.ValidatePayload(const pBody: string; out pErrorsJson: string): Boolean;' + sLineBreak +
    'var' + sLineBreak +
    '  lValidator: TJsonSchemaValidator;' + sLineBreak +
    '  lSchema, lInstance: TJSONValue;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := False;' + sLineBreak +
    '  pErrorsJson := '''';' + sLineBreak +
    '  lSchema := TJSONObject.ParseJSONValue(FSchemaJson);' + sLineBreak +
    '  lInstance := TJSONObject.ParseJSONValue(pBody);' + sLineBreak +
    '  try' + sLineBreak +
    '    if not Assigned(lInstance) then' + sLineBreak +
    '    begin' + sLineBreak +
    '      pErrorsJson := ''{"error": "Request body is not a valid JSON"}'';' + sLineBreak +
    '      Exit;' + sLineBreak +
    '    end;' + sLineBreak +
    '    ' + sLineBreak +
    '    lValidator := TJsonSchemaValidator.Create;' + sLineBreak +
    '    try' + sLineBreak +
    '      lValidator.Validate(lSchema, lInstance);' + sLineBreak +
    '      Result := lValidator.IsValid;' + sLineBreak +
    '      if not Result then' + sLineBreak +
    '        pErrorsJson := lValidator.Errors.ToString;' + sLineBreak +
    '    finally' + sLineBreak +
    '      lValidator.Free;' + sLineBreak +
    '    end;' + sLineBreak +
    '  finally' + sLineBreak +
    '    lSchema.Free;' + sLineBreak +
    '    lInstance.Free;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure T%0:sController.GetEntities;' + sLineBreak +
    'begin' + sLineBreak +
    '  Render(TJSONArray.Create);' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure T%0:sController.GetEntity(const id: string);' + sLineBreak +
    'begin' + sLineBreak +
    '  Render(TJSONObject.Create(TJSONPair.Create(''id'', id)));' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure T%0:sController.CreateEntity;' + sLineBreak +
    'var' + sLineBreak +
    '  lErrors: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  if not ValidatePayload(Context.Request.Body, lErrors) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    Render(HTTP_STATUS.BadRequest, lErrors);' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  end;' + sLineBreak +
    '  Render(HTTP_STATUS.Created, TJSONObject.ParseJSONValue(Context.Request.Body));' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure T%0:sController.UpdateEntity(const id: string);' + sLineBreak +
    'var' + sLineBreak +
    '  lErrors: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  if not ValidatePayload(Context.Request.Body, lErrors) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    Render(HTTP_STATUS.BadRequest, lErrors);' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  end;' + sLineBreak +
    '  Render(TJSONObject.ParseJSONValue(Context.Request.Body));' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure T%0:sController.DeleteEntity(const id: string);' + sLineBreak +
    'begin' + sLineBreak +
    '  Render(HTTP_STATUS.NoContent, '''');' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'end.';

implementation

end.
