const { BN, time,} = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Eth2 = artifacts.require('Eth2');
const EthStaking = artifacts.require('EthStaking');

contract('Basic', function (accounts) {
  const [ eth2Owner, ethStakingOwner, customer1 ] = accounts;
  
  before(async function () {
    this.eth2 = await Eth2.new(eth2Owner, eth2Owner);
    this.ethStaking = await EthStaking.new(ethStakingOwner, ethStakingOwner);
    
    await this.eth2.changeContract(this.ethStaking.address);
    await this.ethStaking.changeContract(this.eth2.address);
  });

  it('Should not be able to withdraw if paused?', async function () {
    await this.ethStaking.paused();
    await this.ethStaking.stake({ from: customer1, value: '12000000000000000000', gas: '5000000' });
    await this.ethStaking.withdrawDividend({ from: customer1, value: '0', gas: '5000000' });
  });

  it('Should be able to withdraw if unpaused?', async function () {
    await this.ethStaking.unpaused();
    await this.ethStaking.stake({ from: customer1, value: '12000000000000000000', gas: '5000000' });
    await this.ethStaking.withdrawDividend({ from: customer1, value: '0', gas: '5000000' });
  });
});