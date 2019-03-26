import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {
        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        console.log("FlightSuretyApp: "+ config.appAddress);
        console.log("FlightSuretyData: "+ config.dataAddress);
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.flights = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {

            this.owner = accts[0];
            console.log("owner: " + this.owner);
            let counter = 1;

          
            while (this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while (this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    registerAirline(airlineAddress, requesterAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods.registerAirline(airlineAddress).send({
            from: requesterAddress,
            gas: 4712388,
            gasPrice: 100000000000
        }, (error, result) => {
            console.log(result);
            callback(error, result);
        });
    }

    submitFunds(airlineAddress, fundsValue, callback) {
        let self = this;
        self.flightSuretyApp.methods.submitFunds().send({
            from: airlineAddress,
            value: self.web3.utils.toWei(fundsValue, "ether"),
            gas: 4712388,
            gasPrice: 100000000000
        }, (error, result) => {
            console.log(result);
            callback(error, result);
        });
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({
                from: self.owner
            }, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({
                from: self.owner
            }, (error, result) => {
                callback(error, payload);
            });
    }

    buyInsurance(passenger, airline, flight, timestamp, insuranceValue, callback) {
       
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: timestamp,
            insuranceValue: insuranceValue,
            insuree: passenger
        }
        self.flightSuretyApp.methods.buyInsurance(payload.airline, payload.flight, payload.timestamp).send({
            from: passenger,
            value: self.web3.utils.toWei(insuranceValue, "ether"),
            gas: 4712388,
            gasPrice: 100000000000
        }, (error, result) => {
            callback(error, payload);
        });
    }


    requestCredits(insureeAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods.payToInsuree(insureeAddress).send({
            from: insureeAddress
        }, (error, result) => {
            console.log(result);
            callback(error, result);
        });
    }

}