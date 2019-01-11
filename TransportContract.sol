pragma solidity ^0.4.20;

contract TransportContract {

    //Set of States
    enum StateType { Created, InTransit, Completed, OutOfCompliance}
    enum LoadStateType {DeadHead, Picked, Dropped}
    
    //List of properties
    StateType public  State;
    address public  Owner;
    address public  InitiatingCounterparty;
    address public  Counterparty;
    address public  PreviousCounterparty;
    address public  Device;
    address public  SupplyChainOwner;
    address public  SupplyChainObserver;
    int public  LastSensorUpdateTimestamp;
    int public SensorLatitude;
    int public SensorLongitude;
    int public TargetMaxLatitude;
    int public TargetMinLatitude;
    int public TargetMaxLongitude;
    int public TargetMinLongitude;
    int public PickupMaxLatitude;
    int public PickupMinLatitude;
    int public PickupMaxLongitude;
    int public PickupMinLongitude;
    LoadStateType public LoadState;
    
    function SetTarget(int targetLat, int targetLong) internal {
        TargetMaxLatitude = targetLat + 500;
        TargetMinLatitude = targetLat - 500;
        TargetMaxLongitude = targetLong + 500;
        TargetMinLongitude = targetLong - 500;
    }
    
    function SetPickup (int pickupLat, int pickupLong) internal {
        PickupMaxLatitude = pickupLat + 500;
        PickupMinLatitude = pickupLat - 500;
        PickupMaxLongitude = pickupLong + 500;
        PickupMinLongitude = pickupLong - 500;
    }
    
    constructor(address device, address supplyChainOwner, address supplyChainObserver, int targetLat, int targetLong, int pickupLat, int pickupLong) public
    {
        InitiatingCounterparty = msg.sender;
        Owner = InitiatingCounterparty;
        Counterparty = InitiatingCounterparty;
        Device = device;
        SupplyChainOwner = supplyChainOwner;
        SupplyChainObserver = supplyChainObserver;
        State = StateType.Created;
        ContractCreated();
        SensorLatitude = -1;
        SensorLongitude = -1;
        SetTarget(targetLat, targetLong);
        SetPickup(pickupLat, pickupLong);
        LoadState = LoadStateType.DeadHead;
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

    function IngestTelemetry( int timestamp, int latitude, int longitude) public
    {
        // Check if the location is within the target zone, if yes then set the state to complete.

        

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
        SensorLongitude = longitude;
        LastSensorUpdateTimestamp = timestamp;
        
        // check if the load has reached the target
        if(LoadState == LoadStateType.Picked){
            if ((latitude < TargetMaxLatitude && latitude > TargetMinLatitude) && (longitude < TargetMaxLongitude && longitude > TargetMinLongitude)){
                State = StateType.Completed;
                LoadState = LoadStateType.Dropped;
            }
            
        }
        
        // check if the load is at the pickup location
        if ((latitude < PickupMaxLatitude && latitude > PickupMinLatitude) && (longitude < PickupMaxLongitude && longitude > PickupMinLongitude)){
            State = StateType.InTransit;
            LoadState = LoadStateType.Picked;
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
