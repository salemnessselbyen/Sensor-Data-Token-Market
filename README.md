# 🌡️ Sensor Data Token Market

> **Democratizing IoT Data Access Through Blockchain Technology** 🚀

A revolutionary smart contract platform that enables IoT device owners to monetize their sensor data while providing researchers, companies, and governments with verified, real-time environmental and industrial data.

## 🎯 Problem & Solution

**Problem**: Valuable real-time data from IoT devices is underutilized and hard to verify.

**Solution**: 
- 📡 IoT sensors publish signed data streams
- 💰 Buyers purchase tokenized access rights
- ✅ On-chain validation of data authenticity through device signatures
- 🌍 Creates new income streams for device owners and democratizes data access

## 🏗️ Architecture

The smart contract consists of several key components:

### 🎫 Fungible Token
- **Data Access Token**: Used for purchasing sensor data access rights

### 📊 Core Data Structures
- **Sensors**: Device registration with location, type, pricing, and public keys
- **Sensor Data**: Timestamped data with cryptographic signatures
- **Access Rights**: Time-based subscription system for data buyers
- **Statistics**: Tracking for both sensor owners and data buyers

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js and npm for testing

### Installation
```bash
git clone <repository-url>
cd Sensor-Data-Token-Market
clarinet check
npm install
npm test
```

## 📋 Core Functions

### 🏭 For Sensor Owners

#### Register a Sensor
```clarity
(register-sensor "New York Harbor" "temperature" u100 0x02...)
```
- **location**: GPS location or description (max 50 chars)
- **sensor-type**: Type of sensor (max 30 chars)
- **price-per-hour**: Cost in tokens per hour of access
- **public-key**: 33-byte secp256k1 public key for data verification

#### Publish Sensor Data
```clarity
(publish-data u1 0x1a2b3c... 0x4d5e6f... u1024)
```
- **sensor-id**: Your registered sensor ID
- **data-hash**: SHA-256 hash of the actual data
- **signature**: secp256k1 signature of the data hash
- **data-size**: Size of data in bytes

#### Update Pricing
```clarity
(update-sensor-price u1 u150)
```

#### Deactivate Sensor
```clarity
(deactivate-sensor u1)
```

### 💰 For Data Buyers

#### Purchase Data Access
```clarity
(purchase-access u1 u24)
```
- **sensor-id**: Target sensor ID
- **duration-hours**: How many hours of access to purchase

#### Check Access Status
```clarity
(has-valid-access 'ST1BUYER... u1)
```

### 🔍 Read-Only Functions

#### Get Sensor Information
```clarity
(get-sensor u1)
```

#### Verify Data Authenticity
```clarity
(verify-data-signature u1 0x1a2b3c... 0x4d5e6f...)
```

#### Calculate Access Cost
```clarity
(calculate-access-cost u1 u24)
```

#### Get Statistics
```clarity
(get-sensor-owner-stats 'ST1OWNER...)
(get-buyer-stats 'ST1BUYER...)
(get-token-balance 'ST1USER...)
```

## 🔐 Security Features

- **🔑 Cryptographic Verification**: All sensor data is signed with secp256k1
- **⏰ Time-Based Access**: Subscriptions automatically expire
- **👤 Owner Authorization**: Only sensor owners can publish data or modify settings
- **💸 Platform Fees**: Configurable fee system (default 2.5%)
- **🛡️ Input Validation**: Comprehensive parameter checking

## 🎮 Example Usage Scenarios

### 🌡️ Environmental Monitoring
```clarity
;; Register temperature sensor in Times Square
(register-sensor "Times Square, NYC" "temperature" u50 0x02...)

;; Research lab purchases 7 days of access
(purchase-access u1 u168) ;; 7 * 24 hours
```

### 🏭 Industrial IoT
```clarity
;; Register pressure sensor in factory
(register-sensor "Factory Floor A" "pressure" u200 0x03...)

;; Company purchases real-time monitoring
(purchase-access u2 u24) ;; 24 hours
```

### 🚗 Smart City Data
```clarity
;; Register traffic sensor
(register-sensor "Highway I-95 Mile 42" "traffic" u75 0x04...)

;; Government purchases access for planning
(purchase-access u3 u720) ;; 30 days
```

## 📊 Token Economics

- **Platform Fee**: 2.5% of all transactions (adjustable by contract owner)
- **Revenue Split**: 97.5% goes directly to sensor owners
- **Access Duration**: Flexible hourly pricing model
- **Token Supply**: Controlled by contract owner minting

## 🧪 Testing

Run the test suite:
```bash
npm test
```

The tests cover:
- ✅ Sensor registration and management
- ✅ Data publishing and verification
- ✅ Access rights purchasing and validation
- ✅ Token transfers and fee calculations
- ✅ Edge cases and error conditions

## 🌐 Real-World Impact

### For Device Owners 📱
- 💰 **New Revenue Streams**: Monetize existing IoT infrastructure
- 🔧 **Easy Integration**: Simple API for data publishing
- 📈 **Scalable Income**: More devices = more earnings

### For Data Buyers 🏢
- 📊 **Access to Real Data**: Verified, timestamped sensor readings
- 🌍 **Global Coverage**: Access sensors worldwide
- ⚡ **Real-Time**: Live data feeds for immediate insights
- 💡 **AI Training**: High-quality data for machine learning models

### For Society 🌍
- 🏛️ **Democratized Data**: Equal access to environmental information
- 🔬 **Research Advancement**: Fuel scientific discoveries
- 🌱 **Environmental Monitoring**: Better climate and pollution tracking
- 🏙️ **Smart Cities**: Data-driven urban planning

## 🔮 Future Enhancements

- 🤖 **AI Integration**: Automated quality scoring for sensor data
- 🌐 **Cross-Chain**: Bridge to other blockchain networks
- 📱 **Mobile Apps**: User-friendly interfaces for non-technical users
- 🎯 **Data Marketplace**: Advanced filtering and discovery features
- 🔔 **Alert Systems**: Real-time notifications for threshold breaches

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to help improve the platform.

## 📞 Support

For questions, issues, or support:
- 🐛 **Issues**: Open a GitHub issue
- 💬 **Discussions**: Join our community discussions
- 📧 **Contact**: Reach out to the development team

---

**Built with ❤️ for the IoT and blockchain community**

# Sensor Data Token Market

