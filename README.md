<div align="center">

# 🏦 DBank

**A decentralized banking dApp running 100% on-chain on the Internet Computer Protocol (ICP).**

Top up, withdraw and watch your balance grow with on-chain compound interest — no bank, no server, no middleman.

[![Internet Computer](https://img.shields.io/badge/Internet%20Computer-ICP-29ABE2?logo=internetcomputer&logoColor=white)](https://internetcomputer.org/)
[![Motoko](https://img.shields.io/badge/Backend-Motoko-6E4AFF)](https://internetcomputer.org/docs/current/motoko/main/motoko)
[![Vite](https://img.shields.io/badge/Frontend-Vite%204-646CFF?logo=vite&logoColor=white)](https://vitejs.dev/)
[![React](https://img.shields.io/badge/Scaffold-React%2018-61DAFB?logo=react&logoColor=black)](https://react.dev/)
[![Vitest](https://img.shields.io/badge/Tests-Vitest-6E9F18?logo=vitest&logoColor=white)](https://vitest.dev/)
[![DFX](https://img.shields.io/badge/dfx-0.31.0-2F2F2F)](https://internetcomputer.org/docs/current/developer-docs/setup/install)
[![License](https://img.shields.io/badge/License-MIT-blue)](#-license--credits)

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Canister API (Candid)](#-canister-api-candid)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Day-to-Day Development Workflow](#-day-to-day-development-workflow)
- [Calling the Backend from the Terminal](#-calling-the-backend-from-the-terminal)
- [How the Interest Math Works](#-how-the-interest-math-works)
- [Testing](#-testing)
- [Production Build](#-production-build)
- [Deploying to Mainnet](#-deploying-to-mainnet)
- [Configuration Reference](#-configuration-reference)
- [Troubleshooting](#-troubleshooting)
- [Known Limitations & Roadmap](#-known-limitations--roadmap)
- [Verified End-to-End Run](#-verified-end-to-end-run)
- [License & Credits](#-license--credits)

---

## 🔎 Overview

DBank is a small but complete **full-stack Web3 application** built on the [Internet Computer](https://internetcomputer.org/).

It is intentionally minimal — the point of the project is to demonstrate the full dApp lifecycle rather than banking regulation:

| Layer | What it does |
| --- | --- |
| **Backend canister** (`dbank_backend`) | A [Motoko](https://internetcomputer.org/docs/current/motoko/main/motoko) **persistent actor** that owns the account balance and the banking rules (`topUp`, `withdraw`, `checkBalance`, `compoundDaily`). All state lives in the canister, replicated by IC consensus. |
| **Frontend canister** (`dbank_frontend`) | A static **asset canister** hosting the built HTML/CSS/JS bundle. It is served by the IC itself — no web server, no CDN, no DNS to manage. |
| **Agent / bindings** | Auto-generated [Candid](https://internetcomputer.org/docs/current/developer-docs/backend/candid/candid-concepts) bindings (`dfx generate`) let the browser talk to the backend canister through `@icp-sdk/core` over HTTP. |

Because the balance lives in a canister, the "bank account" is not a row in someone else's database: it is replicated, consensus-backed state that survives upgrades and can only be changed through the canister's public interface.

---

## 🌟 Features

- **Top up** — add funds to the account (`topUp`).
- **Withdraw with overdraft protection** — withdrawals larger than the current balance are rejected on-chain (`withdraw`).
- **Balance query** — read the current balance with a cheap `query` call (`checkBalance`).
- **Compound interest** — 1% per elapsed day, calculated from real `Time.now()` nanoseconds (`compoundDaily`).
- **Fully on-chain** — both the logic and the UI are canisters on the Internet Computer.
- **Internet Identity pre-wired** — the authentication canister is declared in `dfx.json` and ready to be plugged into the UI (see [Roadmap](#-known-limitations--roadmap)).
- **Tested** — Vitest + React Testing Library, runs with `npm test`.
- 🛠️ **Modern tooling** — Vite 4 dev server with HMR, Sass support, generated TypeScript declarations, npm workspaces.

---

## 🧰 Tech Stack

| Area | Technology | Version used in this repo |
| --- | --- | --- |
| Blockchain runtime | Internet Computer (local replica / mainnet) | `dfx 0.31.0` |
| Backend language | Motoko (`mo:base/Time`, `Float`, `Int`, `Nat`, `Debug`) | `persistent actor` |
| Frontend | Vanilla JS + HTML, bundled by Vite | Vite `4.5.x` |
| Canister bindings | `dfx generate` → `@icp-sdk/core` (`agent`, `principal`, `candid`) | `^6.1.0` |
| React scaffold | React 18 + `@vitejs/plugin-react` (template + tests) | `^18.2.0` |
| Styling | `Assets/main.css` (real UI) + `src/index.scss` (React scaffold) | Sass `^1.63.6` |
| Testing | Vitest + `@testing-library/react` + jsdom | Vitest `^2.0.5` |
| Package management | npm workspaces (`src/dbank_frontend`) | Node `v25.2.1`, npm `11.7.0` |

---

## 🏗️ Architecture

```
                ┌──────────────────────────── Browser ────────────────────────────┐
                │  Vite bundle (index.html + index.js + Assets/main.css)          │
                │  imports  src/declarations/dbank_backend  (Candid bindings)     │
                └───────────────────────────────┬─────────────────────────────────┘
                                                │  HttpAgent / Candid (IDL)
                                                ▼
        ┌──────── http://<replica>:4943  (local)  |  https://icp0.io (mainnet) ────────┐
        │                                                                             │
        │   dbank_frontend  (asset canister)      dbank_backend  (Motoko canister)    │
        │   ───────────────────────────────       ────────────────────────────────    │
        │   serves dist/index.html, JS, CSS       var currentValue : Float (= 300.0)  │
        │   (source = src/dbank_frontend/dist)    var startTime    : Int (Time.now()) │
        │                                         topUp / withdraw / checkBalance /   │
        │                                         compoundDaily                       │
        │                                                                             │
        │   internet_identity (declared in dfx.json) ▶ ready for sign-in, not wired   │
        │                                                                             │
        └─────────────────────────────────────────────────────────────────────────────┘
```

**Data flow of a transaction**

1. The user submits the form in `index.js`.
2. `await dbank_backend.topUp(amount)` → Candid-encoded call → `topUp` on the backend canister.
3. The canister mutates `currentValue` (the state change goes through consensus and is certified).
4. `await dbank_backend.compoundDaily()` applies the interest for the elapsed days.
5. `checkBalance()` (a `query` call, answered without consensus) re-renders the balance in the DOM.

> `topUp`, `withdraw` and `compoundDaily` are declared in Motoko without a return value, so Candid exposes them as **`oneway`** calls (fire-and-forget). `checkBalance` is a **`query`**. See [Known Limitations](#-known-limitations--roadmap) for the read-after-write nuance.

---

## 🔌 Canister API (Candid)

`src/dbank_backend/main.mo` and the generated Candid interface (`src/declarations/dbank_backend/dbank_backend.did`):

```candid
service : {
  checkBalance: () -> (float64) query;      // read the balance (query, no consensus)
  topUp: (amount: float64) -> () oneway;    // deposit funds
  withdraw: (amount: float64) -> () oneway; // withdraw, rejected if the balance would go negative
  compoundDaily: () -> () oneway;           // apply 1% interest per elapsed whole day
}
```

| Method | Type | Argument | Returns | Behaviour |
| --- | --- | --- | --- | --- |
| `checkBalance` | `query` | — | `float64` | Returns `currentValue`. Cheap: no mutation, no consensus round. |
| `topUp` | `oneway` | `amount: float64` | — | `currentValue += amount`, then logs the new value with `Debug.print`. |
| `withdraw` | `oneway` | `amount: float64` | — | Applies only if `currentValue - amount >= 0.0`; otherwise logs `"Insufficient funds"` and leaves the balance untouched. |
| `compoundDaily` | `oneway` | — | — | `currentValue *= 1.01 ^ daysElapsed`, then resets `startTime`. |

Motoko source of truth:

```motoko
persistent actor Dbank {
  var currentValue : Float = 300.0;      // starting balance of the demo account
  var startTime    = Time.now();         // last compounding timestamp (ns)

  public func topUp(amount : Float) { currentValue += amount; };

  public func withdraw(amount : Float) {
    let tempValue : Float = currentValue - amount;
    if (tempValue >= 0.0) { currentValue -= amount; }
    else { Debug.print("Insufficient funds"); }
  };

  public query func checkBalance() : async Float { return currentValue; };

  public func compoundDaily() {
    let timeElapsedDays = (Time.now() - startTime) / (86_400 * 1_000_000_000);
    currentValue := currentValue * (1.01 ** Float.fromInt(timeElapsedDays));
    startTime := Time.now();
  };
}
```

---

## 📁 Project Structure

```
dbank/
├── dfx.json                       # Canister definitions (backend, frontend, internet_identity)
├── package.json                   # npm workspace root + aggregate build/test/start scripts
├── package-lock.json              # Locked dependency tree
├── tsconfig.json                  # Root TS config from the dfx template
├── .env                           # GENERATED by dfx: canister IDs + network (git-ignored)
├── .dfx/                          # GENERATED: local replica state, wasm + candid artefacts (git-ignored)
├── README.md                      # <- you are here
└── src/
    ├── dbank_backend/
    │   └── main.mo                # The entire on-chain banking logic (Motoko)
    ├── dbank_frontend/            # The dApp UI (an npm workspace)
    │   ├── index.html             # Entry HTML served by the asset canister
    │   ├── index.js               # UI logic: form -> canister calls -> balance render
    │   ├── Assets/
    │   │   ├── dbank_logo.png     # Logo shown in the UI
    │   │   └── main.css           # Real UI styling
    │   ├── public/                # Static passthrough files (favicon, logo, .ic-assets.json5)
    │   ├── src/                   # React template leftovers + tests
    │   │   ├── App.jsx            # dfx React sample component (not served by index.html)
    │   │   ├── main.jsx           # Sample React entry point
    │   │   ├── index.scss         # Styles for the sample component
    │   │   ├── setupTests.js      # jest-dom matchers for Vitest
    │   │   ├── vite-env.d.ts      # Vite ambient types
    │   │   └── tests/App.test.jsx # Vitest smoke test with inline snapshot
    │   ├── dist/                  # GENERATED: production build uploaded to the asset canister
    │   ├── package.json           # Frontend deps + scripts (start/build/test/setup/prebuild)
    │   ├── tsconfig.json          # Frontend TS config
    │   └── vite.config.js         # Vite config: port 3000, /api proxy, env injection, test setup
    └── declarations/              # GENERATED by `dfx generate` (git-ignored)
        ├── dbank_backend/         # Candid + JS/TS bindings used by the frontend
        ├── dbank_frontend/        # Asset canister bindings
        └── internet_identity/     # Internet Identity bindings
```

**Two things you should know before you start**

1. `src/declarations/**` and `.dfx/**` are **generated and git-ignored**. A fresh clone has neither - they appear the first time you run `dfx generate` or `dfx deploy`.
2. `.env` is **generated by dfx** (`"output_env_file": ".env"` in `dfx.json`). The frontend build bakes the canister IDs in from that file, so it must exist *before* the frontend is built.

---

## 🚀 Prerequisites

| Tool | Minimum | Verified here | Install |
| --- | --- | --- | --- |
| **DFX SDK** | `0.15.0` | `0.31.0` | `sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"` |
| **Node.js** | `16.0.0` (`engines` in root `package.json`) | `v25.2.1` | https://nodejs.org / `nvm install --lts` |
| **npm** | `7.0.0` | `11.7.0` | ships with Node |
| **A browser** | modern Chrome/Firefox/Safari | — | needed to open the frontend canister URL |

Check everything before you start:

```bash
dfx --version    # dfx 0.31.0
node --version   # v25.2.1
npm --version    # 11.7.0
```

---

## ⚡ Quick Start

From the repository root (`/home/nyanj/ic-projects/dbank`):

```bash
# 1. Install JS dependencies for the workspace (root + src/dbank_frontend)
npm install

# 2. Start the local IC replica in the background (listens on 127.0.0.1:4943)
dfx start --background

# 3. Reserve canister IDs for this project on the local network
#    -> creates .dfx/local/canister_ids.json and writes .env
dfx canister create --all

# 4. Build the Motoko backend, generate Candid bindings, build + upload the frontend
dfx deploy dbank_backend
dfx deploy dbank_frontend
```

Then open the dApp:

```
http://<CANISTER_ID_DBANK_FRONTEND>.localhost:4943/
```

Get the exact URL any time with `dfx deploy` output or:

```bash
echo "http://$(dfx canister id dbank_frontend).localhost:4943/"
```

> **Tip:** `dfx deploy` with no canister name deploys everything, but it *also* tries to install `internet_identity`. On some replica versions that fails with an `ic0` import error (see [Troubleshooting](#-troubleshooting)). Installing the two DBank canisters by name, as above, is the reliable path.

### One-liner (scripted) setup

`src/dbank_frontend/package.json` ships a `setup` script that chains the whole first run:

```bash
cd src/dbank_frontend
npm run setup
# == npm i && dfx canister create dbank_backend && dfx generate dbank_backend && dfx deploy
```

Note it creates only `dbank_backend` first; run `dfx canister create dbank_frontend` too if you want to use the deploy-by-name workflow, or simply run `dfx canister create --all` as in the Quick Start.

---

## 🔁 Day-to-Day Development Workflow

### 1. Replica lifecycle

```bash
dfx start --background          # start the local replica (port 4943)
dfx start --background --clean  # same, but wipe all local canister state
dfx ping local                  # sanity check: replica is reachable
dfx stop                        # stop the replica
```

The replica keeps canister state between restarts, so your balance survives `dfx stop` / `dfx start` — use `--clean` when you want the balance back at `300.0`.

### 2. Backend iteration (Motoko)

Edit `src/dbank_backend/main.mo`, then:

```bash
dfx deploy dbank_backend        # recompile Motoko + upgrade the canister
dfx canister call dbank_backend checkBalance
```

`dfx deploy` uses `mode = auto`: the first run installs, later runs **upgrade** — so `currentValue` and `startTime` are preserved unless you pass `--mode reinstall`.

### 3. Frontend iteration (hot reload)

```bash
cd src/dbank_frontend
npm start                       # Vite dev server on http://localhost:3000
```

* Vite serves `index.html` + `index.js` with instant HMR. `vite.config.js` proxies `/api` to the replica at `http://127.0.0.1:4943`.
* Canister IDs and `DFX_NETWORK` come from the root `.env`, loaded by `dotenv` and injected by `vite-plugin-environment` (`CANISTER_*` / `DFX_*` prefixes).
* Keep `dfx start` running in another terminal, otherwise the agent logs `Unable to fetch root key. Check to ensure that your local replica is running`.

### 4. Publish the real frontend canister

When you want to see the app exactly as the IC serves it (not through Vite):

```bash
dfx deploy dbank_frontend       # runs `npm run build` for the workspace, then uploads dist/
```

That single command is the full frontend pipeline:

| Step | Command | Result |
| --- | --- | --- |
| 1 | `prebuild`: `dfx generate` | regenerates `src/declarations/**` from the canisters' `.did` files |
| 2 | `build`: `tsc && vite build` | type-checks and emits `src/dbank_frontend/dist/` |
| 3 | dfx asset upload | uploads `dist/` (the canister's `source`) to the asset canister |

Useful flags:

```bash
dfx deploy dbank_frontend --yes              # auto-confirm prompts (good for scripts/CI)
dfx deploy dbank_frontend --mode reinstall   # wipe canister state, install fresh
```

### 5. Inspect what is running

```bash
dfx canister id dbank_backend        # -> e.g. uxrrr-q7777-77774-qaaaq-cai
dfx canister id dbank_frontend       # -> e.g. u6s2n-gx777-77774-qaaba-cai
dfx canister status dbank_backend    # cycles, memory, controllers
```

The Candid web UI is served by the replica too; the URL is printed at the end of every `dfx deploy` (it gives you a form to click through `topUp`, `withdraw`, `checkBalance`, `compoundDaily`).

---

## 💻 Calling the Backend from the Terminal

All amounts are `float64`, so **always pass the argument as a Candid tuple** — a bare `50` is rejected with `type mismatch: 50 can not be of type float64`:

```bash
# Read the balance (query)
dfx canister call dbank_backend checkBalance
# (300.0 : float64)

# Deposit 50 (note the float syntax and the parentheses)
dfx canister call dbank_backend topUp '(50.0)'
dfx canister call dbank_backend checkBalance
# (350.0 : float64)

# Withdraw 20.5
dfx canister call dbank_backend withdraw '(20.5)'
dfx canister call dbank_backend checkBalance
# (329.5 : float64)

# Overdraft attempt: ignored, balance unchanged ("Insufficient funds" is logged in the replica)
dfx canister call dbank_backend withdraw '(100000.0)'
dfx canister call dbank_backend checkBalance
# (329.5 : float64)

# Apply compound interest for the elapsed whole days (0 on the same day)
dfx canister call dbank_backend compoundDaily
```

More variations:

```bash
# Machine-readable output
dfx canister call dbank_backend checkBalance --output json

# Different network / identity
dfx canister call dbank_backend checkBalance --network ic --identity <your-identity>
```

Because `topUp`, `withdraw` and `compoundDaily` are `oneway`, `dfx` prints `()` and never reports success/failure — always read the value back with `checkBalance`.

---

## 📈 How the Interest Math Works

`compoundDaily()` implements 1% **per elapsed whole day**, compounded, using the canister's own clock (`Time.now()` returns nanoseconds on the IC — the canister has no access to a wall clock other than this):

```
elapsedDays  = (Time.now() - startTime) / 86_400_000_000_000   // integer division (whole days)
currentValue = currentValue * (1.01 ^ elapsedDays)
startTime    = Time.now()
```

Worked example, starting from `300.0`:

| Elapsed | Days | Calculation | Balance |
| --- | --- | --- | --- |
| 0 h | 0 | `300 * 1.01^0` | `300.0` |
| 24 h | 1 | `300 * 1.01` | `303.0` |
| 48 h | 2 | `300 * 1.01^2` | `303.03` |
| 72 h | 3 | `300 * 1.01^3` | `306.06` |
| 10 days | 10 | `300 * 1.01^10` | `331.39` |

Two subtleties worth knowing:

1. **Partial days are dropped.** The division is integer division (`Int`), so 23 h of interest becomes 0 days.
2. **The remainder is not carried over.** `startTime` is set to *now* rather than to `startTime + days * day`, so those leftover hours are lost on every call. Calling `compoundDaily` in a tight loop therefore never compounds anything — you must wait a full day (or restart the replica with `--clean` and call it after the elapsed period). Fixing this is listed in the [Roadmap](#-known-limitations--roadmap).

---

## 🧪 Testing

```bash
npm test                    # from the repo root (runs the workspace test script)
```

`npm test` triggers `pretest` → `prebuild` → `dfx generate` (so the Candid bindings exist), then runs `vitest run` in `src/dbank_frontend`:

```
 ✓ src/tests/App.test.jsx (1 test) 47ms
 Test Files  1 passed (1)
      Tests  1 passed (1)
```

| Piece | Purpose |
| --- | --- |
| `src/tests/App.test.jsx` | Renders the React sample component inside `StrictMode` and asserts an inline DOM snapshot. |
| `src/setupTests.js` | Adds `@testing-library/jest-dom` matchers and a `cross-fetch` polyfill. |
| `vite.config.js` → `test` | Uses the `jsdom` environment and loads `src/setupTests.js`. |

Useful variants (run them inside `src/dbank_frontend`):

```bash
npm test -- --watch        # re-run on change
npm test -- --coverage     # coverage report (needs @vitest/coverage-v8)
npm test -- -u             # update the inline snapshot after intentional UI changes
```

> The test suite currently covers the React template only — the Motoko canister is validated through `dfx canister call` (see above) rather than unit tests.

---

## 📦 Production Build

```bash
npm run build               # root: runs prebuild + build for every workspace
```

That produces the static bundle in `src/dbank_frontend/dist/`:

```
dist/index.html                        0.94 kB │ gzip:  0.51 kB
dist/assets/dbank_logo-7194150f.png   35.90 kB
dist/assets/index-2c0839d6.css         1.64 kB │ gzip:  0.75 kB
dist/assets/index-536b4ac1.js        206.63 kB │ gzip: 67.21 kB
```

The output is what the `dbank_frontend` asset canister serves, and the backend canister ID is baked into `index-*.js` at build time (taken from `.env`) — so **rebuild after every redeploy** that changes canister IDs.

---

## 🌐 Deploying to Mainnet

> Everything in this section is **guidance** — the local flow above is what was executed and verified in this repo. Mainnet deploys cost cycles, and the identity used here (`andre-mainnet`) is passphrase-encrypted, so it cannot be unlocked from a non-interactive shell.

**1. Pick an identity and make sure it is funded with cycles**

```bash
dfx identity list                 # default, andre-mainnet, andre-wallet, anonymous
dfx identity use andre-mainnet    # will prompt for the identity passphrase
dfx identity get-principal        # give this to whoever sends you cycles

dfx wallet --network ic balance   # cycles available to the identity's wallet
dfx ledger --network ic balance   # ICP balance
```

If the identity has ICP but no cycles, create a cycles wallet:

```bash
dfx ledger --network ic create-canister $(dfx identity get-principal) --amount 1.0
dfx identity --network ic deploy-wallet <wallet-canister-id>
```

**2. Create the canisters on mainnet (once)**

```bash
dfx canister create --network ic dbank_backend --with-cycles 1000000000000
dfx canister create --network ic dbank_frontend --with-cycles 1000000000000
```

This writes `.dfx/ic/canister_ids.json`. Commit that file (or add it to version control manually) so the IDs are not lost.

**3. Deploy**

```bash
dfx deploy --network ic dbank_backend
dfx deploy --network ic dbank_frontend
```

`dfx` sets `DFX_NETWORK=ic` for the frontend build, which makes `dfx generate` emit bindings that **skip `agent.fetchRootKey()`** (root-key fetching is a local-replica-only step), and bakes the mainnet canister IDs into the bundle.

Do **not** deploy `internet_identity` to mainnet: `dfx.json` declares it as `remote` with the mainnet ID `rdmx6-jaaaa-aaaaa-aaadq-cai`, so the real Internet Identity is reused.

**4. Reach the app**

```
https://<CANISTER_ID_DBANK_FRONTEND>.icp0.io/
```

`https://<id>.raw.icp0.io/` bypasses the HTTP gateway cache — useful right after a deploy (see `public/.ic-assets.json5`, where raw access and the security-policy warning are configured).

**5. Managing the deployment**

```bash
dfx canister status --network ic dbank_backend
dfx canister deposit-cycles 500000000000 --network ic dbank_backend
dfx canister call --network ic dbank_backend checkBalance
```

---

## ⚙️ Configuration Reference

### `dfx.json`

```jsonc
{
  "canisters": {
    "dbank_backend":  { "main": "src/dbank_backend/main.mo", "type": "motoko" },
    "dbank_frontend": {
      "dependencies": ["dbank_backend"],          // build backend first
      "source": ["src/dbank_frontend/dist"],      // assets uploaded to the IC
      "type": "assets",
      "workspace": "dbank_frontend"               // npm workspace whose `build` script runs first
    },
    "internet_identity": {
      "type": "custom",
      "candid": "https://github.com/dfinity/internet-identity/releases/latest/download/internet_identity.did",
      "wasm":   "https://github.com/dfinity/internet-identity/releases/latest/download/internet_identity_dev.wasm.gz",
      "remote": { "id": { "ic": "rdmx6-jaaaa-aaaaa-aaadq-cai" } }   // reuse the real II on mainnet
    }
  },
  "defaults": { "bitcoin": { "enabled": false }, "build": { "args": "", "packtool": "" } },
  "output_env_file": ".env",   // dfx writes canister IDs here on every deploy
  "version": 1
}
```

### Scripts

| Where | Script | What it does |
| --- | --- | --- |
| root `package.json` | `npm install` | installs the workspace (`src/dbank_frontend`) |
| root | `npm start` | `vite --port 3000` inside the workspace |
| root | `npm test` | `prebuild` (dfx generate) + `vitest run` |
| root | `npm run build` | `prebuild` + `tsc && vite build` for the workspace |
| frontend | `npm run prebuild` | `dfx generate` — refreshes `src/declarations/**` |
| frontend | `npm run setup` | `npm i && dfx canister create dbank_backend && dfx generate dbank_backend && dfx deploy` |
| frontend | `npm run format` | `prettier` over `src/**` |

### `vite.config.js` highlights

| Setting | Why it matters |
| --- | --- |
| `dotenv.config({ path: '../../.env' })` | loads the dfx-generated canister IDs from the repo root |
| `environment("all", { prefix: "CANISTER_" })`, `environment("all", { prefix: "DFX_" })` | injects them into the bundle (this is how `process.env.CANISTER_ID_DBANK_BACKEND` resolves in `src/declarations/**`) |
| `resolve.alias` for `"declarations"` | lets `import { dbank_backend } from 'declarations/dbank_backend'` work from `src/` *and* from `index.js` |
| `server.proxy."/api"` → `http://127.0.0.1:4943` | same-origin calls to the replica in dev |
| `test.environment: 'jsdom'`, `setupFiles` | Vitest configuration |

### `.env` (generated)

```
DFX_VERSION='0.31.0'
DFX_NETWORK='local'
CANISTER_ID_DBANK_BACKEND='uxrrr-q7777-77774-qaaaq-cai'
CANISTER_ID_DBANK_FRONTEND='u6s2n-gx777-77774-qaaba-cai'
CANISTER_ID_INTERNET_IDENTITY='uzt4z-lp777-77774-qaabq-cai'
CANISTER_ID='uxrrr-q7777-77774-qaaaq-cai'
CANISTER_CANDID_PATH='/home/nyanj/ic-projects/dbank/.dfx/local/canisters/dbank_backend/dbank_backend.did'
```

Because `.env` and `.dfx/` are git-ignored, local canister IDs are per-machine: two developers will have different IDs, which is expected.

---

## 🧯 Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Error: You are trying to connect to the local replica but dfx cannot connect to it.` | The replica is not running. | `dfx start --background`, then `dfx ping local`. |
| `Error: Cannot find canister id. Please issue 'dfx canister create dbank_backend'.` | IDs were never created for this machine (`.dfx/` is git-ignored). | `dfx canister create --all`. |
| `Unable to fetch root key. Check to ensure that your local replica is running` in the browser console | The frontend was built for a local network while the replica is down (or the opposite). | Start the replica and reload; make sure the build ran with `DFX_NETWORK=local`. |
| Candid error `type mismatch: 50 can not be of type float64` | Argument passed without a tuple / not a float. | Use `dfx canister call dbank_backend topUp '(50.0)'`. |
| `Failed to install wasm module to canister 'internet_identity' ... Module imports function 'msg_caller_info_signer_size' from 'ic0'` | The downloaded `internet_identity_dev.wasm.gz` is newer than the local replica's `ic0` API surface. | Deploy only the DBank canisters by name (`dfx deploy dbank_backend`, `dfx deploy dbank_frontend`), or update `dfx`. Internet Identity is not required by the current UI. |
| `Failed while trying to generate type declarations for 'dbank_frontend'` / `assetstorage.did doesn't exist` (during `npm test` → `prebuild`) | `dfx generate` ran for the asset canister before it had ever been built/deployed. | Deploy the frontend once (`dfx deploy dbank_frontend`); afterwards `dfx generate` finds `assetstorage.did`. |
| `Rollup failed to resolve import "@icp-sdk/core/agent" from "src/declarations/dbank_backend/index.js"` | dfx >= 0.31 generates bindings that import `@icp-sdk/core`, which was missing from `src/dbank_frontend/package.json`. | Fixed in this repo: `@icp-sdk/core@^6.1.0` is a dependency, so a fresh `npm install` picks it up. |
| `Cannot find module '@dfinity/agent'` (browser console) | Bindings produced by an older `dfx generate` import `@dfinity/*`. | Re-run `dfx generate` (dfx 0.31) and rebuild — the current bindings use `@icp-sdk/core`. |
| Balance is not `300.0` after a restart | Replica state persists across restarts. | `dfx start --background --clean` for a pristine state. |
| `Failed to load identity ... Failed to decrypt PEM file ... not a terminal` | The `andre-mainnet` identity is passphrase-encrypted and cannot be unlocked from a non-interactive shell. | Run the identity command in an interactive terminal, or switch to an unencrypted identity (e.g. `default`). |
| Vitest snapshot mismatch in `App.test.jsx` | The React sample component changed. | `npm test -- -u` inside `src/dbank_frontend` after reviewing the diff. |

**Useful diagnostics**

```bash
dfx ping local
dfx canister status dbank_backend
dfx canister call dbank_backend checkBalance
cat .env
ls .dfx/local/canisters
```

---

## 🚧 Known Limitations & Roadmap

This is a learning/demonstration project, so a few deliberately simple choices are worth calling out — each one is a great next contribution:

| # | Limitation | Where | Suggested improvement |
| --- | --- | --- | --- |
| 1 | **One shared balance for everyone.** There is no `Principal`-keyed ledger: every visitor reads and mutates the same `currentValue`. | `main.mo` | Store `HashMap<Principal, Float>` (or a `TrieMap`) and key it by `msg.caller`. |
| 2 | **Writes are `oneway`.** Return values are dropped, so a client cannot tell whether a `topUp` / `withdraw` succeeded, and the `checkBalance()` that follows can race the state change. | `main.mo`, `index.js` | Return a result type (`Result.Result<Float, Text>`) from the update methods and `await` it before re-reading. |
| 3 | **Failed withdrawals are silent.** An overdraft attempt only prints `"Insufficient funds"` to the canister log. | `withdraw` | Return an explicit `#Err(#InsufficientFunds)` / `throw` and surface it in the UI. |
| 4 | **Interest loses the partial-day remainder.** `startTime` is reset to `now`, so sub-day time is discarded instead of carried forward. | `compoundDaily` | Advance `startTime` by exactly `days * NS_PER_DAY` rather than to `Time.now()`. |
| 5 | **Interest is manual.** Somebody must call `compoundDaily`; nothing schedules it. | — | Use a Motoko timer (`Timer.setTimer` / `recurringTimer`) or a heartbeat to compound automatically. |
| 6 | **No authentication in the UI.** Internet Identity is declared in `dfx.json` but no sign-in flow is wired up. | `dfx.json`, `index.js` | Add an auth-client login button and pass the returned `Identity` into the `HttpAgent`. |
| 7 | **`Float` money.** Floating-point balances are unsuitable for real value and can drift. | `main.mo` | Model money in `Nat` base units (e.g. cents) or follow the ICRC ledger standard. |
| 8 | **Two frontends coexist.** `index.html` + `index.js` are the real DBank UI; the React scaffold (`src/App.jsx`, `main.jsx`, `index.scss`) is leftover dfx template code and is never served. | `src/dbank_frontend` | Delete the scaffold (and its test), or rebuild the DBank UI in React. |
| 9 | **No backend unit tests or cycles monitoring.** Validation is manual via `dfx canister call`. | repo-wide | Add a Motoko test harness and a cycles/balance alert. |

---

## ✅ Verified End-to-End Run

Everything below was executed in this workspace with `dfx 0.31.0`, `node v25.2.1`, `npm 11.7.0`.

| Step | Command | Result |
| --- | --- | --- |
| Start replica | `dfx start --background` | `Replica API running in the background on 127.0.0.1:4943` |
| Create canisters | `dfx canister create --all` | backend `uxrrr-q7777-77774-qaaaq-cai`, frontend `u6s2n-gx777-77774-qaaba-cai`, II `uzt4z-lp777-77774-qaabq-cai` |
| Deploy backend | `dfx deploy dbank_backend` | `Installed code for canister dbank_backend` |
| Deploy frontend | `dfx deploy dbank_frontend` | `Upgraded code for canister dbank_frontend` (asset-security warnings only) |
| Query | `dfx canister call dbank_backend checkBalance` | `(300.0 : float64)` |
| Top up | `dfx canister call dbank_backend topUp '(50.0)'` | `()`, then balance `(350.0 : float64)` |
| Withdraw | `dfx canister call dbank_backend withdraw '(20.5)'` | `()`, then balance `(329.5 : float64)` |
| Overdraft guard | `dfx canister call dbank_backend withdraw '(100000.0)'` | Balance unchanged at `(329.5 : float64)` |
| Interest | `dfx canister call dbank_backend compoundDaily` | `()` — 0 whole days elapsed, balance stays `329.5` |
| Frontend over HTTP | `curl -s -o /dev/null -w '%{http_code}' http://u6s2n-gx777-77774-qaaba-cai.localhost:4943/` | `200` (assets `/assets/index-*.js` and `/logo2.svg` are `200` too) |
| Tests | `npm test` | `Test Files 1 passed (1)`, `Tests 1 passed (1)` |
| Production build | `npm run build` | `built in 2.12s` → `dist/assets/index-536b4ac1.js  206.63 kB` |

Reproduce the whole thing:

```bash
npm install
dfx start --background
dfx canister create --all
dfx deploy dbank_backend
dfx deploy dbank_frontend
npm test
npm run build
dfx canister call dbank_backend checkBalance
```

Want the pristine `300.0` starting balance back? `dfx stop && dfx start --background --clean`, then redeploy.

---

## 📄 License & Credits

Released under the **MIT License** — see the repository for details.

* **Motoko backend, UI and project wiring:** built on the `dfx` "hello world" template, then extended step by step (see `git log`) into a banking canister.
* [DFINITY Foundation](https://dfinity.org/) — the Internet Computer, Motoko and Internet Identity.
* [DFINITY examples](https://internetcomputer.org/docs/current/developer-docs/) — the asset-canister and `dfx.json` patterns used here.
* React / Vite / Vitest — the JS toolchain that ships with the template.

### Documentation

* [Deploying locally](https://internetcomputer.org/docs/current/developer-docs/setup/deploy-locally)
* [Motoko language guide](https://internetcomputer.org/docs/current/motoko/main/motoko)
* [Candid interface description language](https://internetcomputer.org/docs/current/developer-docs/backend/candid/candid-concepts)
* [`dfx` CLI reference](https://internetcomputer.org/docs/current/developer-docs/developer-tools/cli-tools/cli-reference/dfx-canister)
* [Internet Identity](https://internetcomputer.org/internet-identity)
* [Vite](https://vitejs.dev/) · [Vitest](https://vitest.dev/)

<div align="center">

**Built with Motoko + the Internet Computer. No servers were harmed in the making of this dApp.** 🏦

</div>
