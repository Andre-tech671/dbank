# DBank - Decentralized Banking on the Internet Computer

A simple decentralized banking application built on the [Internet Computer Protocol (ICP)](https://internetcomputer.org/). DBank allows users to manage their funds with features like deposits, withdrawals, balance checking, and automatic compound interest.

## 🌟 Features

- **Deposit Funds**: Add money to your account using the `topUp` function
- **Withdraw Funds**: Withdraw money with balance verification to prevent overdrafts
- **Check Balance**: Query your current account balance at any time
- **Compound Interest**: Automatically calculates and applies 1% compound interest based on time elapsed
- **Decentralized**: Runs entirely on the Internet Computer blockchain
- **Secure**: Integrated with Internet Identity for authentication

## 🏗️ Architecture

### Backend (Motoko)
The backend is written in [Motoko](https://internetcomputer.org/docs/current/motoko/main/motoko), a programming language designed for the Internet Computer. Key components:

- `currentValue`: Persistent stable variable storing the account balance (initialized at 300)
- `startTime`: Tracks the last compounding timestamp
- `topUp(amount)`: Public function to deposit funds
- `withdraw(amount)`: Public function to withdraw funds (validates sufficient balance)
- `checkBalance()`: Query function to retrieve current balance
- `compound()`: Applies 1% interest based on time elapsed since last compounding

### Frontend (React + Vite)
The frontend is built with modern web technologies:

- **React 18**: UI component library
- **Vite**: Fast build tool and development server
- **TypeScript**: Type-safe development
- **SCSS**: Advanced styling capabilities
- **Vitest**: Unit testing framework

## 📁 Project Structure

```
dbank/
├── dfx.json                    # DFX canister configuration
├── package.json                # Root workspace configuration
├── tsconfig.json               # TypeScript configuration
├── src/
│   ├── dbank_backend/
│   │   └── main.mo            # Motoko backend canisters
│   ├── dbank_frontend/
│   │   ├── src/
│   │   │   ├── App.jsx        # Main React application
│   │   │   ├── main.jsx       # Application entry point
│   │   │   ├── index.scss     # Global styles
│   │   │   ├── setupTests.js  # Test setup
│   │   │   ├── tests/         # Test files
│   │   │   └── vite-env.d.ts  # Vite type declarations
│   │   ├── package.json       # Frontend dependencies
│   │   ├── vite.config.js     # Vite configuration
│   │   └── public/            # Static assets
│   └── declarations/          # Generated candid interfaces
```

## 🚀 Getting Started

### Prerequisites

- Node.js >= 16.0.0
- npm >= 7.0.0
- [DFX SDK](https://internetcomputer.org/docs/current/developer-docs/setup/install) >= 0.15.0

### Installation

1. **Install DFX** (if not already installed):
   ```bash
   sh -ci "$(curl -fsSL https://sdk.dfinity.org/install.sh)"
   ```

2. **Install project dependencies**:
   ```bash
   npm install
   ```

3. **Setup and deploy canisters**:
   ```bash
   cd src/dbank_frontend
   npm run setup
   ```

### Development

#### Start the local replica (required for local development):
```bash
dfx start --background
```

#### Deploy to local replica:
```bash
dfx deploy
```

#### Start the frontend development server:
```bash
cd src/dbank_frontend
npm start
```

The frontend will be available at `http://localhost:3000`, with API requests proxied to the replica at port 4943.

### Building for Production

```bash
npm run build
```

### Running Tests

```bash
npm test
```

## 🔧 Configuration

### DFX Configuration (`dfx.json`)

The project uses the following canisters:

| Canister | Type | Description |
|----------|------|-------------|
| `dbank_backend` | Motoko | Core banking logic |
| `dbank_frontend` | Assets | React frontend application |
| `internet_identity` | Custom | Authentication (pre-configured on mainnet) |

### Frontend Configuration

- **Port**: 3000 (development)
- **Build Output**: `src/dbank_frontend/dist`
- **Candid Interface**: Auto-generated in `src/declarations/`

## 📚 Documentation

- [Internet Computer Documentation](https://internetcomputer.org/docs/current/developer-docs/setup/deploy-locally)
- [Motoko Programming Language Guide](https://internetcomputer.org/docs/current/motoko/main/motoko)
- [DFINITY SDK Developer Tools](https://internetcomputer.org/docs/current/developer-docs/setup/install)
- [React Documentation](https://react.dev/)
- [Vite Documentation](https://vitejs.dev/)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the terms of the MIT license.

## 🙏 Acknowledgments

- [DFINITY Foundation](https://dfinity.org/) for the Internet Computer platform
- The open-source community for their valuable contributions

