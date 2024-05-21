
# InvocifyPro

InvocifyPro is a Flutter-based mobile app for invoice generation and stock management, featuring barcode/QR code scanning, PDF invoice creation and sharing, low stock alerts, and QR code generation for shopkeepers. This project is designed to streamline business operations and enhance efficiency in managing invoices and inventory.

## Table of Contents
- [Introduction](#introduction)
- [App Features](#app-features)
- [Installation](#installation)
- [Frontend Installation](#frontend-installation)
- [Backend Installation](#backend-installation)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Introduction

InvocifyPro is an all-in-one solution for businesses looking to automate and simplify their invoicing and stock management processes. The app leverages modern technologies like Flutter for the frontend and NodeJS with Express for the backend, and it uses PostgreSQL for robust data storage.

## App Features

- **Barcode/QR Code Scanning:** Efficiently scan product barcodes or QR codes for quick identification and management.
- **PDF Invoice Creation and Sharing:** Generate professional PDF invoices directly from the app and share them with clients or suppliers.
- **Low Stock Alerts:** Get timely notifications when stock levels are running low, allowing for proactive inventory management.
- **QR Code Generation for Shopkeepers:** Enable shopkeepers to generate QR codes for their products, facilitating easy scanning and tracking.
- **User-friendly Interface:** Simple and intuitive design for a seamless user experience.

## Installation

To install InvocifyPro, follow these steps for both the frontend and backend components.

### Frontend Installation

1. **Clone the Repository:**
	```bash
   git clone https://github.com/meetbutani/InvocifyPro.git
	```
2. **Navigate to the Frontend Directory:**
	```bash
   cd InvocifyPro/invocifypro
   ```
3. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
4. **Run the App:**
   Connect your Android or iOS device, or start an emulator.
	```bash
     flutter run
	```

### Backend Installation

1. **Navigate to the Backend Directory:**
	```bash
   cd InvocifyPro/invocifypro_backend
	```
2. **Install Dependencies:**
	```bash
   npm install
	```
3. **Set Up PostgreSQL Database:**
   - Create a PostgreSQL database.
   - Create a `.env` file in the `invocifypro_backend` directory with the following content:
	```plaintext
    DB_HOST=
    DB_USER=
    DB_PASSWORD=
    DB_DATABASE=invocifypro
    DB_PORT=5432
	```
4. **Run the Server:**
	```bash
	npm start
	```

## Contributing

We welcome contributions from the community to improve InvocifyPro. To contribute, follow these steps:

1. **Fork the Repository:** Click the `Fork` button on the top right corner of the repository page.
2. **Create a Branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make Your Changes:** Implement your feature or bug fix.
4. **Commit Your Changes:**
   ```bash
   git commit -m "Description of your changes"
   ```
5. **Push to Your Branch:**
   ```bash
   git push origin feature/your-feature-name
   ```
6. **Create a Pull Request:** Go to the repository on GitHub and open a pull request.

## License

InvocifyPro is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Contact

For any inquiries, issues, or suggestions, please contact us at:

- Email: meet.butani2702@gmail.com
- GitHub Issues: [InvocifyPro Issues](https://github.com/meetbutani/InvocifyPro/issues)

Thank you for using InvocifyPro! We hope it enhances your business operations by simplifying invoice generation and stock management.
