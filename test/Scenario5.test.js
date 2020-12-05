const { BN, time,} = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Eth2 = artifacts.require('Eth2');
const EthStaking = artifacts.require('EthStaking');

contract('Scenario4', function (accounts) {
  const [ eth2Owner, ethStakingOwner, customer1 ] = accounts;
  
  before(async function () {
    this.eth2 = await Eth2.new(eth2Owner, eth2Owner);
    this.ethStaking = await EthStaking.new(ethStakingOwner, ethStakingOwner);
    await this.eth2.changeContract(this.ethStaking.address);
    await this.ethStaking.changeContract(this.eth2.address);
  });

  after(async function () {
    await time.increase(-2592000);
  });

  it('Execute', async function () {
    await this.ethStaking.stake({ from: customer1, value: '12000000000000000000', gas: '5000000' });
    await this.ethStaking.stake({ from: customer1, value: '12000000000000000000', gas: '5000000' });
    await this.ethStaking.stake({ from: customer1, value: '12000000000000000000', gas: '5000000' });
    await time.increase(2592000);
    await this.ethStaking.withdrawDividend({ from: customer1, value: '0', gas: '5000000' });
  });

  it('Is the staking times correct?', async function () {
    let stakingTimes = await this.ethStaking.getStakingTimes(customer1);
    expect(stakingTimes).to.be.bignumber.equal(new BN('3'));
  });
  
  it('Is total withdrawal amount correct?', async function () {
    let totalStakingAmount = await this.ethStaking.getTotalWithdrawalAmount(customer1);
    expect(totalStakingAmount).to.be.bignumber.equal(new BN('7776000000000000000'));
  });

  it('Is total awarded eth2 amount correct?', async function () {
    let totalAwardedEth2Amount = await this.ethStaking.getTotalAwardedEth2Amount(customer1);
    expect(totalAwardedEth2Amount).to.be.bignumber.equal(new BN('102879090396427428327'));
  });
});