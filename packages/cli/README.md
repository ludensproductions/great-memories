A command-line interface for interfacing with the self-hosted photo manager [Great Memories](https://immich.app/).

Please see the Great Memories CLI documentation (`docs/docs/features/command-line-interface.md` in this repository).

# For developers

Before building the CLI, you must build the Great Memories server and the OpenAPI client. You can use the following command:

    $ mise //:open-api

## Run from build

Go to the cli folder and build it:

    $ pnpm install
    $ pnpm run build
    $ node dist/index.js

## Run and Debug from source (VSCode)

With VScode you can run and debug the Great Memories CLI. Go to the launch.json file, find the Great Memories CLI config and change this with the command you need to debug

`"args": ["upload", "--help"],`

replace that for the command of your choice.

## Install from build

You can also build and install the CLI using

    $ pnpm run build
    $ pnpm install -g .
****
