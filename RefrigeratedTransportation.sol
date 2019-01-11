pragma solidity ^0.4.20;

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
    int public SensorLatitude;
    int public SensorLatitudeDec;
    int public SensorLongitude;
    int public SensorLongitudeDec;
    int public TargetMaxLatitude;
    int public TargetMaxLatitudeDec;
    int public TargetMinLatitude;
    int public TargetMinLatitudeDec;
    int public TargetMaxLongitude;
    int public TargetMaxLongitudeDec;
    int public TargetMinLongitude;
    int public TargetMinLongitudeDec;
    

    constructor(address device, address supplyChainOwner, address supplyChainObserver, int minHumidity, int maxHumidity, int minTemperature, int maxTemperature, int targetMaxLatitude, int targetMaxLatitudeDec, int  targetMinLatitude, int  targetMinLatitudeDec, int  targetMaxLongitude, int targetMaxLongitudeDec, int targetMinLongitude, int targetMinLongitudeDec) public
    {
        ComplianceStatus = true;
        ComplianceSensorReading = -1;
        ComplianceSensorReadingDec = -1;
        InitiatingCounterparty = msg.sender;
        Owner = InitiatingCounterparty;
        Counterparty = InitiatingCounterparty;
        Device = device;
        SupplyChainOwner = supplyChainOwner;
        SupplyChainObserver = supplyChainObserver;
        MinHumidity = minHumidity;
        MaxHumidity = maxHumidity;
        MinTemperature = minTemperature;
        MaxTemperature = maxTemperature;
        State = StateType.Created;
        ComplianceDetail = 'N/A';
        ContractCreated();
        SensorLatitude = -1;
        SensorLatitudeDec = -1;
        SensorLongitude = -1;
        SensorLongitudeDec = -1;
        TargetMaxLatitude = targetMaxLatitude;
        TargetMaxLatitudeDec = targetMaxLatitudeDec;
        TargetMinLatitude = targetMinLatitude;
        TargetMinLatitudeDec = targetMinLatitudeDec;
        TargetMaxLongitude = targetMaxLongitude;
        TargetMaxLongitudeDec = targetMaxLongitudeDec;
        TargetMinLongitude = targetMinLongitude;
        TargetMinLongitudeDec = targetMinLongitudeDec;
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

    function IngestTelemetry(int humidity, int humidityDec, int temperature, int temperatureDec, int timestamp, int latitude, int latitudeDec, int longitude,  int longitudeDec) public
    {
        // Separately check for states and sender 
        // to avoid not checking for state when the sender is the device
        // because of the logical OR
        if ( State == StateType.Completed )
        {
            revert();
        }

        if ( State == StateType.OutOfCompliance )
        {
            revert();
        }

        if (Device != msg.sender)
        {
            revert();
        }
        SensorLatitude = latitude;
        SensorLatitudeDec = latitudeDec;
        SensorLongitude = longitude;
        SensorLongitudeDec = longitudeDec;
        LastSensorUpdateTimestamp = timestamp;

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

    function TransferResponsibility(address newCounterparty) public
    {
        // keep the state checking, message sender, and device checks separate
        // to not get cloberred by the order of evaluation for logical OR
        if ( State == StateType.Completed )
        {
            revert();
        }

        if ( State == StateType.OutOfCompliance )
        {
            revert();
        }

        if ( InitiatingCounterparty != msg.sender && Counterparty != msg.sender )
        {
            revert();
        }

        if ( newCounterparty == Device )
        {
            revert();
        }

        if (State == StateType.Created)
        {
            State = StateType.InTransit;
        }

        PreviousCounterparty = Counterparty;
        Counterparty = newCounterparty;
        ContractUpdated('TransferResponsibility');
    }

    function Complete() public
    {
        // keep the state checking, message sender, and device checks separate
        // to not get cloberred by the order of evaluation for logical OR
        if ( State == StateType.Completed )
        {
            revert();
        }

        if ( State == StateType.OutOfCompliance )
        {
            revert();
        }

        if (Owner != msg.sender && SupplyChainOwner != msg.sender)
        {
            revert();
        }

        State = StateType.Completed;
        PreviousCounterparty = Counterparty;
        Counterparty = 0x0;
        ContractUpdated('Complete');
    }
}
