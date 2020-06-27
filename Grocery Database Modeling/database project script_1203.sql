-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `mydb` DEFAULT CHARACTER SET utf8 ;
USE `mydb` ;

-- -----------------------------------------------------
-- Table `mydb`.`address`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`address` (
  `Address_id` INT(11) NOT NULL,
  `State` VARCHAR(45) NOT NULL,
  `City` VARCHAR(45) NOT NULL,
  `Zipcode` INT(11) NOT NULL,
  `Addressline` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`Address_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `mydb`.`category`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`category` (
  `Main_category` VARCHAR(45) NOT NULL,
  `Sub_category` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`Main_category`, `Sub_category`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `mydb`.`coupons`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`coupons` (
  `Coupon_code` VARCHAR(45) NOT NULL,
  `Coupon_description` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`Coupon_code`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `mydb`.`customers`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`customers` (
  `Customers_id` INT(11) NOT NULL,
  `firstname` VARCHAR(45) NOT NULL,
  `lastname` VARCHAR(45) NOT NULL,
  `address_Address_id` INT(11) NOT NULL,
  PRIMARY KEY (`Customers_id`),
  INDEX `fk_customers_address1_idx` (`address_Address_id` ASC),
  CONSTRAINT `fk_customers_address1`
    FOREIGN KEY (`address_Address_id`)
    REFERENCES `mydb`.`address` (`Address_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `mydb`.`departments`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`departments` (
  `Department_name` VARCHAR(45) NOT NULL,
  `Depthead_Employee_id` INT NOT NULL,
  PRIMARY KEY (`Department_name`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `mydb`.`employees`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`employees` (
  `Employee_id` INT(11) NOT NULL,
  `FirstName` VARCHAR(45) NOT NULL,
  `LastName` VARCHAR(45) NOT NULL,
  `Department_name` VARCHAR(45) NOT NULL,
  `Store_id` INT(11) NULL,
  `ReportTo_Employee_id` INT NULL,
  `address_Address_id` INT(11) NOT NULL,
  PRIMARY KEY (`Employee_id`),
  INDEX `fk_employees_address1_idx` (`address_Address_id` ASC),
  CONSTRAINT `fk_employees_address1`
    FOREIGN KEY (`address_Address_id`)
    REFERENCES `mydb`.`address` (`Address_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `mydb`.`suppliers`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`suppliers` (
  `Suppliers_id` INT(11) NOT NULL,
  `Name` VARCHAR(45) NOT NULL,
  `address_Address_id` INT(11) NOT NULL,
  PRIMARY KEY (`Suppliers_id`),
  INDEX `fk_suppliers_address1_idx` (`address_Address_id` ASC),
  CONSTRAINT `fk_suppliers_address1`
    FOREIGN KEY (`address_Address_id`)
    REFERENCES `mydb`.`address` (`Address_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `mydb`.`products`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`products` (
  `Product_id` INT(11) NOT NULL,
  `Product_name` VARCHAR(45) NOT NULL,
  `Category_Main_category` VARCHAR(45) NOT NULL,
  `Category_Sub_category` VARCHAR(45) NOT NULL,
  `Suppliers_Suppliers_id` INT(11) NOT NULL,
  `VendorPrice` DECIMAL(10,2) NOT NULL,
  `QuantityInStock` INT(11) NOT NULL,
  PRIMARY KEY (`Product_id`),
  INDEX `fk_Products_Category1_idx` (`Category_Main_category` ASC, `Category_Sub_category` ASC),
  INDEX `fk_Products_Suppliers1_idx` (`Suppliers_Suppliers_id` ASC),
  CONSTRAINT `fk_Products_Category1`
    FOREIGN KEY (`Category_Main_category` , `Category_Sub_category`)
    REFERENCES `mydb`.`category` (`Main_category` , `Sub_category`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Products_Suppliers1`
    FOREIGN KEY (`Suppliers_Suppliers_id`)
    REFERENCES `mydb`.`suppliers` (`Suppliers_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `mydb`.`stores`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`stores` (
  `Store_id` INT(11) NOT NULL,
  `address_Address_id` INT(11) NOT NULL,
  `StoreManager_Employee_id` INT NOT NULL,
  PRIMARY KEY (`Store_id`),
  INDEX `fk_stores_address1_idx` (`address_Address_id` ASC),
  CONSTRAINT `fk_stores_address1`
    FOREIGN KEY (`address_Address_id`)
    REFERENCES `mydb`.`address` (`Address_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `mydb`.`orders`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`orders` (
  `Orders_id` INT(11) NOT NULL,
  `Orderdate` DATETIME NOT NULL,
  `Stores_Store_id` INT(11) NOT NULL,
  `customers_Customers_id` INT(11) NOT NULL,
  PRIMARY KEY (`Orders_id`),
  INDEX `fk_Orders_Stores1_idx` (`Stores_Store_id` ASC),
  INDEX `fk_Orders_customers1_idx` (`customers_Customers_id` ASC),
  CONSTRAINT `fk_Orders_Stores1`
    FOREIGN KEY (`Stores_Store_id`)
    REFERENCES `mydb`.`stores` (`Store_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Orders_customers1`
    FOREIGN KEY (`customers_Customers_id`)
    REFERENCES `mydb`.`customers` (`Customers_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `mydb`.`orderdetails`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`orderdetails` (
  `Orders_Orders_id` INT(11) NOT NULL,
  `products_Product_id` INT(11) NOT NULL,
  `Quantity` INT(11) NOT NULL,
  `UnitPrice` DECIMAL(10,2) NOT NULL,
  `FinalPrice` DECIMAL(10,2) NOT NULL,
  `Coupons_Coupon_code` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`Orders_Orders_id`, `products_Product_id`),
  INDEX `fk_Products_has_Orders_Orders1_idx` (`Orders_Orders_id` ASC),
  INDEX `fk_OrderDetails_products1_idx` (`products_Product_id` ASC),
  INDEX `fk_OrderDetails_Coupons1_idx` (`Coupons_Coupon_code` ASC),
  CONSTRAINT `fk_OrderDetails_Coupons1`
    FOREIGN KEY (`Coupons_Coupon_code`)
    REFERENCES `mydb`.`coupons` (`Coupon_code`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_OrderDetails_products1`
    FOREIGN KEY (`products_Product_id`)
    REFERENCES `mydb`.`products` (`Product_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Products_has_Orders_Orders1`
    FOREIGN KEY (`Orders_Orders_id`)
    REFERENCES `mydb`.`orders` (`Orders_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;


insert into category values ('Food','Fruits');
insert into category values ('Food','Vegetables');
insert into category values ('Food','Meat');
insert into category values ('Food','Bread');
insert into category values ('Household','Cleaning');
insert into category values ('Household','Storage');

insert into address values (1, 'NC', 'Winston Salem', 27106, '10 W 5th St');
insert into address values (2, 'NC', 'Winston Salem', 27110, '12 S Main St');
insert into address values (3, 'NC', 'Winston Salem', 27106, '210 Forsyth St');
insert into address values (4, 'NC', 'Winston Salem', 27106, '33 Hinshaw Ave');
insert into address values (5, 'NC', 'Winston Salem', 27106, '1021 N Spring St');
insert into address values (6, 'NC', 'Winston Salem', 27109, '503 Marshall St');
insert into address values (7, 'NC', 'Winston Salem', 27109, '8 W 8th St');
insert into address values (8, 'NC', 'Winston Salem', 27110, '67 Haywood St');
insert into address values (9, 'NC', 'Winston Salem', 27110, '11 Rundell St');
insert into address values (10, 'NC', 'Raleigh', 28105, '324 Williamson Rd');
insert into address values (11, 'NC', 'Winston Salem', 27106, '19 E 11th St');
insert into address values (12, 'NC', 'Winston Salem', 27109, '222 Reynolda Rd');
insert into address values (13, 'NC', 'Winston Salem', 27110, '104 Cherry St');
insert into address values (14, 'NC', 'Greensboro', 26012, '10 W Market St');
insert into address values (15, 'NC', 'Winston Salem', 27109, '1017 Branch St');

insert into suppliers values (901,'Great Value', 9);
insert into suppliers values (902,'Lysol', 10);
insert into suppliers values (903,'Mainstay', 11);

insert into products values (1001,'apple', 'Food', 'Fruits', 901, 1, 7);
insert into products values (1002,'lettuce', 'Food', 'Vegetables', 901, 1.5, 6);
insert into products values (1003,'beef', 'Food', 'Meat', 901, 5, 5);
insert into products values (1004,'bagel', 'Food', 'Bread', 901, 0.8, 2);
insert into products values (1005,'wipes', 'Household','Cleaning', 902, 2, 3);
insert into products values (1006,'container', 'Household','Storage', 903, 4, 1);

insert into coupons values ('c201', 'new member discount');
insert into coupons values ('c202', 'holiday discount');

insert into customers values (7001, 'Brent', 'Cooper', 12);
insert into customers values (7002, 'Holly', 'Long', 13);
insert into customers values (7003, 'Cady', 'Flores', 14);
insert into customers values (7004, 'Halsey', 'Carter', 15);

insert into employees values (5801, 'Wallace', 'Roger', 'Sales', 749, 5802, 3);
insert into employees values (5802, 'Milton', 'Scott', 'Sales', 749, 5805, 4);
insert into employees values (5803, 'Ralph', 'Adams', 'Sales', 750, 5804, 5);
insert into employees values (5804, 'Dayton', 'Parker', 'Sales', 750, 5805, 6);
insert into employees values (5805, 'Lindsay', 'Collins', 'Sales', null, null, 7);
insert into employees values (5806, 'Kim', 'Kelly', 'HR', null, null, 8);

insert into departments values ('Sales', 5805);
insert into departments values ('HR', 5806);

insert into stores values (749,1, 5802);
insert into stores values (750,2, 5804);

insert into orders values (11001, '2019-11-11 09:20:00', 749, 7001);
insert into orders values (11002, '2019-11-11 10:20:00', 750, 7002);
insert into orders values (11003, '2019-11-11 12:20:00', 749, 7003);
insert into orders values (11004, '2019-11-11 13:20:00', 750, 7004);
insert into orders values (11005, '2019-11-12 09:20:00', 749, 7001);

insert into orderdetails values (11001, 1001, 1, 1.99, 1.99, null);
insert into orderdetails values (11001, 1004, 1, 2.49, 2.49, null);
insert into orderdetails values (11002, 1003, 2, 9.99, 9.99, null);
insert into orderdetails values (11003, 1002, 2, 2.99, 2.49, 'c201');
insert into orderdetails values (11003, 1005, 1, 4, 3.59, 'c201');
insert into orderdetails values (11004, 1006, 2, 8, 7.49, 'c201');
insert into orderdetails values (11004, 1003, 1, 9.99, 9.49, 'c201');
insert into orderdetails values (11005, 1004, 1, 2.49, 2.29, 'c202');

alter table departments ADD FOREIGN KEY(Depthead_Employee_id) References employees(Employee_id);
alter table stores ADD FOREIGN KEY(StoreManager_Employee_id) References employees(Employee_id);
alter table employees ADD FOREIGN KEY(Department_name) References departments(department_name);
alter table employees ADD FOREIGN KEY(Store_id) References stores(Store_id);
alter table employees ADD FOREIGN KEY(ReportTo_Employee_id) References employees(Employee_id);
