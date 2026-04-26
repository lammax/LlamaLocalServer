# LlamaLocalServer

Small macOS daemon wrapper for `llama.cpp` `llama-server`.

`llama-server` is already the real HTTP inference server. This project does not reimplement model inference; it runs `llama-server` as a supervised local process with explicit context, output and concurrency limits.

## API

The daemon starts an OpenAI-compatible endpoint:

```text
POST http://127.0.0.1:8080/v1/chat/completions
```

AIChallenge should use:

```text
Base URL: http://127.0.0.1:8080/v1
Model: local-private
API Key: value from LLAMA_API_KEY
```

## Install llama.cpp

```bash
brew install llama.cpp
```

Check:

```bash
which llama-server
llama-server --version
```

## Configure Xcode scheme

Set these environment variables in the `LlamaLocalServer` scheme:

```text
LLAMA_SERVER_BIN=/opt/homebrew/bin/llama-server
LLAMA_MODEL_PATH=/Users/.../Models/qwen2.5-0.5b-instruct-q4_k_m.gguf
LLAMA_HOST=127.0.0.1
LLAMA_PORT=8080
LLAMA_API_KEY=change-me
LLAMA_MODEL_ALIAS=local-private
LLAMA_CTX_SIZE=16384
LLAMA_PARALLEL=2
LLAMA_N_PREDICT=2048
LLAMA_THREADS=-1
LLAMA_RESTART_DELAY_SECONDS=3
```

Context is shared across parallel slots. Example: `LLAMA_CTX_SIZE=16384` and `LLAMA_PARALLEL=2` gives roughly two 8192-token request slots.

## Manual Smoke Test

```bash
curl http://127.0.0.1:8080/v1/chat/completions \
  -H "Authorization: Bearer $LLAMA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"local-private","messages":[{"role":"user","content":"Say hello"}],"max_tokens":64}'
```

## launchd

Use the helper scripts:

```bash
./start-daemon.sh
./listen-daemon.sh
./stop-daemon.sh
```

Or run the launchd steps manually. Build the command line tool with a stable local build path, then copy `local.aichallenge.llama-server.plist` to `~/Library/LaunchAgents`.

```bash
xcodebuild build -project LlamaLocalServer.xcodeproj -scheme LlamaLocalServer -configuration Release -derivedDataPath build
```

```bash
mkdir -p "$HOME/Library/Logs/LlamaLocalServer"
cp local.aichallenge.llama-server.plist "$HOME/Library/LaunchAgents/"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/local.aichallenge.llama-server.plist"
launchctl enable "gui/$(id -u)/local.aichallenge.llama-server"
launchctl kickstart -k "gui/$(id -u)/local.aichallenge.llama-server"
```

Stop:

```bash
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/local.aichallenge.llama-server.plist"
```
