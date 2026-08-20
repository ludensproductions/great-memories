# @great-memories/sdk

A TypeScript SDK for interfacing with the [Great Memories](https://immich.app/) API.

## Install

```bash
npm i --save @great-memories/sdk
```

## Usage

For a more detailed example, check out the Great Memories CLI source in this repository.

```typescript
import { getAllAlbums, getMyUser, init } from "@great-memories/sdk";

const API_KEY = "<API_KEY>"; // process.env.GREAT_MEMORIES_API_KEY

init({ baseUrl: "https://demo.immich.app/api", apiKey: API_KEY });

const user = await getMyUser();
const albums = await getAllAlbums({});

console.log({ user, albums });
```
