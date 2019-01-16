pragma solidity ^0.4.24;

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
    
    function SetTarget(int targetLat, int targetLong, int range) internal {
        TargetMaxLatitude = targetLat + range;
        TargetMinLatitude = targetLat - range;
        TargetMaxLongitude = targetLong + range;
        TargetMinLongitude = targetLong - range;
    }
    
    function SetPickup (int pickupLat, int pickupLong, int range) internal {
        PickupMaxLatitude = pickupLat + range;
        PickupMinLatitude = pickupLat - range;
        PickupMaxLongitude = pickupLong + range;
        PickupMinLongitude = pickupLong - range;
    }
    
    constructor(address device, address supplyChainOwner, address supplyChainObserver, int targetLat, int targetLong, int pickupLat, int pickupLong, int range) public
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
        SetTarget(targetLat, targetLong, range);
        SetPickup(pickupLat, pickupLong, range);
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

    function IngestTelemetry( int timestamp, int latitude, int longitude) public ingestChecks
    {
        SensorLatitude = latitude;
        SensorLongitude = longitude;
        LastSensorUpdateTimestamp = timestamp;
        
         // check if the load is at the pickup location
        if ((latitude < PickupMaxLatitude && latitude > PickupMinLatitude) && (longitude < PickupMaxLongitude && longitude > PickupMinLongitude)){
            State = StateType.InTransit;
            LoadState = LoadStateType.Picked;
        }
        
        // check if the load has reached the target
        if(LoadState == LoadStateType.Picked){
            if ((latitude < TargetMaxLatitude && latitude > TargetMinLatitude) && (longitude < TargetMaxLongitude && longitude > TargetMinLongitude)){
                State = StateType.Completed;
                LoadState = LoadStateType.Dropped;
            }
            
        }

        ContractUpdated('IngestTelemetry');
    }
      modifier ingestChecks() {
        require(State == StateType.Created || State == StateType.InTransit);
        require(Device == msg.sender);
        _;
      }

    function TransferResponsibility(address newCounterparty) public
    {
        require(State == StateType.Created || State == StateType.InTransit);
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
