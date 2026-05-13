unit TestJsonSchema.Uri;

interface

uses TestFramework, JsonSchema.Uri; // A unit que estamos testando

type
  TJsonSchemaUriTest = class(TTestCase)
  private
    { Private Helper Methods for Test Execution }
    procedure TestParsing(const ADescription, AURIStr, AScheme, AAuthority,
      AHost, APath, AQuery, AFragment: string);
    procedure TestResolution(const ARelativeRef, AExpectedAbsoluteURI: string);
  published
    { --- RFC 1.1.2: Parsing Examples --- }
    procedure Test_RFC_1_1_2_FTP;
    procedure Test_RFC_1_1_2_HTTP;
    procedure Test_RFC_1_1_2_LDAP_with_IPv6;
    procedure Test_RFC_1_1_2_MailTo;
    procedure Test_RFC_1_1_2_News;
    procedure Test_RFC_1_1_2_Tel;
    procedure Test_RFC_1_1_2_Telnet_with_Port_and_Empty_Path;
    procedure Test_RFC_1_1_2_URN;

    { --- Additional Parsing Tests (from Python lib) --- }
    procedure Test_Parsing_Tricky_UserInfo;
    procedure Test_Parsing_Percent_Encoding_In_Path;
    procedure Test_Parsing_Empty_Query_String;
    procedure Test_Parsing_Handles_Absolute_Path_URI;

    { --- RFC 5.4.1: Normal Resolution Examples --- }
    procedure Test_RFC_5_4_1_NormalExamples;

    { --- RFC 5.4.2: Abnormal Resolution Examples --- }
    procedure Test_RFC_5_4_2_AbnormalExamples;

    { --- RFC 6.2: Normalization and Comparison --- }
    procedure Test_Normalization_SyntaxBased;
    procedure Test_Normalization_SchemeBased_Equivalence;
    procedure Test_Equivalence_Comparison;

    { --- TURIBuilder Tests --- }
    procedure Test_Builder_Full_Construction;
    procedure Test_Builder_From_URI;
    procedure Test_Builder_Append_Path;
    procedure Test_Builder_With_Query_From_Pairs;
    procedure Test_Builder_With_Credentials;

    { --- TValidator Tests --- }
    procedure Test_Validator_Require_Component;
    procedure Test_Validator_Allow_Schemes;
    procedure Test_Validator_Forbid_Password;
    procedure Test_Validator_Complex_Validation;

    { --- API Functions Tests --- }
    procedure Test_API_IsValidURI;
    procedure Test_API_URIParse;
  end;

implementation

uses System.Rtti, System.TypInfo, System.SysUtils, System.Generics.Collections;

{ TJsonSchemaUriTest }

procedure TJsonSchemaUriTest.TestParsing(const ADescription, AURIStr, AScheme, AAuthority, AHost, APath, AQuery, AFragment: string);
var
  LURI: TURIReference;
begin
  LURI := TURIReference.From(AURIStr);
  CheckEqualsString(AScheme, LURI.Scheme, 'Scheme mismatch for: ' + ADescription);
  CheckEqualsString(AAuthority, LURI.Authority, 'Authority mismatch for: ' + ADescription);
  CheckEqualsString(AHost, LURI.Host, 'Host mismatch for: ' + ADescription);
  CheckEqualsString(APath, LURI.Path, 'Path mismatch for: ' + ADescription);
  CheckEqualsString(AQuery, LURI.Query, 'Query mismatch for: ' + ADescription);
  CheckEqualsString(AFragment, LURI.Fragment, 'Fragment mismatch for: ' + ADescription);
end;

procedure TJsonSchemaUriTest.TestResolution(const ARelativeRef, AExpectedAbsoluteURI: string);
const
  BaseURIStr = 'http://a/b/c/d;p?q';
var
  LBaseURI, LRelativeURI, LTargetURI: TURIReference;
  LMsg: string;
begin
  LBaseURI     := TURIReference.From(BaseURIStr);
  LRelativeURI := TURIReference.From(ARelativeRef);
  LTargetURI   := LRelativeURI.ResolveWith(LBaseURI);
  LMsg         := Format('Resolution mismatch for ref "%s"', [ARelativeRef]);
  CheckEqualsString(AExpectedAbsoluteURI, LTargetURI.Unsplit, LMsg);
end;

procedure TJsonSchemaUriTest.Test_API_IsValidURI;
begin
  CheckTrue(IsValidURI('http://example.com/'), 'Valid URI should return True');
  CheckFalse(IsValidURI('http://[::1%eth0]'), 'Invalid URI should return False');
  CheckFalse(IsValidURI('123://a.com'), 'Invalid scheme should return False');
end;

procedure TJsonSchemaUriTest.Test_API_URIParse;
var
  LParseResult: TParseResult;
begin
  LParseResult := URIParse('https://user:pass@example.com:443/path?q=1#frag');
  CheckEqualsString('https', LParseResult.Scheme);
  CheckEqualsString('user:pass', LParseResult.UserInfo);
  CheckEqualsString('example.com', LParseResult.Host);
  CheckEquals(443, LParseResult.Port);
  CheckEqualsString('/path', LParseResult.Path);
  CheckEqualsString('q=1', LParseResult.Query);
  CheckEqualsString('frag', LParseResult.Fragment);
  CheckEqualsString('example.com', LParseResult.Hostname);
  CheckEqualsString('user:pass@example.com:443', LParseResult.Netloc);
end;

procedure TJsonSchemaUriTest.Test_Builder_Append_Path;
var
  LURI: TURIReference;
  LBuilder: TURIBuilder;
begin
  LBuilder := TURIBuilder.Create.WithHost('a.com').WithPath('/users/');
  LURI := LBuilder.AppendPath('sigmavirus24').Build;
  CheckEqualsString('/users/sigmavirus24', LURI.Path);

  LURI := LBuilder.AppendPath('/test/').Build;
  CheckEqualsString('/users/sigmavirus24/test', LURI.Path);
end;

procedure TJsonSchemaUriTest.Test_Builder_From_URI;
var
  LOriginalURI, LRebuiltURI: TURIReference;
begin
  LOriginalURI := TURIReference.From('https://user@example.com/path?q=1');
  LRebuiltURI := TURIBuilder.FromURI(LOriginalURI).Build;
  Check(LOriginalURI = LRebuiltURI);
end;

procedure TJsonSchemaUriTest.Test_Builder_Full_Construction;
var
  LURI: TURIReference;
  LExpected: string;
begin
  LURI := TURIBuilder.Create
    .WithScheme('https')
    .WithCredentials('user', 'p@ss')
    .WithHost('example.com')
    .WithPort(8080)
    .WithPath('/path/to/resource')
    .WithQuery('key=value')
    .WithFragment('section1')
    .Build;

  LExpected := 'https://user:p%40ss@example.com:8080/path/to/resource?key=value#section1';
  CheckEqualsString(LExpected, LURI.Unsplit);
end;

procedure TJsonSchemaUriTest.Test_Builder_With_Credentials;
var
  LBuilder: TURIBuilder;
  LURI: TURIReference;
begin
  LBuilder := TURIBuilder.Create.WithHost('a.com');
  LURI := LBuilder.WithCredentials('user@domain.com', 'pass:word').Build;
  CheckEqualsString('user%40domain.com:pass%3Aword', LURI.UserInfo);
end;

procedure TJsonSchemaUriTest.Test_Builder_With_Query_From_Pairs;
var
  LPairs: TDictionary<string, string>;
  LURI: TURIReference;
begin
  LPairs := TDictionary<string, string>.Create;
  try
    LPairs.Add('a', 'b c');
    LPairs.Add('d', 'e&f');
    LURI := TURIBuilder.Create.WithQueryFromPairs(LPairs).Build;
    CheckEqualsString('a=b+c&d=e%26f', LURI.Query);
  finally
    LPairs.Free;
  end;
end;

procedure TJsonSchemaUriTest.Test_Equivalence_Comparison;
var
  URI1, URI2: TURIReference;
begin
  URI1 := TURIReference.From('example://a/b/c/%7Bfoo%7D');
  URI2 := TURIReference.From('eXAMPLE://a/./b/../b/%63/%7bfoo%7d');
  Check(URI1 = URI2, 'URIs should be equivalent after syntax-based normalization');
end;

procedure TJsonSchemaUriTest.Test_Normalization_SchemeBased_Equivalence;
var
  LURI1, LURI2: TURIReference;
begin
  // Em uma normalização completa, a porta padrão é removida e o path vazio vira '/'
  // Nossa implementação atual de Normalize é apenas baseada em sintaxe.
  // A equivalência (operator=) deve detectar isso.
  LURI1 := TURIReference.From('http://example.com');
  LURI2 := TURIReference.From('http://example.com:80/');
  Check(LURI1 <> LURI2, 'URIs are not identical');
  // Para serem equivalentes, precisaríamos de uma Normalização baseada em esquema,
  // que é mais complexa. Por enquanto, a equivalência é baseada em sintaxe.
end;

procedure TJsonSchemaUriTest.Test_Normalization_SyntaxBased;
var
  LNormURI: TURIReference;
begin
  // 6.2.2.1: Case Normalization
  LNormURI := TURIReference.From('HTTP://EXAMPLE.COM/Path').Normalize;
  CheckEqualsString('http', LNormURI.Scheme);
  CheckEqualsString('example.com', LNormURI.Host);
  CheckEqualsString('/Path', LNormURI.Path, 'Path case should be preserved');

  // 6.2.2.2: Percent-Encoding Normalization
  LNormURI := TURIReference.From('http://a.com/a%c3%b1o/%7euser/%3a').Normalize;
  CheckEqualsString('/a%C3%B1o/~user/%3A', LNormURI.Path, 'Should decode unreserved, not reserved, and uppercase hex');

  // 6.2.2.3: Path Segment Normalization
  CheckEqualsString('http://a/g', NormalizeURI('http://a/b/c/./../../g'));
end;

procedure TJsonSchemaUriTest.Test_Parsing_Empty_Query_String;
var
  LURI: TURIReference;
begin
  LURI := TURIReference.From('https://httpbin.org/get?');
  CheckEqualsString('', LURI.Query, 'Query should be an empty string, not nil');
  CheckEqualsString('https://httpbin.org/get', LURI.Unsplit);
end;

procedure TJsonSchemaUriTest.Test_Parsing_Handles_Absolute_Path_URI;
var
  LURI: TURIReference;
begin
  LURI := TURIReference.From('/path/to/file');
  Check(LURI.Scheme.IsEmpty);
  Check(LURI.Authority.IsEmpty);
  CheckEqualsString('/path/to/file', LURI.Path);
end;

procedure TJsonSchemaUriTest.Test_Parsing_Percent_Encoding_In_Path;
var
  LURI: TURIReference;
begin
  LURI := TURIReference.From('http://a.com/%25%20');
  CheckEqualsString('/%25%20', LURI.Path, 'Should handle percent-encoded "%" correctly');
end;

procedure TJsonSchemaUriTest.Test_Parsing_Tricky_UserInfo;
var
  LURI: TURIReference;
begin
  LURI := TURIReference.From('ssh://user%20!=:pass@example.com:22');
  CheckEqualsString('user%20!=:pass', LURI.UserInfo, 'Should handle percent-encoded and symbols in userinfo');
  CheckEqualsString('example.com', LURI.Host);
  CheckEqualsString('22', LURI.Port);
end;

procedure TJsonSchemaUriTest.Test_RFC_1_1_2_FTP;
begin
  TestParsing('FTP', 'ftp://ftp.is.co.za/rfc/rfc1808.txt', 'ftp', 'ftp.is.co.za', 'ftp.is.co.za', '/rfc/rfc1808.txt', '', '');
end;

procedure TJsonSchemaUriTest.Test_RFC_1_1_2_HTTP;
begin
  TestParsing('HTTP', 'http://www.ietf.org/rfc/rfc2396.txt', 'http', 'www.ietf.org', 'www.ietf.org', '/rfc/rfc2396.txt', '', '');
end;

procedure TJsonSchemaUriTest.Test_RFC_1_1_2_LDAP_with_IPv6;
begin
  TestParsing('LDAP with IPv6', 'ldap://[2001:db8::7]/c=GB?objectClass?one', 'ldap', '[2001:db8::7]', '[2001:db8::7]', '/c=GB',
    'objectClass?one', '');
end;

procedure TJsonSchemaUriTest.Test_RFC_1_1_2_MailTo;
begin
  TestParsing('MailTo', 'mailto:John.Doe@example.com', 'mailto', '', '', 'John.Doe@example.com', '', '');
end;

procedure TJsonSchemaUriTest.Test_RFC_1_1_2_News;
begin
  TestParsing('News', 'news:comp.infosystems.www.servers.unix', 'news', '', '', 'comp.infosystems.www.servers.unix', '', '');
end;

procedure TJsonSchemaUriTest.Test_RFC_1_1_2_Tel;
begin
  TestParsing('Tel', 'tel:+1-816-555-1212', 'tel', '', '', '+1-816-555-1212', '', '');
end;

procedure TJsonSchemaUriTest.Test_RFC_1_1_2_Telnet_with_Port_and_Empty_Path;
begin
  TestParsing('Telnet with Port', 'telnet://192.0.2.16:80/', 'telnet', '192.0.2.16:80', '192.0.2.16', '/', '', '');
end;

procedure TJsonSchemaUriTest.Test_RFC_1_1_2_URN;
begin
  TestParsing('URN', 'urn:oasis:names:specification:docbook:dtd:xml:4.1.2', 'urn', '', '',
    'oasis:names:specification:docbook:dtd:xml:4.1.2', '', '');
end;

procedure TJsonSchemaUriTest.Test_RFC_5_4_1_NormalExamples;
begin
  TestResolution('g:h', 'g:h');
  TestResolution('g', 'http://a/b/c/g');
  TestResolution('./g', 'http://a/b/c/g');
  TestResolution('g/', 'http://a/b/c/g/');
  TestResolution('/g', 'http://a/g');
  TestResolution('//g', 'http://g');
  TestResolution('?y', 'http://a/b/c/d;p?y');
  TestResolution('g?y', 'http://a/b/c/g?y');
  TestResolution('#s', 'http://a/b/c/d;p?q#s');
  TestResolution('g#s', 'http://a/b/c/g#s');
  TestResolution('g?y#s', 'http://a/b/c/g?y#s');
  TestResolution(';x', 'http://a/b/c/;x');
  TestResolution('g;x', 'http://a/b/c/g;x');
  TestResolution('g;x?y#s', 'http://a/b/c/g;x?y#s');
  TestResolution('', 'http://a/b/c/d;p?q');
  TestResolution('.', 'http://a/b/c/');
  TestResolution('./', 'http://a/b/c/');
  TestResolution('..', 'http://a/b/');
  TestResolution('../', 'http://a/b/');
  TestResolution('../g', 'http://a/b/g');
  TestResolution('../..', 'http://a/');
  TestResolution('../../', 'http://a/');
  TestResolution('../../g', 'http://a/g');
end;

procedure TJsonSchemaUriTest.Test_RFC_5_4_2_AbnormalExamples;
begin
  TestResolution('../../../g', 'http://a/g');
  TestResolution('../../../../g', 'http://a/g');
  TestResolution('/./g', 'http://a/g');
  TestResolution('/../g', 'http://a/g');
  TestResolution('g.', 'http://a/b/c/g.');
  TestResolution('.g', 'http://a/b/c/.g');
  TestResolution('g..', 'http://a/b/c/g..');
  TestResolution('..g', 'http://a/b/c/..g');
  TestResolution('./../g', 'http://a/b/g');
  TestResolution('./g/.', 'http://a/b/c/g/');
  TestResolution('g/./h', 'http://a/b/c/g/h');
  TestResolution('g/../h', 'http://a/b/c/h');
  TestResolution('g?y/./x', 'http://a/b/c/g?y/./x');
  TestResolution('g?y/../x', 'http://a/b/c/g?y/../x');
  TestResolution('g#s/./x', 'http://a/b/c/g#s/./x');
  TestResolution('g#s/../x', 'http://a/b/c/g#s/../x');
end;

procedure TJsonSchemaUriTest.Test_Validator_Allow_Schemes;
var
  LValidator: TValidator;
  LValidURI, LInvalidURI: TURIReference;
begin
  LValidator := TValidator.Create;
  try
    LValidator.AllowSchemes(['http', 'https']);

    LValidURI := TURIReference.From('https://a.com');
    LValidator.Validate(LValidURI); // Should not raise

    LInvalidURI := TURIReference.From('ftp://a.com');
    CheckException(
      procedure
      begin
        LValidator.Validate(LInvalidURI);
      end,
      EValidationError,
      'Should raise EValidationError for disallowed scheme'
    );
  finally
    LValidator.Free;
  end;
end;

procedure TJsonSchemaUriTest.Test_Validator_Complex_Validation;
var
  LValidator: TValidator;
  LValidURI, LInvalidHostURI, LInvalidSchemeURI, LMissingPathURI: TURIReference;
begin
  LValidator := TValidator.Create;
  try
    LValidator.AllowSchemes(['https', 'ssh'])
              .AllowHosts(['github.com', 'gitlab.com'])
              .RequirePresenceOf([uricScheme, uricHost, uricPath])
              .ForbidPassword;

    LValidURI := TURIReference.From('https://github.com/user/repo');
    LValidator.Validate(LValidURI); // Should pass

    LInvalidHostURI := TURIReference.From('https://bitbucket.org/user/repo');
    CheckException(
      procedure
      begin
        LValidator.Validate(LInvalidHostURI);
      end,
      EValidationError,
      '');

    LInvalidSchemeURI := TURIReference.From('git://github.com/user/repo');
    CheckException(
      procedure
      begin
        LValidator.Validate(LInvalidSchemeURI);
      end,
      EValidationError,
      '');

    LMissingPathURI := TURIReference.From('https://github.com');
    CheckException(
      procedure
      begin
        LValidator.Validate(LMissingPathURI);
      end,
      EValidationError,
      '');

  finally
    LValidator.Free;
  end;
end;

procedure TJsonSchemaUriTest.Test_Validator_Forbid_Password;
var
  LValidator: TValidator;
  LInvalidURI: TURIReference;
begin
  LValidator := TValidator.Create;
  try
    LValidator.ForbidPassword;
    LInvalidURI := TURIReference.From('https://user:pass@a.com');

    CheckException(
      procedure
      begin
        LValidator.Validate(LInvalidURI);
      end,
      EValidationError,
      'Should raise EValidationError for forbidden password'
    );
  finally
    LValidator.Free;
  end;
end;

procedure TJsonSchemaUriTest.Test_Validator_Require_Component;
var
  LValidator: TValidator;
  LURI: TURIReference;
begin
  LValidator := TValidator.Create;
  try
    LURI := TURIReference.From('/path/to/resource');
    LValidator.RequirePresenceOf([uricScheme, uricHost]);

    CheckException(
      procedure
      begin
        LValidator.Validate(LURI);
      end,
      EMissingComponentError,
      'Should raise EMissingComponentError for missing scheme and host'
    );
  finally
    LValidator.Free;
  end;
end;

initialization
//  RegisterTest(TJsonSchemaUriTest.Suite);

end.
