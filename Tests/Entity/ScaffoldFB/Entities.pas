unit Entities;

interface

uses
  Dext.Entity,
  Dext.Entity.Mapping,
  Dext.Core.SmartTypes,
  Dext.Types.Nullable,
  Dext.Types.Lazy,
  System.SysUtils,
  System.Classes;

type

  TCountry = class;
  TCustomer = class;
  TDepartment = class;
  TEmployee = class;
  TEmployeeProject = class;
  TJob = class;
  TPhoneList = class;
  TProject = class;
  TProjDeptBudget = class;
  TSalaryHistory = class;
  TSales = class;

  [Table('COUNTRY')]
  TCountry = class
  private
    FCountry: StringType;
    FCurrency: StringType;
  public
    [PK, Column('COUNTRY')]
    property Country: StringType read FCountry write FCountry;
    [Column('CURRENCY')]
    property Currency: StringType read FCurrency write FCurrency;
  end;

  [Table('CUSTOMER')]
  TCustomer = class
  private
    FCustNo: IntType;
    FCustomer: StringType;
    FContactFirst: StringType;
    FContactLast: StringType;
    FPhoneNo: StringType;
    FAddressLine1: StringType;
    FAddressLine2: StringType;
    FCity: StringType;
    FStateProvince: StringType;
    FCountry: StringType;
    FPostalCode: StringType;
    FOnHold: StringType;
    FCountryNavigation: Lazy<TCountry>;
  public
    [PK, Column('CUST_NO')]
    property CustNo: IntType read FCustNo write FCustNo;
    [Column('CUSTOMER')]
    property Customer: StringType read FCustomer write FCustomer;
    [Column('CONTACT_FIRST')]
    property ContactFirst: StringType read FContactFirst write FContactFirst;
    [Column('CONTACT_LAST')]
    property ContactLast: StringType read FContactLast write FContactLast;
    [Column('PHONE_NO')]
    property PhoneNo: StringType read FPhoneNo write FPhoneNo;
    [Column('ADDRESS_LINE1')]
    property AddressLine1: StringType read FAddressLine1 write FAddressLine1;
    [Column('ADDRESS_LINE2')]
    property AddressLine2: StringType read FAddressLine2 write FAddressLine2;
    [Column('CITY')]
    property City: StringType read FCity write FCity;
    [Column('STATE_PROVINCE')]
    property StateProvince: StringType read FStateProvince write FStateProvince;
    [Column('COUNTRY')]
    property Country: StringType read FCountry write FCountry;
    [Column('POSTAL_CODE')]
    property PostalCode: StringType read FPostalCode write FPostalCode;
    [Column('ON_HOLD')]
    property OnHold: StringType read FOnHold write FOnHold;
    [ForeignKey('COUNTRY')]
    property CountryNavigation: Lazy<TCountry> read FCountryNavigation write FCountryNavigation;
  end;

  [Table('DEPARTMENT')]
  TDepartment = class
  private
    FDeptNo: StringType;
    FDepartment: StringType;
    FHeadDept: StringType;
    FMngrNo: IntType;
    FBudget: CurrencyType;
    FLocation: StringType;
    FPhoneNo: StringType;
    FHeadDeptNavigation: Lazy<TDepartment>;
    FMngrNoNavigation: Lazy<TEmployee>;
  public
    [PK, Column('DEPT_NO')]
    property DeptNo: StringType read FDeptNo write FDeptNo;
    [Column('DEPARTMENT')]
    property Department: StringType read FDepartment write FDepartment;
    [Column('HEAD_DEPT')]
    property HeadDept: StringType read FHeadDept write FHeadDept;
    [Column('MNGR_NO')]
    property MngrNo: IntType read FMngrNo write FMngrNo;
    [Column('BUDGET')]
    property Budget: CurrencyType read FBudget write FBudget;
    [Column('LOCATION')]
    property Location: StringType read FLocation write FLocation;
    [Column('PHONE_NO')]
    property PhoneNo: StringType read FPhoneNo write FPhoneNo;
    [ForeignKey('HEAD_DEPT')]
    property HeadDeptNavigation: Lazy<TDepartment> read FHeadDeptNavigation write FHeadDeptNavigation;
    [ForeignKey('MNGR_NO')]
    property MngrNoNavigation: Lazy<TEmployee> read FMngrNoNavigation write FMngrNoNavigation;
  end;

  [Table('EMPLOYEE')]
  TEmployee = class
  private
    FEmpNo: IntType;
    FFirstName: StringType;
    FLastName: StringType;
    FPhoneExt: StringType;
    FHireDate: DateTimeType;
    FDeptNo: StringType;
    FJobCode: StringType;
    FJobGrade: IntType;
    FJobCountry: StringType;
    FSalary: CurrencyType;
    FFullName: StringType;
    FDeptNoNavigation: Lazy<TDepartment>;
    FJobCodeNavigation: Lazy<TJob>;
  public
    [PK, Column('EMP_NO')]
    property EmpNo: IntType read FEmpNo write FEmpNo;
    [Column('FIRST_NAME')]
    property FirstName: StringType read FFirstName write FFirstName;
    [Column('LAST_NAME')]
    property LastName: StringType read FLastName write FLastName;
    [Column('PHONE_EXT')]
    property PhoneExt: StringType read FPhoneExt write FPhoneExt;
    [Column('HIRE_DATE')]
    property HireDate: DateTimeType read FHireDate write FHireDate;
    [Column('DEPT_NO')]
    property DeptNo: StringType read FDeptNo write FDeptNo;
    [Column('JOB_CODE')]
    property JobCode: StringType read FJobCode write FJobCode;
    [Column('JOB_GRADE')]
    property JobGrade: IntType read FJobGrade write FJobGrade;
    [Column('JOB_COUNTRY')]
    property JobCountry: StringType read FJobCountry write FJobCountry;
    [Column('SALARY')]
    property Salary: CurrencyType read FSalary write FSalary;
    [Column('FULL_NAME')]
    property FullName: StringType read FFullName write FFullName;
    [ForeignKey('DEPT_NO')]
    property DeptNoNavigation: Lazy<TDepartment> read FDeptNoNavigation write FDeptNoNavigation;
    [ForeignKey('JOB_CODE')]
    property JobCodeNavigation: Lazy<TJob> read FJobCodeNavigation write FJobCodeNavigation;
  end;

  [Table('EMPLOYEE_PROJECT')]
  TEmployeeProject = class
  private
    FEmpNo: IntType;
    FProjId: StringType;
    FEmpNoNavigation: Lazy<TEmployee>;
    FProj: Lazy<TProject>;
  public
    [PK, Column('EMP_NO')]
    property EmpNo: IntType read FEmpNo write FEmpNo;
    [PK, Column('PROJ_ID')]
    property ProjId: StringType read FProjId write FProjId;
    [ForeignKey('EMP_NO')]
    property EmpNoNavigation: Lazy<TEmployee> read FEmpNoNavigation write FEmpNoNavigation;
    [ForeignKey('PROJ_ID')]
    property Proj: Lazy<TProject> read FProj write FProj;
  end;

  [Table('JOB')]
  TJob = class
  private
    FJobCode: StringType;
    FJobGrade: IntType;
    FJobCountry: StringType;
    FJobTitle: StringType;
    FMinSalary: CurrencyType;
    FMaxSalary: CurrencyType;
    FJobRequirement: TBytes;
    FJobCountryNavigation: Lazy<TCountry>;
  public
    [PK, Column('JOB_CODE')]
    property JobCode: StringType read FJobCode write FJobCode;
    [PK, Column('JOB_GRADE')]
    property JobGrade: IntType read FJobGrade write FJobGrade;
    [PK, Column('JOB_COUNTRY')]
    property JobCountry: StringType read FJobCountry write FJobCountry;
    [Column('JOB_TITLE')]
    property JobTitle: StringType read FJobTitle write FJobTitle;
    [Column('MIN_SALARY')]
    property MinSalary: CurrencyType read FMinSalary write FMinSalary;
    [Column('MAX_SALARY')]
    property MaxSalary: CurrencyType read FMaxSalary write FMaxSalary;
    [Column('JOB_REQUIREMENT')]
    property JobRequirement: TBytes read FJobRequirement write FJobRequirement;
    [ForeignKey('JOB_COUNTRY')]
    property JobCountryNavigation: Lazy<TCountry> read FJobCountryNavigation write FJobCountryNavigation;
  end;

  [Table('PHONE_LIST')]
  TPhoneList = class
  private
    FEmpNo: IntType;
    FFirstName: StringType;
    FLastName: StringType;
    FPhoneExt: StringType;
    FLocation: StringType;
    FPhoneNo: StringType;
  public
    [Column('EMP_NO')]
    property EmpNo: IntType read FEmpNo write FEmpNo;
    [Column('FIRST_NAME')]
    property FirstName: StringType read FFirstName write FFirstName;
    [Column('LAST_NAME')]
    property LastName: StringType read FLastName write FLastName;
    [Column('PHONE_EXT')]
    property PhoneExt: StringType read FPhoneExt write FPhoneExt;
    [Column('LOCATION')]
    property Location: StringType read FLocation write FLocation;
    [Column('PHONE_NO')]
    property PhoneNo: StringType read FPhoneNo write FPhoneNo;
  end;

  [Table('PROJECT')]
  TProject = class
  private
    FProjId: StringType;
    FProjName: StringType;
    FProjDesc: TBytes;
    FTeamLeader: IntType;
    FProduct: StringType;
    FTeamLeaderNavigation: Lazy<TEmployee>;
  public
    [PK, Column('PROJ_ID')]
    property ProjId: StringType read FProjId write FProjId;
    [Column('PROJ_NAME')]
    property ProjName: StringType read FProjName write FProjName;
    [Column('PROJ_DESC')]
    property ProjDesc: TBytes read FProjDesc write FProjDesc;
    [Column('TEAM_LEADER')]
    property TeamLeader: IntType read FTeamLeader write FTeamLeader;
    [Column('PRODUCT')]
    property Product: StringType read FProduct write FProduct;
    [ForeignKey('TEAM_LEADER')]
    property TeamLeaderNavigation: Lazy<TEmployee> read FTeamLeaderNavigation write FTeamLeaderNavigation;
  end;

  [Table('PROJ_DEPT_BUDGET')]
  TProjDeptBudget = class
  private
    FFiscalYear: IntType;
    FProjId: StringType;
    FDeptNo: StringType;
    FProjectedBudget: CurrencyType;
    FDeptNoNavigation: Lazy<TDepartment>;
    FProj: Lazy<TProject>;
  public
    [PK, Column('FISCAL_YEAR')]
    property FiscalYear: IntType read FFiscalYear write FFiscalYear;
    [PK, Column('PROJ_ID')]
    property ProjId: StringType read FProjId write FProjId;
    [PK, Column('DEPT_NO')]
    property DeptNo: StringType read FDeptNo write FDeptNo;
    [Column('PROJECTED_BUDGET')]
    property ProjectedBudget: CurrencyType read FProjectedBudget write FProjectedBudget;
    [ForeignKey('DEPT_NO')]
    property DeptNoNavigation: Lazy<TDepartment> read FDeptNoNavigation write FDeptNoNavigation;
    [ForeignKey('PROJ_ID')]
    property Proj: Lazy<TProject> read FProj write FProj;
  end;

  [Table('SALARY_HISTORY')]
  TSalaryHistory = class
  private
    FEmpNo: IntType;
    FChangeDate: DateTimeType;
    FUpdaterId: StringType;
    FOldSalary: CurrencyType;
    FPercentChange: FloatType;
    FNewSalary: FloatType;
    FEmpNoNavigation: Lazy<TEmployee>;
  public
    [PK, Column('EMP_NO')]
    property EmpNo: IntType read FEmpNo write FEmpNo;
    [PK, Column('CHANGE_DATE')]
    property ChangeDate: DateTimeType read FChangeDate write FChangeDate;
    [PK, Column('UPDATER_ID')]
    property UpdaterId: StringType read FUpdaterId write FUpdaterId;
    [Column('OLD_SALARY')]
    property OldSalary: CurrencyType read FOldSalary write FOldSalary;
    [Column('PERCENT_CHANGE')]
    property PercentChange: FloatType read FPercentChange write FPercentChange;
    [Column('NEW_SALARY')]
    property NewSalary: FloatType read FNewSalary write FNewSalary;
    [ForeignKey('EMP_NO')]
    property EmpNoNavigation: Lazy<TEmployee> read FEmpNoNavigation write FEmpNoNavigation;
  end;

  [Table('SALES')]
  TSales = class
  private
    FPoNumber: StringType;
    FCustNo: IntType;
    FSalesRep: IntType;
    FOrderStatus: StringType;
    FOrderDate: DateTimeType;
    FShipDate: DateTimeType;
    FDateNeeded: DateTimeType;
    FPaid: StringType;
    FQtyOrdered: IntType;
    FTotalValue: CurrencyType;
    FDiscount: FloatType;
    FItemType: StringType;
    FAged: CurrencyType;
    FCustNoNavigation: Lazy<TCustomer>;
    FSalesRepNavigation: Lazy<TEmployee>;
  public
    [PK, Column('PO_NUMBER')]
    property PoNumber: StringType read FPoNumber write FPoNumber;
    [Column('CUST_NO')]
    property CustNo: IntType read FCustNo write FCustNo;
    [Column('SALES_REP')]
    property SalesRep: IntType read FSalesRep write FSalesRep;
    [Column('ORDER_STATUS')]
    property OrderStatus: StringType read FOrderStatus write FOrderStatus;
    [Column('ORDER_DATE')]
    property OrderDate: DateTimeType read FOrderDate write FOrderDate;
    [Column('SHIP_DATE')]
    property ShipDate: DateTimeType read FShipDate write FShipDate;
    [Column('DATE_NEEDED')]
    property DateNeeded: DateTimeType read FDateNeeded write FDateNeeded;
    [Column('PAID')]
    property Paid: StringType read FPaid write FPaid;
    [Column('QTY_ORDERED')]
    property QtyOrdered: IntType read FQtyOrdered write FQtyOrdered;
    [Column('TOTAL_VALUE')]
    property TotalValue: CurrencyType read FTotalValue write FTotalValue;
    [Column('DISCOUNT')]
    property Discount: FloatType read FDiscount write FDiscount;
    [Column('ITEM_TYPE')]
    property ItemType: StringType read FItemType write FItemType;
    [Column('AGED')]
    property Aged: CurrencyType read FAged write FAged;
    [ForeignKey('CUST_NO')]
    property CustNoNavigation: Lazy<TCustomer> read FCustNoNavigation write FCustNoNavigation;
    [ForeignKey('SALES_REP')]
    property SalesRepNavigation: Lazy<TEmployee> read FSalesRepNavigation write FSalesRepNavigation;
  end;

implementation

end.
