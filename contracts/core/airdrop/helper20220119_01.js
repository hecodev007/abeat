const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const Web3 = require("web3");
const web3 = new Web3();

let data = [
  {
    address: "0x8A733f6b6F90E057F7bdCC68b1367B07Fc5A460F",
    amount: 10000,
    index: 0,
  },
  {
    address: "0xF0B75806d7Cf16E945629B58309Aaffc97dBcf40",
    amount: 20000,
    index: 1,
  },
];

function formatNumber(num) {
  return web3.utils.padLeft(web3.utils.numberToHex(num).slice(2), 64);
}

data = data.map((it) => ({
  data: it.address + formatNumber(it.amount) + formatNumber(it.index),
  ...it,
}));

const leaves = data.map((v) => keccak256(v.data));
const tree = new MerkleTree(leaves, keccak256, { sort: true });
const root = tree.getHexRoot();

exports.getRoot = function () {
  return root;
};

exports.getProof = function (index) {
  const proof = tree.getHexProof(keccak256(data[index].data));
  return { proof, ...data[index] };
};

console.log("root:");
console.log(root);

const proof0 = tree.getHexProof(keccak256(data[0].data));
console.log("proof0:");
console.log(proof0);

const proof1 = tree.getHexProof(keccak256(data[1].data));
console.log("proof1:");
console.log(proof1);

/*
D:\airdrop>node helper20220119_01.js
root:
0x24faa0c2b275fa5bc217415b35a89c92b26c382891265fb20023c2437f3e80cf

proof0:
[
  '0xa378fd0034f11ccba8a157fe8f6c62e12ed4bd5470337f583faae84e74f685ce'
]

proof1:
[
  '0x5c848672bdfb30f736d21a5af290c6d10419b8b09237db7a055d32cce6c7dce0'
]

   
在remix作为合约参数的正确格式：  

["0xa378fd0034f11ccba8a157fe8f6c62e12ed4bd5470337f583faae84e74f685ce"]

*/
