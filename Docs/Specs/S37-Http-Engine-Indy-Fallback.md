# S37: HTTP Client Engine Abstraction & Indy Fallback

- **Status**: ✅ Completed
- **Author**: Cesar Romero & Antigravity
- **Created**: 2026-06-17
- **Last Updated**: 2026-06-17

## 1. Goal
Abstract the HTTP outbound layer in `Dext.Net.Core` (which currently depends directly on `System.Net.HttpClient.THTTPClient` introduced in Delphi XE8) to enable compilation and functionality in legacy Delphi versions (specifically Delphi XE2 to XE7) using Indy (`IdHTTP.TIdHTTP`) as a fallback implementation.

---

## 2. Architecture

We will introduce a decoupled interface structure for HTTP requests and engines:

### 2.1 The Unified Response Interface
Instead of relying on `System.Net.URLClient.TNetHeaders` and `System.Net.HttpClient.IHTTPResponse`, we will define native mappings or alias types in Dext to avoid importing `System.Net.*` in legacy environments.

```delphi
type
  TDextNetHeader = record
    Name: string;
    Value: string;
    constructor Create(const AName, AValue: string);
  end;
  TDextNetHeaders = TArray<TDextNetHeader>;
```

### 2.2 The HTTP Engine Interface
```delphi
type
  IDextHttpEngine = interface
    ['{B9D8A7C6-B5E4-4D3C-2B1A-0F9E8D7C6B5A}']
    procedure SetConnectionTimeout(AMilliseconds: Integer);
    procedure SetSendTimeout(AMilliseconds: Integer);
    procedure SetResponseTimeout(AMilliseconds: Integer);
    function Execute(const AMethod, AUrl: string; const ABody: TStream; const AHeaders: TDextNetHeaders): IRestResponse;
  end;
```

---

## 3. Fallback Mechanism (Indy)

The factory method `CreateHttpEngine` will instantiate the appropriate engine based on compilation directives:

```delphi
function CreateHttpEngine: IDextHttpEngine;
begin
  {$IF defined(DEXT_FORCE_INDY) or (CompilerVersion < 29.0)} // 29.0 is XE8
  Result := TDextIndyHttpEngine.Create;
  {$ELSE}
  Result := TDextNetHttpEngine.Create;
  {$ENDIF}
end;
```

### 3.1 Indy Engine Implementation (`TDextIndyHttpEngine`)
Uses `IdHTTP.TIdHTTP` internally:
* Map standard verbs (`GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `HEAD`, `OPTIONS`) to Indy methods.
* Configure OpenSSL handler (`TIdSSLIOHandlerSocketOpenSSL`) if the URL starts with `https://`.
* Safely map stream uploads and response stream copying.
* Map response headers from `IdHTTP.Response.RawHeaders`.

---

## 4. Proposed Changes

### [MODIFY] [Dext.Net.RestClient.pas](file:///C:/dev/Dext/DextRepository/Sources/Net/Dext.Net.RestClient.pas)
* Replace usage of `TNetHeaders` / `IHTTPResponse` with unified Dext equivalents.
* Delegate execution to `IDextHttpEngine` acquired from the pool.

### [MODIFY] [Dext.Net.ConnectionPool.pas](file:///C:/dev/Dext/DextRepository/Sources/Net/Dext.Net.ConnectionPool.pas)
* Change connection pool to hold `IDextHttpEngine` references instead of `THttpClient`.

### [MODIFY] [Dext.Net.Authentication.pas](file:///C:/dev/Dext/DextRepository/Sources/Net/Dext.Net.Authentication.pas)
* Refactor `TOAuth2ClientCredentialsProvider.RefreshToken` to use `CreateHttpEngine` instead of instantiating `THTTPClient` directly.

---

## 5. Verification Plan

### Automated Tests
* Run unit tests under modern Delphi to ensure no regressions:
  ```powershell
  powershell -ExecutionPolicy Bypass -File Scripts/run_tests.ps1
  ```
* Run the sync script to generate legacy packages:
  ```powershell
  powershell -ExecutionPolicy Bypass -File Scripts/sync-legacy-packages.ps1
  ```
