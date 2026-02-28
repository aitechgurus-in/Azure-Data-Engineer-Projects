-- 1. Products Table (Added NOT NULL)
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

-- Optimized Multi-row Insert
INSERT INTO products (product_id, product_name, category, price) VALUES 
(1, 'Wireless Mouse', 'Electronics', 799.99),
(2, 'Bluetooth Speaker', 'Electronics', 1299.49),
(3, 'Yoga Mat', 'Fitness', 499.00),
(4, 'Laptop Stand', 'Accessories', 999.99),
(5, 'Notebook Set', 'Stationery', 149.00),
(6, 'Water Bottle', 'Fitness', 299.00),
(7, 'Smartwatch', 'Electronics', 4999.00),
(8, 'Desk Organizer', 'Accessories', 399.00),
(9, 'Dumbbell Set', 'Fitness', 1999.00),
(10, 'Pen Drive 32GB', 'Electronics', 599.00);

-- 2. Stores Table (Added NOT NULL)
CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL
);

INSERT INTO stores (store_id, store_name, location) VALUES 
(1, 'City Mall Store', 'Mumbai'),
(2, 'High Street Store', 'Delhi'),
(3, 'Tech World Outlet', 'Bangalore'),
(4, 'Downtown Mini Store', 'Pune'),
(5, 'Mega Plaza', 'Chennai');

-- 3. Transactions Table (Added Identity and Constraints)
CREATE TABLE transactions (
    transaction_id INT IDENTITY(1,1) PRIMARY KEY, -- Auto-increments
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    store_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0), -- Business logic check
    transaction_date DATE NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

-- Note: Since transaction_id is now IDENTITY, we don't pass the first number
INSERT INTO transactions (customer_id, product_id, store_id, quantity, transaction_date) VALUES 
(127, 8, 4, 4, '2025-03-31'),
(105, 3, 4, 5, '2024-11-12'),
(116, 2, 2, 3, '2025-05-01'),
(120, 8, 1, 1, '2024-11-02'),
(105, 5, 2, 1, '2025-03-17'),
(110, 7, 3, 5, '2025-01-04'),
(110, 7, 2, 5, '2025-01-01'),
(126, 7, 5, 2, '2025-06-08'),
(123, 1, 3, 2, '2024-10-08'),
(124, 2, 2, 5, '2024-08-27'),
(102, 1, 3, 2, '2024-08-11'),
(108, 5, 1, 4, '2025-05-26'),
(104, 3, 3, 4, '2025-05-04'),
(120, 1, 4, 5, '2024-07-17'),
(121, 6, 5, 5, '2025-05-19'),
(118, 6, 2, 4, '2024-11-29'),
(109, 8, 5, 5, '2024-07-10'),
(103, 1, 4, 3, '2024-09-05'),
(116, 8, 4, 4, '2024-07-14'),
(130, 5, 1, 2, '2024-07-30'),
(105, 1, 3, 5, '2024-10-02'),
(107, 9, 3, 4, '2024-11-16'),
(122, 9, 4, 2, '2025-04-30'),
(125, 1, 5, 1, '2024-07-14'),
(116, 8, 4, 5, '2024-12-13'),
(126, 6, 2, 2, '2024-09-21'),
(127, 8, 1, 1, '2024-10-10'),
(101, 7, 5, 3, '2024-11-15'),
(119, 9, 4, 2, '2025-06-03'),
(116, 8, 4, 5, '2025-03-16');
