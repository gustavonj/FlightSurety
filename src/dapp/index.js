
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        /*DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })*/

        DOM.elid('registerAirline').addEventListener('click', () => {
            let registerAirlineAddress = DOM.elid('registerAirlineAddress').value;
            let requesterAddress = DOM.elid('requesterAddress').value;
            contract.registerAirline(registerAirlineAddress, requesterAddress, (error, result) => {
                    if(error) {
                        alert(error);
                    }
                    DOM.elid('registerAirlineAddress').value = "";
                    DOM.elid('requesterAddress').value = "";

                    display('', 'Register submitted', [ { label: 'Register submitted', error: error, value: `Airline Address:  ${registerAirlineAddress}, Requester Address: ${requesterAddress}`} ], "register");
            });
        });

        DOM.elid('submitFunds').addEventListener('click', () => {
            let submitAirlineAddress = DOM.elid('fundsAirlineAddress').value;
            let fundsValue = DOM.elid('fundsValue').value;
            contract.submitFunds(submitAirlineAddress, fundsValue, (error, result) => {
                    if(error) {
                        alert(error);
                    }
                    DOM.elid('fundsAirlineAddress').value = "";
                    DOM.elid('fundsValue').value = "";

                    display('', 'Submitted Funds', [ { label: 'Submitted Funds', error: error, value: `Airline Address:  ${submitAirlineAddress}, Funds Value: ${fundsValue}`} ], "funds");
            });
        });

        DOM.elid('buyInsurance').addEventListener('click', () => {
            let passengerAddress = DOM.elid('passengerAddress').value;
            let insuranceAirlineAddress = DOM.elid('insuranceAirlineAddress').value;
            let selectedFlight = document.getElementById("selectFlight").options[document.getElementById("selectFlight").selectedIndex].value;
            let insuranceValue = DOM.elid('insuranceValue').value;
            if(selectedFlight === "0") {
                alert("Please select a flight");
            } else {
                selectedFlight = JSON.parse(selectedFlight);
                contract.buyInsurance(passengerAddress, insuranceAirlineAddress, selectedFlight.flight, selectedFlight.timestamp, insuranceValue, (error, result) => {
                    if(error) {
                        alert(error);
                    }
                    DOM.elid('insuranceAirlineAddress').value = "";
                    DOM.elid('passengerAddress').value = "";
                    DOM.elid('insuranceValue').value = "";
                    display('', 'Insurance purchased', [ { label: 'Insurance Purchased', error: error, value: `Insuree:  ${result.insuree}, value: ${result.insuranceValue} ETH, flight: ${result.flight}, airline: ${result.airline}, timestamp:  ${result.timestamp}`} ], "insurance");

                });
            }
        });
    

        DOM.elid('requestCredits').addEventListener('click', () => {
            let insureeAddreess = DOM.elid('insureeAddreess').value;
               
                contract.requestCredits(insureeAddreess, (error, result) => {
                    if(error) {
                        alert(error);
                    }
                    DOM.elid('insureeAddreess').value = "";
                    display('', 'Credits Refunded', [ { label: 'Credits Refunded', error: error, value: `Passenger:  ${insureeAddreess}`} ], "credits");
                });
            
        });
    });
    

})();


function display(title, description, results, wrapperName) {
    let displayDiv = DOM.elid(wrapperName+"-display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







