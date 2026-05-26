object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Dext - Active Architecture'
  ClientHeight = 561
  ClientWidth = 849
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object OrderGrid: TDBGrid
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 843
    Height = 264
    Align = alClient
    DataSource = OrderDataSource
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object OrderDetailsGrid: TDBGrid
    AlignWithMargins = True
    Left = 3
    Top = 273
    Width = 843
    Height = 126
    Align = alBottom
    DataSource = OrderDetailsDataSource
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object LogsMemo: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 405
    Width = 843
    Height = 153
    Align = alBottom
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object SqliteDemoConnection: TFDConnection
    Params.Strings = (
      'ConnectionDef=SQLite_Demo')
    Connected = True
    LoginPrompt = False
    Left = 73
    Top = 70
  end
  object EntityDataProvider: TEntityDataProvider
    DatabaseConnection = SqliteDemoConnection
    ModelUnits.Strings = (
      
        'C:\dev\Dext\DextRepository\Examples\09-ActiveArchitecture\Deskto' +
        'p.BasicActiveArchitecture.Demo\Infra\Dext.ActiveArchitecture.Sta' +
        'rtup.pas'
      
        'C:\dev\Dext\DextRepository\Examples\09-ActiveArchitecture\Deskto' +
        'p.BasicActiveArchitecture.Demo\Presentation\Dext.ActiveArchitect' +
        'ure.Main.Form.pas'
      
        'C:\dev\Dext\DextRepository\Examples\09-ActiveArchitecture\Deskto' +
        'p.BasicActiveArchitecture.Demo\Domain\Dext.ActiveArchitecture.En' +
        'tities.pas'
      
        'C:\dev\Dext\DextRepository\Examples\09-ActiveArchitecture\Deskto' +
        'p.BasicActiveArchitecture.Demo\Domain\Dext.ActiveArchitecture.Sp' +
        'ecifications.pas'
      
        'C:\dev\Dext\DextRepository\Examples\09-ActiveArchitecture\Deskto' +
        'p.BasicActiveArchitecture.Demo\Infra\Dext.Logging.Sinks.VCL.pas'
      
        'C:\dev\Dext\DextRepository\Examples\09-ActiveArchitecture\Deskto' +
        'p.BasicActiveArchitecture.Demo\Domain\Dext.ActiveArchitecture.Do' +
        'main.pas'
      
        'C:\dev\Dext\DextRepository\Examples\09-ActiveArchitecture\Deskto' +
        'p.BasicActiveArchitecture.Demo\Infra\Dext.ActiveArchitecture.Ser' +
        'vices.pas'
      
        'C:\dev\Dext\DextRepository\Examples\09-ActiveArchitecture\Deskto' +
        'p.BasicActiveArchitecture.Demo\Presentation\Dext.ActiveArchitect' +
        'ure.ViewModels.pas')
    Dialect = ddSQLite
    EntitiesMetadata = <
      item
        EntityClassName = 'TOrders'
        DisplayName = ''
        TableName = 'Orders'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'OrderId'
            MemberType = 'IntType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            DisplayLabel = 'Pedido'
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'CustomerId'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 5
            Precision = 0
            Scale = 0
            DisplayLabel = 'Cliente'
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'EmployeeId'
            MemberType = 'IntType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            DisplayLabel = 'Usu'#225'rio'
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'OrderDate'
            MemberType = 'DateTimeType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'RequiredDate'
            MemberType = 'DateTimeType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = False
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ShippedDate'
            MemberType = 'DateTimeType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ShipVia'
            MemberType = 'IntType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Freight'
            MemberType = 'CurrencyType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ShipName'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 40
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ShipAddress'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 60
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ShipCity'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ShipRegion'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ShipPostalCode'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 10
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ShipCountry'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ShipViaNavigation'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end
          item
            Name = 'Customer'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end
          item
            Name = 'Employee'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end>
      end
      item
        EntityClassName = 'TOrderDetails'
        DisplayName = ''
        TableName = 'Order Details'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'OrderId'
            MemberType = 'IntType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            DisplayLabel = 'Pedido'
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ProductId'
            MemberType = 'IntType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            DisplayLabel = 'Produto'
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'UnitPrice'
            MemberType = 'CurrencyType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            DisplayLabel = 'Pre'#231'o Unit'#225'rio'
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Quantity'
            MemberType = 'IntType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            DisplayLabel = 'Quantidade'
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Discount'
            MemberType = 'FloatType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            DisplayLabel = 'Desconto'
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end>
      end
      item
        EntityClassName = 'TSuppliers'
        DisplayName = ''
        TableName = 'Suppliers'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'SupplierId'
            MemberType = 'IntType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'CompanyName'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 40
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ContactName'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 30
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ContactTitle'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 30
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Address'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 60
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'City'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Region'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'PostalCode'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 10
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Country'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Phone'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 24
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Fax'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 24
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'HomePage'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end>
      end
      item
        EntityClassName = 'TTerritories'
        DisplayName = ''
        TableName = 'Territories'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'TerritoryId'
            MemberType = 'StringType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 20
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'TerritoryDescription'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 50
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'RegionId'
            MemberType = 'IntType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Region'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end>
      end
      item
        EntityClassName = 'TCustomerDemographics'
        DisplayName = ''
        TableName = 'CustomerDemographics'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'CustomerTypeId'
            MemberType = 'StringType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 10
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'CustomerDesc'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end>
      end
      item
        EntityClassName = 'TCustomerCustomerDemo'
        DisplayName = ''
        TableName = 'CustomerCustomerDemo'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'CustomerId'
            MemberType = 'StringType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 5
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'CustomerTypeId'
            MemberType = 'StringType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 10
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Customer'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end
          item
            Name = 'CustomerType'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end>
      end
      item
        EntityClassName = 'TCategories'
        DisplayName = ''
        TableName = 'Categories'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'CategoryId'
            MemberType = 'IntType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'CategoryName'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Description'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Picture'
            MemberType = 'TBytes'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end>
      end
      item
        EntityClassName = 'TProducts'
        DisplayName = ''
        TableName = 'Products'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'ProductId'
            MemberType = 'IntType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ProductName'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 40
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'SupplierId'
            MemberType = 'IntType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'CategoryId'
            MemberType = 'IntType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'QuantityPerUnit'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 20
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'UnitPrice'
            MemberType = 'CurrencyType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'UnitsInStock'
            MemberType = 'IntType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'UnitsOnOrder'
            MemberType = 'IntType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ReorderLevel'
            MemberType = 'IntType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Discontinued'
            MemberType = 'BoolType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Supplier'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end
          item
            Name = 'Category'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end>
      end
      item
        EntityClassName = 'TEmployeeTerritories'
        DisplayName = ''
        TableName = 'EmployeeTerritories'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'EmployeeId'
            MemberType = 'IntType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'TerritoryId'
            MemberType = 'StringType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 20
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Employee'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end
          item
            Name = 'Territory'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end>
      end
      item
        EntityClassName = 'TCustomers'
        DisplayName = ''
        TableName = 'Customers'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'CustomerId'
            MemberType = 'StringType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 5
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'CompanyName'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 40
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ContactName'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 30
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ContactTitle'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 30
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Address'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 60
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'City'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Region'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'PostalCode'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 10
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Country'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Phone'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 24
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Fax'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 24
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end>
      end
      item
        EntityClassName = 'TShippers'
        DisplayName = ''
        TableName = 'Shippers'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'ShipperId'
            MemberType = 'IntType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'CompanyName'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 40
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Phone'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 24
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end>
      end
      item
        EntityClassName = 'TEmployees'
        DisplayName = ''
        TableName = 'Employees'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'EmployeeId'
            MemberType = 'IntType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'LastName'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 20
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'FirstName'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 10
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Title'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 30
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'TitleOfCourtesy'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 25
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'BirthDate'
            MemberType = 'DateTimeType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'HireDate'
            MemberType = 'DateTimeType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Address'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 60
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'City'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Region'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'PostalCode'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 10
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Country'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 15
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'HomePhone'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 24
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Extension'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 4
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Photo'
            MemberType = 'TBytes'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'Notes'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ReportsTo'
            MemberType = 'IntType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'PhotoPath'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 255
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'ReportsToNavigation'
            MemberType = 'Lazy'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
            RelationType = 'BelongsTo'
          end>
      end
      item
        EntityClassName = 'TRegion'
        DisplayName = ''
        TableName = 'Region'
        EntityUnitName = 'Dext.ActiveArchitecture.Entities'
        Members = <
          item
            Name = 'RegionId'
            MemberType = 'IntType'
            IsPrimaryKey = True
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 0
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end
          item
            Name = 'RegionDescription'
            MemberType = 'StringType'
            IsPrimaryKey = False
            IsRequired = False
            IsAutoInc = False
            IsReadOnly = False
            MaxLength = 50
            Precision = 0
            Scale = 0
            Alignment = taLeftJustify
            DisplayWidth = 0
            Visible = True
            IsCurrency = False
            HasJoin = False
            HasInclude = False
          end>
      end>
    Left = 72
    Top = 144
  end
  object OrderEntityDataSet: TEntityDataSet
    DataProvider = EntityDataProvider
    EntityClassName = 'TOrders'
    FieldDefs = <
      item
        Name = 'OrderId'
        DataType = ftInteger
      end
      item
        Name = 'CustomerId'
        DataType = ftString
        Size = 5
      end
      item
        Name = 'EmployeeId'
        DataType = ftInteger
      end
      item
        Name = 'OrderDate'
        DataType = ftDateTime
      end
      item
        Name = 'RequiredDate'
        DataType = ftDateTime
      end
      item
        Name = 'ShippedDate'
        DataType = ftDateTime
      end
      item
        Name = 'ShipVia'
        DataType = ftInteger
      end
      item
        Name = 'Freight'
        DataType = ftCurrency
      end
      item
        Name = 'ShipName'
        DataType = ftString
        Size = 40
      end
      item
        Name = 'ShipAddress'
        DataType = ftString
        Size = 60
      end
      item
        Name = 'ShipCity'
        DataType = ftString
        Size = 15
      end
      item
        Name = 'ShipRegion'
        DataType = ftString
        Size = 15
      end
      item
        Name = 'ShipPostalCode'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'ShipCountry'
        DataType = ftString
        Size = 15
      end>
    TableName = 'Orders'
    Left = 528
    Top = 152
    object OrderEntityDataSetOrderId: TIntegerField
      DisplayLabel = 'Pedido'
      FieldName = 'OrderId'
    end
    object OrderEntityDataSetCustomerId: TStringField
      DisplayLabel = 'Cliente'
      FieldName = 'CustomerId'
      Size = 5
    end
    object OrderEntityDataSetEmployeeId: TIntegerField
      DisplayLabel = 'Usu'#225'rio'
      FieldName = 'EmployeeId'
    end
    object OrderEntityDataSetOrderDate: TDateTimeField
      FieldName = 'OrderDate'
    end
    object OrderEntityDataSetRequiredDate: TDateTimeField
      FieldName = 'RequiredDate'
      Visible = False
    end
    object OrderEntityDataSetShippedDate: TDateTimeField
      FieldName = 'ShippedDate'
    end
    object OrderEntityDataSetShipVia: TIntegerField
      FieldName = 'ShipVia'
    end
    object OrderEntityDataSetFreight: TCurrencyField
      FieldName = 'Freight'
    end
    object OrderEntityDataSetShipName: TStringField
      FieldName = 'ShipName'
      Size = 40
    end
    object OrderEntityDataSetShipAddress: TStringField
      FieldName = 'ShipAddress'
      Size = 60
    end
    object OrderEntityDataSetShipCity: TStringField
      FieldName = 'ShipCity'
      Size = 15
    end
    object OrderEntityDataSetShipRegion: TStringField
      FieldName = 'ShipRegion'
      Size = 15
    end
    object OrderEntityDataSetShipPostalCode: TStringField
      FieldName = 'ShipPostalCode'
      Size = 10
    end
    object OrderEntityDataSetShipCountry: TStringField
      FieldName = 'ShipCountry'
      Size = 15
    end
  end
  object OrderDetailsEntityDataSet: TEntityDataSet
    DataProvider = EntityDataProvider
    EntityClassName = 'TOrderDetails'
    FieldDefs = <
      item
        Name = 'OrderId'
        DataType = ftInteger
      end
      item
        Name = 'ProductId'
        DataType = ftInteger
      end
      item
        Name = 'UnitPrice'
        DataType = ftCurrency
      end
      item
        Name = 'Quantity'
        DataType = ftInteger
      end
      item
        Name = 'Discount'
        DataType = ftFloat
      end>
    Filtered = True
    IndexFieldNames = 'OrderId'
    MasterFields = 'OrderId'
    MasterSource = OrderDataSource
    TableName = 'Order Details'
    Left = 512
    Top = 336
    object OrderDetailsEntityDataSetOrderId: TIntegerField
      DisplayLabel = 'Pedido'
      FieldName = 'OrderId'
    end
    object OrderDetailsEntityDataSetProductId: TIntegerField
      DisplayLabel = 'Produto'
      FieldName = 'ProductId'
    end
    object OrderDetailsEntityDataSetUnitPrice: TCurrencyField
      DisplayLabel = 'Pre'#231'o Unit'#225'rio'
      FieldName = 'UnitPrice'
    end
    object OrderDetailsEntityDataSetQuantity: TIntegerField
      DisplayLabel = 'Quantidade'
      FieldName = 'Quantity'
    end
    object OrderDetailsEntityDataSetDiscount: TFloatField
      DisplayLabel = 'Desconto'
      FieldName = 'Discount'
    end
  end
  object OrderDataSource: TDataSource
    DataSet = OrderEntityDataSet
    Left = 680
    Top = 152
  end
  object OrderDetailsDataSource: TDataSource
    DataSet = OrderDetailsEntityDataSet
    Left = 680
    Top = 336
  end
end
