const Migrations = artifacts.require("Migrations");
const IBCHost = artifacts.require("IBCHost");
const IBFT2Client = artifacts.require("IBFT2Client");
const IBCClient = artifacts.require("IBCClient");
const IBCConnection = artifacts.require("IBCConnection");
const IBCChannel = artifacts.require("IBCChannel");
const IBCHandler = artifacts.require("IBCHandler");
const IBCMsgs = artifacts.require("IBCMsgs");
const IBCIdentifier = artifacts.require("IBCIdentifier");
const SimpleTokenModule = artifacts.require("SimpleTokenModule");
const SimpleToken = artifacts.require("SimpleToken");
const ICS20Transfer = artifacts.require("ICS20Transfer");
const ICS20Vouchers = artifacts.require("ICS20Vouchers");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(IBCIdentifier).then(function() {
    return deployer.link(IBCIdentifier, [IBCHost, IBFT2Client, IBCHandler, SimpleTokenModule]);
  });
  deployer.deploy(IBCMsgs).then(function() {
    return deployer.link(IBCMsgs, [IBCClient, IBCConnection, IBCChannel, IBCHandler, IBFT2Client]);
  });
  deployer.deploy(IBCClient).then(function() {
    return deployer.link(IBCClient, [IBCHandler, IBCConnection, IBCChannel]);
  });
  deployer.deploy(IBCConnection).then(function() {
    return deployer.link(IBCConnection, [IBCHandler, IBCChannel]);
  });
  deployer.deploy(IBCChannel).then(function() {
    return deployer.link(IBCChannel, [IBCHandler, SimpleTokenModule]);
  });
  deployer.deploy(IBFT2Client);
  deployer.deploy(IBCHost).then(function() {
    return deployer.deploy(IBCHandler, IBCHost.address).then(function() {
      return deployer.deploy(SimpleTokenModule, IBCHost.address, IBCHandler.address);
    });
  });
  deployer.deploy(SimpleToken, "simple", "simple", 1000000);
  deployer.deploy(ICS20Vouchers).then(function() {
    return deployer.deploy(ICS20Transfer, IBCHost.address, IBCHandler.address, ICS20Vouchers.address);
  });
};
