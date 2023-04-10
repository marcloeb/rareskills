import { ethers } from 'ethers';
import { createInstance } from './forwarder';
import { signMetaTxRequest } from './signer';

async function sendTx(registry, name) {
  console.log(`Sending register tx to set name=${name}`);
  return registry.register(name);
}

async function sendMetaTx(registry, provider, signer, name) {
  require('dotenv').config();

  console.log(`Sending register meta-tx to set name=${name}`);
  //const url = process.env.REACT_APP_WEBHOOK_URL;
  const url =
    'https://api.defender.openzeppelin.com/autotasks/916e5dc6-47e6-4d0a-8dde-dc509178d3db/runs/webhook/9b38e65f-7d5a-48de-afe1-192efb20f798/3uNUmxEKMCiWXNrEtUiTa6';
  if (!url) throw new Error(`Missing relayer url`);

  const forwarder = createInstance(provider);
  const from = await signer.getAddress();
  const data = registry.interface.encodeFunctionData('register', [name]);
  const to = registry.address;

  const request = await signMetaTxRequest(signer.provider, forwarder, { to, from, data });

  return fetch(url, {
    method: 'POST',
    body: JSON.stringify(request),
    headers: { 'Content-Type': 'application/json' },
  });
}

export async function registerName(registry, provider, name) {
  if (!name) throw new Error(`Name cannot be empty`);
  if (!window.ethereum) throw new Error(`User wallet not found`);

  await window.ethereum.enable();
  const userProvider = new ethers.providers.Web3Provider(window.ethereum);
  const userNetwork = await userProvider.getNetwork();
  if (userNetwork.chainId !== 5) throw new Error(`Please switch to Goerli for signing`);

  const signer = userProvider.getSigner();
  const from = await signer.getAddress();
  const balance = await provider.getBalance(from);

  const canSendTx = balance.gt(1e15);
  if (canSendTx) return sendTx(registry.connect(signer), name);
  else return sendMetaTx(registry, provider, signer, name);
}
