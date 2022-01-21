const ethers = require('ethers');

const generateAccount = (id, secret='') => {
  const privateKey = ethers.utils.id(`420 ${id}${secret}`);
  return new ethers.Wallet(privateKey);
}

const generateAccounts = (amount, secret='') => {
  const accounts = [];
  for (let i = 0; i < amount; i++) {
    accounts.push(generateAccount(i, secret));
  }

  return accounts;
}

const generatePrivateKeys = (amount, secret='') => {
  const accounts = generateAccounts(amount, secret);
  return accounts.map(item => item.privateKey);
}

const generateAccountsForHardhatNetwork = (amount, secret='') => {
  const accounts = generateAccounts(amount, secret);
  return accounts.map(item => {
    return {
      address: item.getAddress(),
      privateKey: item.privateKey,
      balance: '10000000000000000000000' // 1000 ETH
    }
  });
}

module.exports = {
  generateAccount,
  generateAccounts,
  generateAccountsForHardhatNetwork,
  generatePrivateKeys
}
