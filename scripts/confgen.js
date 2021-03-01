const IBCHost = artifacts.require("IBCHost");
const IBFT2Client = artifacts.require("IBFT2Client");
const IBCHandler = artifacts.require("IBCHandler");
const IBCIdentifier = artifacts.require("IBCIdentifier");
const SimpleTokenModule = artifacts.require("SimpleTokenModule");
const SimpleToken = artifacts.require("SimpleToken");
const ICS20Transfer = artifacts.require("ICS20Transfer");
const ICS20Vouchers = artifacts.require("ICS20Vouchers");

var fs = require("fs");
var ejs = require("ejs");

if (!process.env.CONF_TPL) {
  console.log("You must set environment variable 'CONF_TPL'");
  process.exit(1);
}

const makePairs = function(arr) {
  var pairs = [];
  for (var i=0 ; i<arr.length ; i+=2) {
      if (arr[i+1] !== undefined) {
          pairs.push ([arr[i], arr[i+1]]);
      } else {
          console.error("invalid pair found");
          process.exit(1);
      }
  }
  return pairs;
};

const targets = makePairs(process.env.CONF_TPL.split(":"));

module.exports = function(callback) {
  targets.forEach(function(item) {
    ejs.renderFile(item[1], {
      IBCHostAddress: IBCHost.address,
      IBCHandlerAddress: IBCHandler.address,
      IBFT2ClientAddress: IBFT2Client.address,
      IBCIdentifierAddress: IBCIdentifier.address,
      SimpleTokenModuleAddress: SimpleTokenModule.address,
      SimpleTokenAddress: SimpleToken.address,
      ICS20TransferAddress: ICS20Transfer.address,
      ICS20VouchersAddress: ICS20Vouchers.address
    }, null, function(err, str){
        if (err) {
          throw err;
        }
        fs.writeFileSync(item[0], str);
        console.log('generated file', item[0]);
      });
  });
  callback();
};
