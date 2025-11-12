DROP DATABASE IF EXISTS retail_store_adv;
CREATE DATABASE retail_store_adv;
USE retail_store_adv;

CREATE TABLE roles (
    role_id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255)
);

INSERT INTO roles (name, description) VALUES
('customer','Regular customer'),
('admin','Administrator'),
('seller','Third-party seller');

CREATE TABLE users (
    user_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    role_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
    first_name VARCHAR(60),
    last_name VARCHAR(60),
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    INDEX (role_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE TABLE addresses (
    address_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    label VARCHAR(50),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    is_default BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE categories (
    category_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    parent_id INT UNSIGNED,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    FOREIGN KEY (parent_id) REFERENCES categories(category_id)
);

CREATE TABLE brands (
    brand_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE products (
    product_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    seller_id INT UNSIGNED,
    category_id INT UNSIGNED,
    brand_id INT UNSIGNED,
    title VARCHAR(255) NOT NULL,
    short_desc VARCHAR(512),
    long_desc TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id),
    FOREIGN KEY (seller_id) REFERENCES users(user_id)
);

CREATE TABLE product_skus (
    sku_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    product_id INT UNSIGNED NOT NULL,
    sku_code VARCHAR(100) NOT NULL UNIQUE,
    attributes JSON,
    price DECIMAL(12,2) NOT NULL,
    cost_price DECIMAL(12,2),
    weight_kg DECIMAL(8,3),
    length_cm DECIMAL(8,2),
    width_cm DECIMAL(8,2),
    height_cm DECIMAL(8,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE warehouses (
    warehouse_id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    location VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE inventory (
    inventory_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    sku_id INT UNSIGNED NOT NULL,
    warehouse_id SMALLINT UNSIGNED NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    reserved INT NOT NULL DEFAULT 0,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY (sku_id, warehouse_id),
    FOREIGN KEY (sku_id) REFERENCES product_skus(sku_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

CREATE TABLE inventory_movements (
    movement_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    sku_id INT UNSIGNED NOT NULL,
    warehouse_id SMALLINT UNSIGNED NOT NULL,
    delta INT NOT NULL,
    movement_type VARCHAR(50) NOT NULL,
    reference VARCHAR(200),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sku_id) REFERENCES product_skus(sku_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

CREATE TABLE orders (
    order_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    address_id INT UNSIGNED,
    order_uuid CHAR(36) NOT NULL UNIQUE,
    total_amount DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    shipping_amount DECIMAL(12,2) DEFAULT 0,
    final_amount DECIMAL(12,2) NOT NULL,
    placed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    current_status VARCHAR(50) DEFAULT 'placed',
    is_paid BOOLEAN DEFAULT FALSE,
    payment_method VARCHAR(50),
    is_deleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

CREATE TABLE order_items (
    order_item_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT UNSIGNED NOT NULL,
    sku_id INT UNSIGNED NOT NULL,
    sku_snapshot JSON,
    unit_price DECIMAL(12,2) NOT NULL,
    quantity INT NOT NULL,
    total_price DECIMAL(12,2) NOT NULL,
    warehouse_id SMALLINT UNSIGNED,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (sku_id) REFERENCES product_skus(sku_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

CREATE TABLE order_status_history (
    history_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT UNSIGNED NOT NULL,
    from_status VARCHAR(50),
    to_status VARCHAR(50) NOT NULL,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    changed_by INT UNSIGNED,
    note VARCHAR(255),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (changed_by) REFERENCES users(user_id)
);

CREATE TABLE shipments (
    shipment_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT UNSIGNED NOT NULL,
    carrier VARCHAR(100),
    tracking_number VARCHAR(150),
    shipped_at DATETIME,
    estimated_delivery DATETIME,
    status VARCHAR(50) DEFAULT 'created',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE payments (
    payment_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT UNSIGNED NOT NULL,
    paid_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(12,2) NOT NULL,
    gateway VARCHAR(100),
    gateway_txn_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'success',
    method VARCHAR(50),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE promotions (
    promo_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(50) UNIQUE,
    description VARCHAR(255),
    discount_type ENUM('percentage','fixed') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    min_order_value DECIMAL(12,2) DEFAULT 0,
    starts_at DATETIME,
    ends_at DATETIME,
    usage_limit INT DEFAULT NULL,
    per_user_limit INT DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE promotion_usage (
    usage_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    promo_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED,
    order_id BIGINT UNSIGNED,
    used_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (promo_id) REFERENCES promotions(promo_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE product_reviews (
    review_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    product_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title VARCHAR(255),
    content TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE api_tokens (
    token_id BINARY(16) PRIMARY KEY,
    user_id INT UNSIGNED,
    description VARCHAR(255),
    revoked BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE audit_logs (
    log_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    entity VARCHAR(100),
    entity_id VARCHAR(100),
    action VARCHAR(50),
    changes JSON,
    performed_by INT UNSIGNED,
    performed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (performed_by) REFERENCES users(user_id)
);

CREATE INDEX idx_products_title ON products (title(100));
CREATE INDEX idx_orders_user_status ON orders (user_id, current_status);
CREATE INDEX idx_inventory_sku_wh ON inventory (sku_id, warehouse_id);
CREATE INDEX idx_product_skus_price ON product_skus (price);

INSERT INTO warehouses (name, location) VALUES
('Chennai Warehouse', 'Neyveli'),
('Bangalore Warehouse', 'Bangalore');

INSERT INTO categories (name, slug) VALUES
('Electronics','electronics'),
('Mobiles','mobiles'),
('Accessories','accessories');

INSERT INTO brands (name) VALUES ('Dell'), ('Samsung'), ('Sony');

INSERT INTO users (role_id, first_name, last_name, email, password_hash, phone) VALUES
(1,'John','Doe','john@example.com','hash1','9876543210'),
(1,'Priya','Singh','priya@example.com','hash2','9123456789'),
(2,'Admin','User','admin@example.com','hash3','9000000000');

INSERT INTO products (seller_id, category_id, brand_id, title, short_desc, long_desc)
VALUES
(3,1,1,'Dell Inspiron 15','15 inch laptop','Dell Inspiron 15 for developers'),
(NULL,2,2,'Samsung Galaxy S23','Flagship phone','S23 with 8GB RAM'),
(NULL,3,3,'Sony WH-1000XM5','Headphones','Noise cancelling headphones');

INSERT INTO product_skus (product_id, sku_code, attributes, price, cost_price, weight_kg)
VALUES
(1,'DELL-INS-15-STD', JSON_OBJECT('color','Silver','ram','8GB','storage','512GB'), 65000, 52000, 2.2),
(2,'SAM-GS23-8GB', JSON_OBJECT('color','Phantom Black','storage','128GB'), 55000, 42000, 0.18),
(3,'SONY-WH1000XM5-BLK', JSON_OBJECT('color','Black'), 25000, 17000, 0.27);

INSERT INTO inventory (sku_id, warehouse_id, quantity, reserved) VALUES
(1, 1, 10, 0),
(1, 2, 5, 0),
(2, 2, 15, 0),
(3, 1, 20, 0);

INSERT INTO promotions (code, description, discount_type, discount_value, min_order_value, starts_at, ends_at, is_active)
VALUES
('WELCOME10','10 percent off','percentage',10,0,NOW(),NOW() + INTERVAL 30 DAY,TRUE),
('FLAT500','Flat 500 off','fixed',500,5000,NOW(),NOW() + INTERVAL 60 DAY,TRUE);

INSERT INTO product_reviews (product_id, user_id, rating, title, content, is_verified_purchase)
VALUES (1,1,5,'Excellent','Good performance',TRUE);
