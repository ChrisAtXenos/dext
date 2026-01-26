# Magic Binding

> Binding bidirecional declarativo para controles VCL.

---

## Visão Geral

O Magic Binding elimina código boilerplate para sincronizar controles de UI com ViewModels. Ao invés de escrever event handlers manualmente, você usa atributos para declarar bindings.

---

## Atributos de Binding

### `[BindEdit]` - Controles Edit

Vincula um `TEdit` a uma propriedade do ViewModel:

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

O motor de binding automaticamente:
- Lê o valor inicial de `FViewModel.Name`
- Atualiza `FViewModel.Name` quando o usuário digita
- Atualiza o edit quando `FViewModel.Name` muda

### `[BindText]` - Labels

Vincula um `TLabel` (unidirecional, somente leitura):

```pascal
[BindText('ErrorMessage')]
ErrorLabel: TLabel;

[BindText('Errors.Text')]  // Propriedade aninhada
ErrorsLabel: TLabel;
```

### `[BindCheckBox]` - CheckBoxes

```pascal
[BindCheckBox('Active')]
ActiveCheckBox: TCheckBox;
```

---

## Atributos de Evento

### `[OnClickMsg]` - Despacho de Mensagens

Ao invés de escrever handlers `OnClick`, despache mensagens:

```pascal
type
  // Defina as mensagens
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

O motor de binding envia mensagens para um handler registrado (tipicamente seu Controller).

---

## Configurando o Binding

### 1. Criar o Motor de Binding

```pascal
uses
  Dext.UI.Binding;

procedure TCustomerEditFrame.AfterConstruction;
begin
  inherited;
  FBindingEngine := TBindingEngine.Create(Self, FViewModel);
end;
```

### 2. Atualizar Bindings

Quando o ViewModel muda externamente:

```pascal
procedure TCustomerEditFrame.LoadCustomer(Customer: TCustomer);
begin
  FViewModel.Load(Customer);
  FBindingEngine.Refresh;
end;
```

---

## Propriedades Aninhadas

Vincule a propriedades de objetos aninhados usando notação de ponto:

```pascal
// ViewModel tem: Customer.Address.City
[BindEdit('Customer.Address.City')]
CityEdit: TEdit;

// ViewModel tem: Errors: TStrings
[BindText('Errors.Text')]  // Chama propriedade Errors.Text
ErrorsLabel: TLabel;
```

---

## Conversores Customizados

Para conversões de tipo complexas:

```pascal
type
  TCurrencyConverter = class(TInterfacedObject, IValueConverter)
    function Convert(const Value: TValue): TValue;
    function ConvertBack(const Value: TValue): TValue;
  end;

// Uso
[BindEdit('Price', TCurrencyConverter)]
PriceEdit: TEdit;
```

---

## Integração com Validação

Combine com validação do ViewModel:

```pascal
procedure TCustomerEditFrame.Save;
begin
  if not FViewModel.Validate then
  begin
    // Erros são automaticamente vinculados ao ErrorsLabel
    FBindingEngine.Refresh;
    Exit;
  end;
  
  // Prosseguir com save
  FController.SaveCustomer(FViewModel.GetEntity);
end;
```

---

## Boas Práticas

1. **Um ViewModel por Frame** - Mantenha bindings simples
2. **Use seção `published`** - Motor de binding usa RTTI
3. **Refresh após mudanças externas** - Chame `FBindingEngine.Refresh`
4. **Evite misturar handlers manuais** - Deixe o motor de binding controlar tudo

---

## Veja Também

- [Navigator Framework](navigator.md) - Navegação de views
- [Padrões MVVM](mvvm-patterns.md) - Guia de arquitetura
