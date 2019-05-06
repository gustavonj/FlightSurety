import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];

let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let oracles = [];


const app = express();
app.get('/api', (req, res) => {
  res.send({
    message: 'An API for use with your Dapp!'
  })
})


async function setupOracles() {
  let fee = await flightSuretyApp.methods.REGISTRATION_FEE().call()

  for (let i = 0; i < 20; i++) {
    let oracleAccount = accounts[i];

    var oracleRegistered = await flightSuretyApp.methods.registerOracle().send({
      from: oracleAccount,
      value: fee,
      gas: 3900000
    })

    oracleIndexes = await flightSuretyApp.methods.getMyIndexes().call({ from: accounts[i] })
    oracles[oracleAccount] = indexes;
    console.log("New Oracle registered: " + oracleAccount + " - indexes:" + oracleIndexes);

  }

  //console.log(oracles);
}



flightSuretyApp.events.OracleRequest({
  fromBlock: 0
}, function (error, result) {
  if (error) console.log(error);

  
  console.log(result.returnValues);
  const airline = result.returnValues.airline;
  const flight = result.returnValues.flight;
  const timestamp = result.returnValues.timestamp;
  const index = result.returnValues.index;

  console.log(" for " + flight + " and index:" + index + " airline: " + airline);


  try {
    for (var i = 0; i < oracles.length; i++) {

      if (oracles[i].includes(index)) {

        var statusCode = Math.floor(Math.random() * Math.floor(5)) * 10
     
        await flightSuretyApp.methods.submitOracleResponse(index, airline, flight, timestamp, statusCode)
          .send({ from: oracles[i], gas: 3900000 })

        console.log("Oracle " + oracles[i] + " - statuscode: " + statusCode + " flight " + flight + " - index:" + index);
      }
    }

  }
  catch (e) {
    console.log(e.message)
  }

});


setupOracles();

export default app;