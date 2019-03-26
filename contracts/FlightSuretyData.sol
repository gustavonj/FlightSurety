pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    
    struct Airline {
        address airlineAddress;
        uint registeredIndex;
        bool isRegistered;
        uint activeIndex;
        bool isActive;
        mapping(address => bool) registrants;
        address[] registrantsIndexes;
        uint256 fundsValue;
    }

    struct Insurance {
        bytes32 flightKey;
        address insurer;
        address insuree;
        uint256 value;
        bool isPaid;
    }

    struct InsureeCredit {
        address insureeAddress;
        uint256 creditValue;
        bytes32[] creditedInsurances;
    }

    address[] registeredAirlines;
    address[] activeAirlines;

    mapping(address => Airline) private airlines;
    mapping(bytes32 => Insurance) private insurances;
    mapping(bytes32 => bytes32[]) private flightInsurances;
    mapping(address => InsureeCredit) private insureeCredits;

    // Allowed App Contracts
    mapping(address => bool) private authorizedContracts; 

    

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    //event debugEvent(uint id);
    event authorizedContract(address appContract);
    event deauthorizedContract(address appContract);

    event addedAirline(address airlineAddress, address requester);
    event registeredAirline(address airlineAddress);
    event airlineSubmittedFunds(address airlineAddress, uint256 value);
    event activedAirline(address airlineAddress);

    event removedActiveAirline(address airlineAddress, uint deletedIndex);
    event removedRegisteredAirline(address airlineAddress, uint deletedIndex);
    
    event insurancePurchased(address airline, string flight, uint256 timestamp, address insuree, uint256 value);
    event creditedFunds(bytes32 insuranceKey, bytes32 flightKey, address insurer, address insuree, uint256 value, bool isPaid);
    event payedInsuree(address insuree, uint value);

    /********************************************************************************************/
    /*                                      CONSTRUCTOR DEFINITION                              */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor (address initialAirline) public 
    {
        contractOwner = msg.sender;

        /* Rubric: First airline is registered when contract is deployed. */ 
       
        addAirline(initialAirline, msg.sender);
        registerAirline(initialAirline);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAuthorizedCallerForRegisterAirline() 
    {
        true;
        //FIXME:
        //require((authorizedContracts[msg.sender] == true) || msg.sender == contractOwner, "Caller is not authorized contract for register airline");
        _;
    }

    modifier requireAuthorizedCaller() 
    {
        true;
        //FIXME:
        //require((authorizedContracts[msg.sender] == true), string(abi.encodePacked("Caller is not authorized contract ", msg.sender)));
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
       return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external requireContractOwner 
    {
        operational = mode;
    }


    function authorizeContract
                            (
                                address appContractAddress
                            )
                            external
                            requireContractOwner
    {
        authorizedContracts[appContractAddress] = true; 
        emit authorizedContract(appContractAddress);
    }

    function deauthorizeContract
                            (
                                address appContractAddress
                            )
                            external
                            requireContractOwner
    {
        delete authorizedContracts[appContractAddress];
        emit deauthorizedContract(appContractAddress);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract //TODO: check address FlightSuretyApp
    *
    */   
    function addAirline(    
                            address airline, 
                            address requester
                        ) 
                        public 
                        //pure 
                        requireAuthorizedCallerForRegisterAirline
                        requireIsOperational 
    {   
        require(!airlines[airline].registrants[requester], "Airline is already added for this requester.");

        if (airlines[airline].airlineAddress == airline) {
            airlines[airline].registrants[requester] = true;
            airlines[airline].registrantsIndexes.push(requester);
        } else {
            airlines[airline].airlineAddress = airline;
            airlines[airline].registeredIndex = 0;
            airlines[airline].isRegistered = false;
            airlines[airline].activeIndex = 0;
            airlines[airline].isActive = false;
            airlines[airline].registrantsIndexes.push(requester);
            airlines[airline].registrants[requester] = true;
            airlines[airline].fundsValue = 0;
        }

        emit addedAirline(airline, requester);
    }


    function registerAirline(address airline) 
                            public 
                            requireAuthorizedCallerForRegisterAirline  
                            requireIsOperational 
                            returns(uint index) 
    {
        require(airlines[airline].airlineAddress == airline, "Airline not found.");
        require(!isRegisteredAirline(airline), "Airline already registered");
        airlines[airline].registeredIndex = registeredAirlines.push(airline) -1;
        airlines[airline].isRegistered = true;
        emit registeredAirline(airline);
        return airlines[airline].registeredIndex;
    }

    function activateAirline(address airline)
                            external 
                            requireAuthorizedCallerForRegisterAirline
                            requireIsOperational 
                            returns(uint index) 
    {
        require(airlines[airline].airlineAddress == airline, "Airline not found.");
        require(isRegisteredAirline(airline), "Airline not registered");
        require(!isActiveAirline(airline), "Airline already active");
        airlines[airline].activeIndex = activeAirlines.push(airline) -1;
        airlines[airline].isActive = true;
        return airlines[airline].activeIndex;
        emit activedAirline(airline);
    }


    function isRegisteredAirline(address airline)
                            public 
                            requireAuthorizedCallerForRegisterAirline  
                            requireIsOperational 
                            returns(bool) 
    {
        require(airlines[airline].airlineAddress == airline, "Airline not found.");
        return airlines[airline].isRegistered;
    }
    
    function isActiveAirline(address airline)
                            public 
                            requireAuthorizedCallerForRegisterAirline 
                            requireIsOperational 
                            returns(bool) 
    {
        require(airlines[airline].airlineAddress == airline, "Airline not found.");
        return airlines[airline].isActive;
    }

    function removeRegisteredAirline(address airline) 
                                    external 
                                    requireAuthorizedCallerForRegisterAirline  
                                    requireIsOperational 
    {
        
        require(airlines[airline].registeredIndex > 0, "Airline not registered");

        airlines[airline].registeredIndex = 0; 
        airlines[airline].isRegistered = false; 
        
        // Removing from array and fix index
        uint toDeleteIndex = airlines[airline].registeredIndex;
        address lastRegisteredAirline = registeredAirlines[registeredAirlines.length-1];
        registeredAirlines[toDeleteIndex] = lastRegisteredAirline;
        airlines[lastRegisteredAirline].registeredIndex = toDeleteIndex; 
        registeredAirlines.length--;
        emit removedRegisteredAirline(airline,toDeleteIndex);
    }    

     function removeActiveAirline(address airline)
                                external 
                                requireAuthorizedCallerForRegisterAirline  
                                requireIsOperational 
     {
        
        require(isActiveAirline(airline), "Airline not active");

        airlines[airline].activeIndex = 0; 
        airlines[airline].isActive = false; 

        // Removing from array and fix index
        uint toDeleteIndex = airlines[airline].activeIndex;
        address lastActivedAirline = activeAirlines[activeAirlines.length-1];
        activeAirlines[toDeleteIndex] = lastActivedAirline;
        airlines[lastActivedAirline].activeIndex = toDeleteIndex; 
        activeAirlines.length--;
        emit removedActiveAirline(airline,toDeleteIndex);

    }    

    
    function getRegistrants( address airline )
                                external
                                view 
                                requireAuthorizedCaller
                                requireIsOperational
                                returns (address[])  {
        return airlines[airline].registrantsIndexes;                                    
    } 

    function getRegisteredAirlines()
                                external
                                view 
                                requireAuthorizedCaller
                                requireIsOperational
                                returns (address[])  {
        return registeredAirlines;                                    
    } 

    function getActiveAirlines()
                                external
                                view 
                                requireAuthorizedCaller
                                requireIsOperational
                                returns (address[])  {
        return activeAirlines;                                    
    } 

    function getAirlineFunds(address airline)
                            public
                            view 
                            requireAuthorizedCaller
                            requireIsOperational
                            returns (uint256) {
        return airlines[airline].fundsValue;
    }


    /**
     * @dev Buy insurance for a flight
     *
     */
    function buyInsurance(address airline, 
                         string flight, 
                         uint256 timestamp, 
                         address buyer
                         ) 
                         external 
                         payable 
                         requireIsOperational
                         requireAuthorizedCaller
    {
        require(msg.value > 0, "Insurance value is zero");
        require(isActiveAirline(airline), "Airline is not active");
        
        bytes32 _flightKey = getFlightKey(airline, flight, timestamp);
        bytes32 _insuranceKey = keccak256(abi.encodePacked(buyer, airline, flight, timestamp));
        
        require(insurances[_insuranceKey].insuree != buyer, "Insurence already purchased");

        insurances[_insuranceKey] = Insurance({
            flightKey: _flightKey,
            insurer: airline,
            insuree: buyer,
            value: msg.value,
            isPaid: false
        });

        flightInsurances[_flightKey].push(_insuranceKey);
        fund(airline); 
        emit insurancePurchased(airline, flight, timestamp, buyer, msg.value);
    }


    /**
     *  @dev Credits payout to insuree
    */
     function getFlightInsurances
        (
            address airline, 
            string flight, 
            uint256 timestamp
        )
        external
        view
        requireAuthorizedCaller
        requireIsOperational
        returns (bytes32[])
    {
       return flightInsurances[getFlightKey(airline, flight, timestamp)];
    }


  
    /**
     *  @dev Credits payout to insuree
    */
     function creditToInsuree
        (
            bytes32 insuranceKey
        )
        external
        requireAuthorizedCaller
        requireIsOperational
    {
        require(insurances[insuranceKey].value > 0, "Insurance not found or with not funds.");
        require(!insurances[insuranceKey].isPaid, "Insurance already paid.");

        Insurance insurance = insurances[insuranceKey];
        uint256 creditsToPay = insurance.value.mul(15).div(10);

        require(creditsToPay < getAirlineFunds(insurance.insurer) , "Insurer not have funds to pay");

        airlines[insurance.insurer].fundsValue = airlines[insurance.insurer].fundsValue.sub(creditsToPay);
       
        insureeCredits[insurance.insuree].insureeAddress = insurance.insuree;
        insureeCredits[insurance.insuree].creditValue = creditsToPay;
        insureeCredits[insurance.insuree].creditedInsurances.push(insuranceKey);
        insurances[insuranceKey].isPaid = true;
        
        emit creditedFunds(insuranceKey, insurance.flightKey, insurance.insurer, insurance.insuree, insurance.value, insurance.isPaid);
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function payToInsuree(address requester) 
                        external
                        requireAuthorizedCaller
                        requireIsOperational
    {
        require(insureeCredits[requester].creditValue > 0, "Not credits to transfer");
        uint256 valueToPay = insureeCredits[requester].creditValue;
        insureeCredits[requester].creditValue = 0;
        requester.transfer(valueToPay);
        emit payedInsuree(requester, valueToPay);
        
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund(address senderAddress) 
                public 
                payable 
                requireIsOperational{
        require(msg.value > 0, "Funds equal zero");
        require(airlines[senderAddress].airlineAddress == senderAddress && isRegisteredAirline(senderAddress), "Airline not registered");
        airlines[senderAddress].fundsValue = airlines[senderAddress].fundsValue.add(msg.value);
        emit airlineSubmittedFunds(airlines[senderAddress].airlineAddress, airlines[senderAddress].fundsValue);
        emit airlineSubmittedFunds(senderAddress, msg.value);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        //pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function getInsuranceKey(address passenger, address airline, string memory flight, uint256 timestamp) 
                            //pure 
                            internal 
                            requireIsOperational 
                            requireAuthorizedCaller 
                            returns (bytes32) {
        return keccak256(abi.encodePacked(passenger, airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
        external 
        payable 
    {
        fund(msg.sender);
    }
      
}


