## Setup

1. Install dependencies:
   ```
   yarn install
   ```
   or
   ```
   npm install
   ```

## Building the Contract

To build the smart contract (this compiles Tact to FunC, then to Fift, and finally to a cell (BOC) file):

```
npx blueprint build
```

or

```
yarn blueprint build
```

## Testing

Run the test suite with:

```
npx blueprint test
```

or

```
yarn blueprint test
```

## Deployment

To deploy the Zkme Sbt:



```
npx blueprint run deployNftCollection
```

The script will output the deployed collection address and the address of the first minted NFT.
