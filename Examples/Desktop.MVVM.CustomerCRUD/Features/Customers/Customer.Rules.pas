{***************************************************************************}
{                                                                           }
{           Dext Framework - Example                                        }
{                                                                           }
{           Customer Business Rules                                         }
{                                                                           }
{***************************************************************************}
unit Customer.Rules;

interface

uses
  System.Generics.Collections,
  System.RegularExpressions,
  System.SysUtils,
  Dext.Collections,
  Customer.Entity;

type
  /// <summary>
  /// Business validation rules for Customer entities.
  /// Provides static validation methods for customer data.
  /// </summary>
  TCustomerRules = class
  public
    const
      MIN_NAME_LENGTH = 3;
      MAX_NAME_LENGTH = 100;
      MIN_DOCUMENT_LENGTH = 5;
      MAX_DOCUMENT_LENGTH = 20;
      
    class function ValidateName(const Name: string; out ErrorMsg: string): Boolean;
    class function ValidateEmail(const Email: string; out ErrorMsg: string): Boolean;
    class function ValidatePhone(const Phone: string; out ErrorMsg: string): Boolean;
    class function ValidateDocument(const Document: string; out ErrorMsg: string): Boolean;
    
    /// <summary>
    /// Checks if email is unique among customers (excludes current customer for updates)
    /// </summary>
    class function IsEmailUnique(const Email: string; ExcludeId: Integer; 
      const Customers: IList<TCustomer>): Boolean;
      
    /// <summary>
    /// Checks if document is unique among customers (excludes current customer for updates)
    /// </summary>
    class function IsDocumentUnique(const Document: string; ExcludeId: Integer;
      const Customers: IList<TCustomer>): Boolean;
      
    /// <summary>
    /// Validates all customer fields at once
    /// </summary>
    class function ValidateAll(const Customer: TCustomer; 
      out Errors: TArray<string>): Boolean;
  end;

implementation

{ TCustomerRules }

class function TCustomerRules.ValidateName(const Name: string; out ErrorMsg: string): Boolean;
var
  TrimmedName: string;
begin
  ErrorMsg := '';
  TrimmedName := Trim(Name);
  
  if TrimmedName.IsEmpty then
  begin
    ErrorMsg := 'Name is required';
    Exit(False);
  end;
  
  if Length(TrimmedName) < MIN_NAME_LENGTH then
  begin
    ErrorMsg := Format('Name must be at least %d characters', [MIN_NAME_LENGTH]);
    Exit(False);
  end;
  
  if Length(TrimmedName) > MAX_NAME_LENGTH then
  begin
    ErrorMsg := Format('Name cannot exceed %d characters', [MAX_NAME_LENGTH]);
    Exit(False);
  end;
  
  Result := True;
end;

class function TCustomerRules.ValidateEmail(const Email: string; out ErrorMsg: string): Boolean;
const
  EMAIL_PATTERN = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
var
  TrimmedEmail: string;
begin
  ErrorMsg := '';
  TrimmedEmail := Trim(Email);
  
  if TrimmedEmail.IsEmpty then
  begin
    ErrorMsg := 'Email is required';
    Exit(False);
  end;
  
  if not TRegEx.IsMatch(TrimmedEmail, EMAIL_PATTERN) then
  begin
    ErrorMsg := 'Invalid email format';
    Exit(False);
  end;
  
  Result := True;
end;

class function TCustomerRules.ValidatePhone(const Phone: string; out ErrorMsg: string): Boolean;
const
  // Matches: (XX) XXXXX-XXXX, XX XXXXX-XXXX, XXXXXXXXXXX, +XX XX XXXXX-XXXX
  PHONE_PATTERN = '^[\+]?[(]?[0-9]{1,3}[)]?[-\s\.]?[0-9]{1,5}[-\s\.]?[0-9]{4,6}[-\s\.]?[0-9]{0,4}$';
var
  TrimmedPhone: string;
begin
  ErrorMsg := '';
  TrimmedPhone := Trim(Phone);
  
  // Phone is optional
  if TrimmedPhone.IsEmpty then
    Exit(True);
  
  if not TRegEx.IsMatch(TrimmedPhone, PHONE_PATTERN) then
  begin
    ErrorMsg := 'Invalid phone format';
    Exit(False);
  end;
  
  Result := True;
end;

class function TCustomerRules.ValidateDocument(const Document: string; out ErrorMsg: string): Boolean;
var
  TrimmedDoc: string;
begin
  ErrorMsg := '';
  TrimmedDoc := Trim(Document);
  
  // Document is optional
  if TrimmedDoc.IsEmpty then
    Exit(True);
  
  if Length(TrimmedDoc) < MIN_DOCUMENT_LENGTH then
  begin
    ErrorMsg := Format('Document must be at least %d characters', [MIN_DOCUMENT_LENGTH]);
    Exit(False);
  end;
  
  if Length(TrimmedDoc) > MAX_DOCUMENT_LENGTH then
  begin
    ErrorMsg := Format('Document cannot exceed %d characters', [MAX_DOCUMENT_LENGTH]);
    Exit(False);
  end;
  
  Result := True;
end;

class function TCustomerRules.IsEmailUnique(const Email: string; ExcludeId: Integer;
  const Customers: IList<TCustomer>): Boolean;
var
  Customer: TCustomer;
  LowerEmail: string;
begin
  Result := True;
  if (Customers = nil) or Trim(Email).IsEmpty then
    Exit;
    
  LowerEmail := LowerCase(Trim(Email));
  
  for Customer in Customers do
  begin
    if (Customer.Id <> ExcludeId) and 
       (LowerCase(Trim(Customer.Email.Value)) = LowerEmail) then
    begin
      Exit(False);
    end;
  end;
end;

class function TCustomerRules.IsDocumentUnique(const Document: string; ExcludeId: Integer;
  const Customers: IList<TCustomer>): Boolean;
var
  Customer: TCustomer;
  NormalizedDoc: string;
begin
  Result := True;
  if (Customers = nil) or Trim(Document).IsEmpty then
    Exit;
    
  NormalizedDoc := Trim(Document);
  
  for Customer in Customers do
  begin
    if (Customer.Id <> ExcludeId) and 
       (Trim(Customer.Document.Value) = NormalizedDoc) then
    begin
      Exit(False);
    end;
  end;
end;

class function TCustomerRules.ValidateAll(const Customer: TCustomer;
  out Errors: TArray<string>): Boolean;
var
  ErrorList: TList<string>;
  ErrorMsg: string;
begin
  ErrorList := TList<string>.Create;
  try
    if not ValidateName(Customer.Name, ErrorMsg) then
      ErrorList.Add(ErrorMsg);
      
    if not ValidateEmail(Customer.Email, ErrorMsg) then
      ErrorList.Add(ErrorMsg);
      
    if not ValidatePhone(Customer.Phone, ErrorMsg) then
      ErrorList.Add(ErrorMsg);
      
    if not ValidateDocument(Customer.Document, ErrorMsg) then
      ErrorList.Add(ErrorMsg);
    
    Errors := ErrorList.ToArray;
    Result := ErrorList.Count = 0;
  finally
    ErrorList.Free;
  end;
end;

end.
