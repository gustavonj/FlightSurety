
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeContract(config.flightSuretyApp.address);
    await config.flightSuretyData.authorizeContract("0xFa82B9121E37A104DE430E84CA63DcFfBcfF2551");
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;

      //Pausing contract
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, {from: config.owner});
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

      //Activate contract
      try 
      {
          await config.flightSuretyData.setOperatingStatus(true, {from: config.owner});
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it('(airline) Only existing airline may register a new airline until there are at least four airlines registered', async () => {
    
    // ARRANGE
    let airline2 = accounts[2];
    let airline3 = accounts[3];
    let airline4 = accounts[4];
    let airline5 = accounts[5];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(airline2, {from: config.firstAirline});
        await config.flightSuretyApp.registerAirline(airline3, {from: airline2});
        await config.flightSuretyApp.registerAirline(airline4, {from: config.firstAirline});
        await config.flightSuretyApp.registerAirline(airline5, {from: config.firstAirline});
    }
    catch(e) {
        console.log(e);
    }
    let resultAirline2 = await config.flightSuretyData.isRegisteredAirline.call(airline2, {from: config.owner}); 
    let resultAirline3 = await config.flightSuretyData.isRegisteredAirline.call(airline3, {from: config.owner}); 
    let resultAirline4 = await config.flightSuretyData.isRegisteredAirline.call(airline4, {from: config.owner}); 
    let resultAirline5 = await config.flightSuretyData.isRegisteredAirline.call(airline5, {from: config.owner}); 

    // ASSERT
    assert.equal(resultAirline2, true, "Airline registered should be able to register until there are at least four airlines registered");
    assert.equal(resultAirline3, true, "Airline registered should be able to register until there are at least four airlines registered");
    assert.equal(resultAirline4, true, "Airline registered should be able to register until there are at least four airlines registered");
    assert.equal(resultAirline5, false, "Registration of fifth and subsequent airlines requires multi-party consensus");
    
  });


  it('(airline) Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines', async () => {
    
    // ARRANGE
    let airline2 = accounts[2];
    let airline3 = accounts[3];
    let airline4 = accounts[4];
    let airline5 = accounts[5];
    let airline6 = accounts[6];
    let airline7 = accounts[7];
    
    // ACT
    try {

        //Assuming that in the previous test 4 airlines were registered
        await config.flightSuretyApp.registerAirline(airline6, {from: config.firstAirline});
        await config.flightSuretyApp.registerAirline(airline7, {from: airline2});
        await config.flightSuretyApp.registerAirline(airline7, {from: config.firstAirline});
        
    }
    catch(e) {
        console.log(e);
    }
    
    let resultAirline6 = await config.flightSuretyData.isRegisteredAirline.call(airline6, {from: config.owner}); 
    let resultAirline7 = await config.flightSuretyData.isRegisteredAirline.call(airline7, {from: config.owner}); 
   
    // ASSERT
    assert.equal(resultAirline6, false, "Airline registered requires multi-party consensus of 50% of registered airlines");
    assert.equal(resultAirline7, true, "Airline registered has consensus of 50% of registered airlines");
    
  });

  it('(airline) can airline to submit funds to be active', async () => {
    
    // ARRANGE
    let airline7 = accounts[7];
    
    //Assuming that in the previous test airline7 were registered
    let isRegisteredAirline7 = await config.flightSuretyData.isRegisteredAirline.call(airline7, {from: config.owner}); 
    let isActiveAirline7 = await config.flightSuretyData.isActiveAirline.call(airline7, {from: config.owner}); 

    // ASSERT
    assert.equal(isRegisteredAirline7, true, "Airline 7 shoud be registered");
    assert.equal(isActiveAirline7, false, "Airline 7 shoud not be active yet");
    
    // ACT (Submitting 1 ether)
    await config.flightSuretyApp.submitFunds({
        from: airline7,
        value: config.weiMultiple * 1
    });

    
    // ASSERT
    assert.equal(isActiveAirline7, false, "Airline 7 shoud not be active yet");

    // ACT (Submitting more 9 ether)
    
    await config.flightSuretyApp.submitFunds({
        from: airline7,
        value: config.weiMultiple * 9
    });

    isActiveAirline7 = await config.flightSuretyData.isActiveAirline.call(airline7, {from: config.owner}); 

    // ASSERT
    assert.equal(isActiveAirline7, true, "Airline 7 shoud be active now");
    
  });



  it(`(passenger) can buy a flight insurance`, async function () {
    
    // ARRANGE
    let airline7 = accounts[7];
    let passenger9 = accounts[9];
    let purchased = false;
    
    // ACT
    try {
        await config.flightSuretyApp.buyInsurance(airline7, "1234 - New York to Sao Paulo", 1, {
            from: passenger9,
            value: config.weiMultiple * 1
        });
        purchased = true;
    } catch (e) {
        console.log(e);
        purchased = false;
    }

    // ASSERT
    assert.equal(purchased, true, "Passenger should be to buy a flight insurance");

});


it(`(passengers) can to be credited`, async function () {
    
    // ARRANGE
    let airline7 = accounts[7];
    let credited = false;
    
    // ACT
    try {
        await config.flightSuretyApp.creditInsurees(airline7, "1234 - New York to Sao Paulo", 1);
        credited = true;
    } catch (e) {
        console.log(e);
        credited = false;
    }

    // ASSERT
    assert.equal(credited, true, "Passengers should have been credited");

});


it(`(passenger) can to be payed/refunded`, async function () {
    
    // ARRANGE
    let airline7 = accounts[7];
    
    // assuming previous tests, the nine passenger can be refunded now
    let passenger9 = accounts[9];

    let payed = false;

    // ACT
    try {
        await config.flightSuretyApp.payToInsuree(passenger9);
        payed = true;
      
    } catch (e) {
        console.log(e);
        payed = false;
    }

    // ASSERT
    assert.equal(payed, true, "Passenger should be refunded");

});

  
});



