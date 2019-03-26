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
        bytes32[] paidInsurances;
    }

    address[] registeredAirlines;
    address[] activeAirlines;

    mapping(address => Airline) private airlines;
    mapping(address => bool) private authorizedContracts; 
    mapping(bytes32 => Insurance) private insurances;
    mapping(bytes32 => bytes32[]) private flightInsurances;
    mapping(address => InsureeCredit) private insureeCredits;

    // Allowed App Contracts

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    //TODO:




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

        //TODO: Tests
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

    modifier requireAuthorizedCallerForRegisterAirline() //TODO: tests
    {
        require((authorizedContracts[msg.sender] == true) || msg.sender == contractOwner, "Caller is not authorized contract for register airline");
        _;
    }

    modifier requireAuthorizedCaller() //TODO: tests
    {
        require((authorizedContracts[msg.sender] == true), "Caller is not authorized contract");
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
    }

    function deauthorizeContract
                            (
                                address appContractAddress
                            )
                            external
                            requireContractOwner
    {
        delete authorizedContracts[appContractAddress];
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
                        //pure //TODO: check it
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
        }

        //TODO: emmit event*/
        
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

        return airlines[airline].registeredIndex;
        //TODO: emmit event
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
        //TODO: emmit event
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
                                    returns(uint index) 
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
        return toDeleteIndex;   

        //TODO: emmit event
    }    

     function removeActiveAirline(address airline)
                                external 
                                requireAuthorizedCallerForRegisterAirline  
                                requireIsOperational 
                                returns(uint index) 
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
        return toDeleteIndex; 

        //TODO: emmit event  
    }    

    //TODO: documentation
    function getRegistrants( address airline )
                                external
                                view 
                                //requireAuthorizedCaller FIXME:
                                requireIsOperational
                                returns (address[])  {
        return airlines[airline].registrantsIndexes;                                    
    } 

    function getRegisteredAirlines()
                                external
                                view 
                                //requireAuthorizedCallerrequireAuthorizedCaller FIXME:
                                requireIsOperational
                                returns (address[])  {
        return registeredAirlines;                                    
    } 

    function getActiveAirlines()
                                external
                                view //TODO: check it
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
        require(msg.value > 0, "Insurance value is 0");
        require(isActiveAirline(airline), "Airline is not active");
        require(airlines[airline].airlineAddress == buyer, "Insuree can not to be an airline");
        
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
        
        fund(airline); //TODO: check it

        //TODO: emit insurancePurchased(airline, flight, timestamp, passenger, insuranceAmount);
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

        require(creditsToPay > getAirlineFunds(insurance.insurer) , "Insurer not have funds to pay");

        airlines[insurance.insurer].fundsValue.sub(creditsToPay);
        /*insureeCredits[insurance.insuree] = InsureeCredit({
            insureeAddress: insurance.insuree,
            creditValue: creditsToPay
        });*/
    
       insureeCredits[insurance.insuree].insureeAddress = insurance.insuree;
       insureeCredits[insurance.insuree].creditValue = creditsToPay;
       insureeCredits[insurance.insuree].creditedInsurances.push(insuranceKey);
        
        //TODO: emit insuranceClaimed(airline, flight, timestamp, passenger, amountCreditedToPassenger);
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

        insureeCredits[requester].creditValue = 0;
        requester.transfer(insureeCredits[requester].creditValue);

        insureeCredits[requester].paidInsurances = insureeCredits[requester].creditedInsurances; //TODO: check it;

        //TODO: emits
        
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
        require(airlines[senderAddress].airlineAddress == senderAddress && isRegisteredAirline(senderAddress), "Airline not registered");
        airlines[senderAddress].fundsValue.add(msg.value);
        //TODO: test it
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


