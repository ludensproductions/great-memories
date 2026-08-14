# The Great Memories CLI

Great Memories has a command line interface (CLI) that allows you to perform certain actions from the command line.

## Features

- Upload photos and videos to Great Memories
- Check server version

More features are planned for the future.

:::tip Google Photos Takeout
If you are looking to import your Google Photos takeout, we recommend this community maintained tool [great-memories-go](https://github.com/simulot/great-memories-go)
:::

## Requirements

- Node.js 20 or above
- Npm

If you can't install node/npm, there is also a Docker version available below.

## Installation (NPM)

```bash
npm i -g @immich/cli
```

NOTE: if you previously installed the legacy CLI, you will need to uninstall it first:

```bash
npm uninstall -g great-memories
```

## Installation (Docker)

If npm is not available on your system you can try the Docker version

```bash
docker run -it -v "$(pwd)":/import:ro -e GREAT_MEMORIES_INSTANCE_URL=https://your-great-memories-instance/api -e GREAT_MEMORIES_API_KEY=your-api-key ghcr.io/immich-app/immich-cli:latest
```

Please modify the `GREAT_MEMORIES_INSTANCE_URL` and `GREAT_MEMORIES_API_KEY` environment variables as suitable. You can also use a Docker env file to store your sensitive API key.

This `docker run` command will directly run the command `great-memories` inside the container. You can directly append the desired parameters (see under "usage") to the commandline like this:

```bash
docker run -it -v "$(pwd)":/import:ro -e GREAT_MEMORIES_INSTANCE_URL=https://your-great-memories-instance/api -e GREAT_MEMORIES_API_KEY=your-api-key ghcr.io/immich-app/immich-cli:latest upload -a -c 5 --recursive directory/
```

## Usage

<details>
<summary>Usage</summary>

```
$ great-memories
Usage: great-memories [options] [command]

Command line interface for Great Memories

Options:
  -V, --version                       output the version number
  -d, --config-directory <directory>  Configuration directory where auth.yml will be stored (default: "~/.config/great-memories/", env:
                                      GREAT_MEMORIES_CONFIG_DIR)
  -u, --url [url]                     Great Memories server URL (env: GREAT_MEMORIES_INSTANCE_URL)
  -k, --key [key]                     Great Memories API key (env: GREAT_MEMORIES_API_KEY)
  -h, --help                          display help for command

Commands:
  login|login-key <url> <key>         Login using an API key
  logout                              Remove stored credentials
  server-info                         Display server information
  upload [options] [paths...]         Upload assets
  help [command]                      display help for command
```

</details>

## Commands

The upload command supports the following options:

<details>
<summary>Options</summary>

```
Usage: great-memories upload [paths...] [options]

Upload assets

Arguments:
  paths                       One or more paths to assets to be uploaded

Options:
  -r, --recursive             Recursive (default: false, env: GREAT_MEMORIES_RECURSIVE)
  -i, --ignore <pattern>      Pattern to ignore (env: GREAT_MEMORIES_IGNORE_PATHS)
  -h, --skip-hash             Don't hash files before upload (default: false, env: GREAT_MEMORIES_SKIP_HASH)
  -H, --include-hidden        Include hidden folders (default: false, env: GREAT_MEMORIES_INCLUDE_HIDDEN)
  -a, --album                 Automatically create albums based on folder name (default: false, env: GREAT_MEMORIES_AUTO_CREATE_ALBUM)
  -A, --album-name <name>     Add all assets to specified album (env: GREAT_MEMORIES_ALBUM_NAME)
  --visibility <visibility>   Set the visibility of uploaded assets (choices: "archive", "timeline", "hidden", "locked", env: GREAT_MEMORIES_VISIBILITY)
  -n, --dry-run               Don't perform any actions, just show what will be done (default: false, env: GREAT_MEMORIES_DRY_RUN)
  -c, --concurrency <number>  Number of assets to upload at the same time (default: 4, env: GREAT_MEMORIES_UPLOAD_CONCURRENCY)
  -j, --json-output           Output detailed information in json format (default: false, env: GREAT_MEMORIES_JSON_OUTPUT)
  --delete                    Delete local assets after upload (env: GREAT_MEMORIES_DELETE_ASSETS)
  --delete-duplicates         Delete local assets that are duplicates (already exist on server) (env: GREAT_MEMORIES_DELETE_DUPLICATES)
  --no-progress               Hide progress bars (env: GREAT_MEMORIES_PROGRESS_BAR)
  --watch                     Watch for changes and upload automatically (default: false, env: GREAT_MEMORIES_WATCH_CHANGES)
  --help                      display help for command
```

</details>

Note that the above options can read from environment variables as well.

## Quick Start

You begin by authenticating to your Great Memories server. For instance:

```bash
# great-memories login [url] [key]
great-memories login http://192.168.1.216:2283/api HFEJ38DNSDUEG
```

This will store your credentials in a `auth.yml` file in the configuration directory which defaults to `~/.config/great-memories/`. The directory can be set with the `-d` option or the environment variable `GREAT_MEMORIES_CONFIG_DIR`. Please keep the file secure, either by performing the logout command after you are done, or deleting it manually.

Once you are authenticated, you can upload assets to your Great Memories server.

```bash
great-memories upload file1.jpg file2.jpg
```

By default, subfolders are not included. To upload a directory including subfolder, use the --recursive option:

```bash
great-memories upload --recursive directory/
```

If you are unsure what will happen, you can use the `--dry-run` option to see what would happen without actually performing any actions.

```bash
great-memories upload --dry-run --recursive directory/
```

By default, the upload command will hash the files before uploading them. This is to avoid uploading the same file multiple times. If you are sure that the files are unique, you can skip this step by passing the `--skip-hash` option. Note that Great Memories always performs its own deduplication through hashing, so this is merely a performance consideration. If you have good bandwidth it might be faster to skip hashing.

```bash
great-memories upload --skip-hash --recursive directory/
```

You can automatically create albums based on the folder name by passing the `--album` option. This will automatically create albums for each uploaded asset based on the name of the folder they are in.

```bash
great-memories upload --album --recursive directory/
```

You can also choose to upload all assets to a specific album with the `--album-name` option.

```bash
great-memories upload --album-name "My summer holiday" --recursive directory/
```

It is possible to skip assets matching a glob pattern by passing the `--ignore` option. See [the library documentation](docs/features/libraries.md) on how to use glob patterns. You can add several exclusion patterns if needed.

```bash
great-memories upload --ignore **/Raw/** --recursive directory/
```

```bash
great-memories upload --ignore **/Raw/** **/*.tif --recursive directory/
```

By default, hidden files are skipped. If you want to include hidden files, use the `--include-hidden` option:

```bash
great-memories upload --include-hidden --recursive directory/
```

You can set the visibility of uploaded assets to `archive`, `timeline`, `hidden`, or `locked` with the `--visibility` option:

```bash
great-memories upload --visibility archive --recursive directory/
```

You can use the `--json-output` option to get a json printed which includes
three keys: `newFiles`, `duplicates` and `newAssets`. Due to some logging
output you will need to strip the first three lines of output to get the json.
For example to get a list of files that would be uploaded for further
processing:

```bash
great-memories upload --dry-run --json-output . | tail -n +6 | jq .newFiles[]
```

### Obtain the API Key

The API key can be obtained in the user setting panel on the web interface. You can also specify permissions for the key to limit its access.

![Obtain Api Key](./img/obtain-api-key.webp)

![Specify permissions for the key](./img/obtain-api-key-2.webp)
