# Magic Binding

> Declarative two-way data binding for VCL controls.

---

## Overview

Magic Binding eliminates boilerplate code for syncing UI controls with ViewModels. Instead of writing manual event handlers, you use attributes to declare bindings.

---

## Binding Attributes

### `[BindEdit]` - Edit Controls

Binds a `TEdit` to a ViewModel property:

```pascal
type
  TCustomerEditFrame = class(TFrame)
  private
    FViewModel: TCustomerViewModel;
  published
    [BindEdit('Name')]
    NameEdit: TEdit;
    
    [BindEdit('Email')]
    EmailEdit: TEdit;
    
    [BindEdit('Phone')]
    PhoneEdit: TEdit;
  end;
```

The binding engine automatically:
- Reads the initial value from `FViewModel.Name`
- Updates `FViewModel.Name` when the user types
- Refreshes the edit when `FViewModel.Name` changes

### `[BindText]` - Labels

Binds a `TLabel` (one-way, read-only):

```pascal
[BindText('ErrorMessage')]
ErrorLabel: TLabel;

[BindText('Errors.Text')]  // Nested property
ErrorsLabel: TLabel;
```

### `[BindCheckBox]` - CheckBoxes

```pascal
[BindCheckBox('Active')]
ActiveCheckBox: TCheckBox;
```

---

## Event Attributes

### `[OnClickMsg]` - Message Dispatch

Instead of writing `OnClick` handlers, dispatch messages:

```pascal
type
  // Define messages
  TSaveMsg = class end;
  TCancelMsg = class end;
  
  TCustomerEditFrame = class(TFrame)
  published
    [OnClickMsg(TSaveMsg)]
    SaveButton: TButton;
    
    [OnClickMsg(TCancelMsg)]
    CancelButton: TButton;
  end;
```

The binding engine sends messages to a registered handler (typically your Controller).

---

## Setting Up Binding

### 1. Create the Binding Engine

```pascal
uses
  Dext.UI.Binding;

procedure TCustomerEditFrame.AfterConstruction;
begin
  inherited;
  FBindingEngine := TBindingEngine.Create(Self, FViewModel);
end;
```

### 2. Refresh Bindings

When the ViewModel changes externally:

```pascal
procedure TCustomerEditFrame.LoadCustomer(Customer: TCustomer);
begin
  FViewModel.Load(Customer);
  FBindingEngine.Refresh;
end;
```

---

## Nested Properties

Bind to nested object properties using dot notation:

```pascal
// ViewModel has: Customer.Address.City
[BindEdit('Customer.Address.City')]
CityEdit: TEdit;

// ViewModel has: Errors: TStrings
[BindText('Errors.Text')]  // Calls Errors.Text property
ErrorsLabel: TLabel;
```

---

## Custom Converters

For complex type conversions:

```pascal
type
  TCurrencyConverter = class(TInterfacedObject, IValueConverter)
    function Convert(const Value: TValue): TValue;
    function ConvertBack(const Value: TValue): TValue;
  end;

// Usage
[BindEdit('Price', TCurrencyConverter)]
PriceEdit: TEdit;
```

---

## Validation Integration

Combine with ViewModel validation:

```pascal
procedure TCustomerEditFrame.Save;
begin
  if not FViewModel.Validate then
  begin
    // Errors are automatically bound to ErrorsLabel
    FBindingEngine.Refresh;
    Exit;
  end;
  
  // Proceed with save
  FController.SaveCustomer(FViewModel.GetEntity);
end;
```

---

## Best Practices

1. **One ViewModel per Frame** - Keep bindings simple
2. **Use `published` section** - Binding engine uses RTTI
3. **Refresh after external changes** - Call `FBindingEngine.Refresh`
4. **Avoid mixing manual handlers** - Let the binding engine handle everything

---

## See Also

- [Navigator Framework](navigator.md) - View navigation
- [MVVM Patterns](mvvm-patterns.md) - Architecture guide
