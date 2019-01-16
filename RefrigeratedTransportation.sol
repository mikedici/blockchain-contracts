pragma solidity ^0.4.24;

contract RefrigeratedTransportation  {

    //Set of States
    enum StateType { Created, InTransit, Completed, OutOfCompliance}
    enum SensorType { None, Humidity, Temperature }

    //List of properties
    StateType public  State;
    address public  Owner;
    address public  InitiatingCounterparty;
    address public  Counterparty;
    address public  PreviousCounterparty;
    address public  Device;
    address public  SupplyChainOwner;
    address public  SupplyChainObserver;
    int public  MinHumidity;
    int public  MaxHumidity;
    int public  MinTemperature;
    int public  MaxTemperature;
    SensorType public  ComplianceSensorType;
    int public  ComplianceSensorReading;
    int public  ComplianceSensorReadingDec;
    bool public  ComplianceStatus;
    string public  ComplianceDetail;
    int public  LastSensorUpdateTimestamp;
    
    constructor(address device, address supplyChainOwner, address supplyChainObserver, int minHumidity, int maxHumidity, int minTemperature, int maxTemperature) public
    {
        ComplianceStatus = true;
        ComplianceSensorReading = -1;
        ComplianceSensorReadingDec = -1;
        InitiatingCounterparty = msg.sender;
        Device = device;
        Owner = InitiatingCounterparty;
        Counterparty = InitiatingCounterparty;
        SupplyChainOwner = supplyChainOwner;
        SupplyChainObserver = supplyChainObserver;
        MinHumidity = minHumidity;
        MaxHumidity = maxHumidity;
        MinTemperature = minTemperature;
        MaxTemperature = maxTemperature;
        State = StateType.Created;
        ComplianceDetail = 'N/A';
        ContractCreated();
    }
    

    event WorkbenchContractCreated(string applicationName, string workflowName, address originatingAddress);
    event WorkbenchContractUpdated(string applicationName, string workflowName, string action, address originatingAddress);

    string internal ApplicationName;
    string internal WorkflowName;


    function ContractCreated() internal {
        emit WorkbenchContractCreated(ApplicationName, WorkflowName, msg.sender);
    }

    function ContractUpdated(string action) internal {
        emit WorkbenchContractUpdated(ApplicationName, WorkflowName, action, msg.sender);
    }


    function IngestTelemetry(int humidity, int humidityDec, int temperature, int temperatureDec, int timestamp) public validState
    {
        require(Device == msg.sender);

        if ((humidity > MaxHumidity || humidity < MinHumidity)||(humidity == MaxHumidity && humidityDec > 0))
        {
            ComplianceSensorType = SensorType.Humidity;
            ComplianceSensorReading = humidity;
            ComplianceSensorReadingDec = humidityDec;
            ComplianceDetail = 'Humidity value out of range.';
            ComplianceStatus = false;
        }
        else if ((temperature > MaxTemperature || temperature < MinTemperature)||(temperature == MaxTemperature && temperatureDec > 0))
        {
            ComplianceSensorType = SensorType.Temperature;
            ComplianceSensorReading = temperature;
            ComplianceSensorReadingDec = temperatureDec;
            ComplianceDetail = 'Temperature value out of range.';
            ComplianceStatus = false;
        }

        if (ComplianceStatus == false)
        {
            State = StateType.OutOfCompliance;
        }

        ContractUpdated('IngestTelemetry');
    }

    function TransferResponsibility(address newCounterparty) public validState
    {
        require(InitiatingCounterparty == msg.sender || Counterparty == msg.sender);
        require(newCounterparty != Device);

        if (State == StateType.Created)
        {
            State = StateType.InTransit;
        }

        PreviousCounterparty = Counterparty;
        Counterparty = newCounterparty;
        ContractUpdated('TransferResponsibility');
    }

    function Complete() public validState
    {
        require(Owner == msg.sender || SupplyChainOwner == msg.sender);

        State = StateType.Completed;
        PreviousCounterparty = Counterparty;
        Counterparty = 0x0;
        ContractUpdated('Complete');
    }
    modifier validState() {
      require(State == StateType.Created || State == StateType.InTransit);
      _;
    }
}
