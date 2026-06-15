program Web.TicketSales.Tests;

{$APPTYPE CONSOLE}

{***************************************************************************}
{                                                                           }
{           Web.TicketSales - Unit Tests                                    }
{                                                                           }
{           Tests for business logic and validation rules                   }
{                                                                           }
{***************************************************************************}

uses
  Dext.MM,
  Dext.Utils,
  System.SysUtils,
  Dext.Testing,
  // Source Units (Relative paths from Tests folder)
  TicketSales.Domain.Entities in '..\Domain\TicketSales.Domain.Entities.pas',
  TicketSales.Domain.Enums in '..\Domain\TicketSales.Domain.Enums.pas',
  TicketSales.Domain.Models in '..\Domain\TicketSales.Domain.Models.pas',
  TicketSales.Data.Context in '..\Data\TicketSales.Data.Context.pas',
  TicketSales.Services in '..\Services\TicketSales.Services.pas',
  // Test Units
  TicketSales.Tests.Services in 'TicketSales.Tests.Services.pas',
  TicketSales.Tests.Validation in 'TicketSales.Tests.Validation.pas',
  TicketSales.Tests.Entities in 'TicketSales.Tests.Entities.pas';

begin
  SetConsoleCharSet;
  try
    SafeWriteLn('');
    SafeWriteLn('========================================');
    SafeWriteLn('   🧪 Ticket Sales Unit Tests');
    SafeWriteLn('========================================');
    SafeWriteLn('');

    TTest.SetExitCode(
      TTest.Configure
        .Verbose
        .RegisterFixtures([
          TEventEntityTests,
          TCustomerEntityTests,
          TOrderEntityTests,
          TTicketEntityTests,
          TEventServiceTests,
          TOrderServiceTests,
          TTicketValidationTests
        ])
        .Run
    );
  except
    on E: Exception do
    begin
      SafeWriteLn('❌ Test Error: ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
  ConsolePause;
end.
