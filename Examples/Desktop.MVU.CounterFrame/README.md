# 🎯 Desktop.MVU.CounterFrame

Exemplo MVU usando **TFrame** desenhado no IDE do Delphi, demonstrando como combinar o Form Designer com a arquitetura MVU.

## 📚 Diferenças do Exemplo Anterior

| Aspecto | Desktop.MVU.Counter | Desktop.MVU.CounterFrame |
|---------|---------------------|--------------------------|
| UI | Criada em código | **Desenhada no IDE (TFrame)** |
| Model | Record no mesmo arquivo | **Arquivo separado** |
| Messages | Enum | **Classes herdando de TMessage** |
| Update | Classe com método static | **Arquivo separado** |
| Estrutura | Monolítico | **Modular (Model/Messages/Update/View)** |

## 🏗️ Estrutura do Projeto

```
Desktop.MVU.CounterFrame/
├── DesktopMVUCounterFrame.dpr     # Projeto principal
├── DesktopMVUCounterFrame.dproj   # Configuração IDE
├── Counter.Model.pas              # TCounterModel (estado)
├── Counter.Messages.pas           # TIncrementMsg, TDecrementMsg, etc.
├── Counter.Update.pas             # TCounterUpdate (lógica pura)
├── Counter.View.pas               # TCounterViewFrame (TFrame)
├── Counter.View.dfm               # Layout visual do Frame
├── Counter.Main.pas               # TMainForm (orquestrador)
├── Counter.Main.dfm               # Layout do Form
└── README.md                      # Este arquivo
```

## 📦 Componentes

### `Counter.Model.pas` - Estado
```pascal
TCounterModel = record
  Count: Integer;
  Step: Integer;
  History: string;
  
  class function Init: TCounterModel; static;
  function WithCount(const NewCount: Integer): TCounterModel;
  // ... outros métodos With
end;
```

### `Counter.Messages.pas` - Ações
```pascal
TCounterMsg = class(TMessage)
end;

TIncrementMsg = class(TCounterMsg)
end;

TSetStepMsg = class(TCounterMsg)
  property Step: Integer read FStep;
end;
```

### `Counter.Update.pas` - Lógica
```pascal
class function TCounterUpdate.Update(
  const Model: TCounterModel; 
  const Msg: TCounterMsg): TCounterModel;
```

### `Counter.View.pas` - UI (TFrame)
Frame desenhado no IDE do Delphi com todos os controles visuais.

### `Counter.Main.pas` - Orquestrador
```pascal
procedure TMainForm.ProcessMessage(const Msg: TCounterMsg);
begin
  FModel := TCounterUpdate.Update(FModel, Msg);
  Render;
end;
```

## ▶️ Como Executar

1. Abra `DesktopMVUCounterFrame.dproj` no Delphi
2. Compile (Ctrl+F9)
3. Execute (F9)

## 🔮 Próximo Passo: Binding Automático

Este exemplo ainda usa wiring manual:
```pascal
FFrame.IncrementButton.OnClick := procedure(Sender: TObject)
  begin
    DispatchMessage(TIncrementMsg.Create);
  end;
```

O objetivo é evoluir para **binding declarativo via atributos**:
```pascal
[OnClickMsg(TIncrementMsg)]
IncrementButton: TButton;

[BindText('Count')]
CountLabel: TLabel;
```

Onde o `TMVUBinder` fará o wiring automaticamente via RTTI!

## 📖 Aprendizados

1. **TFrame no IDE** - Layout visual, sem código de criação
2. **Mensagens como Classes** - Mais flexíveis que enum, podem carregar dados
3. **Separação de Responsabilidades** - Model, Messages, Update, View em arquivos separados
4. **Pattern Matching via `is`** - `if Msg is TIncrementMsg then ...`

---

*Dext Framework - MVU for Delphi*
