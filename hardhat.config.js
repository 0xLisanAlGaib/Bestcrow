module.exports = {
  // ... other config options ...
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  paths: {
    // ... other paths ...
    '@openzeppelin/': './node_modules/@openzeppelin/'
  },
}; 