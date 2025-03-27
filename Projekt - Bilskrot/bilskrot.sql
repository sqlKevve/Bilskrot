CREATE DATABASE Bilskrot;
USE Bilskrot;

-- Tabell för alla bildelar
CREATE TABLE Parts (
	PartID INT AUTO_INCREMENT PRIMARY KEY,
    Part VARCHAR(100) NOT NULL,
    FitsToCar VARCHAR(100) NOT NULL,
    Price INT NOT NULL,
    Quantity INT NOT NULL
);

-- Tabell för alla kunder och deras information
CREATE TABLE Customers ( 
	CustomerID INT AUTO_INCREMENT PRIMARY KEY, 
	FullName VARCHAR(100) NOT NULL, 
	Email VARCHAR(100) UNIQUE NOT NULL, 
	Phone VARCHAR(100) NOT NULL, 
	Adress VARCHAR(100) NOT NULL,
    Balance INT DEFAULT 5000 NOT NULL
);

-- Tabell för alla beställningar
CREATE TABLE Orders (
	OrderID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    DateAndTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TotalAmount INT NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Tabell för beställningsraderna
CREATE TABLE Orderrows (
	OrderrowID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    PartID INT NOT NULL,
    Quantity INT NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (PartID) REFERENCES Parts(PartID)
);

-- Test data i Customers
INSERT INTO Customers (FullName, Email, Phone, Adress, Balance) VALUES
('Anna Johansson', 'anna.johansson@email.com', '070-1234567', 'Storgatan 1, Stockholm', 5000),
('Erik Svensson', 'erik.svensson@email.com', '073-7654321', 'Lillgatan 3, Göteborg', 4500),
('Linda Karlsson', 'linda.karlsson@email.com', '072-1122334', 'Skogsvägen 9, Malmö', 6200);

-- Test data i Parts
INSERT INTO Parts (Part, FitsToCar, Price, Quantity) VALUES
('Bromsskiva', 'Volvo V70', 750, 10),
('Strålkastare', 'Audi A4', 1200, 5),
('Kylare', 'BMW 3-Serie', 2500, 3),
('Avgassystem', 'Volkswagen Golf', 2200, 4);


-- Funktion för att automatiskt lägga in en order genom att bara knappa in email, partID och kvantitet
DELIMITER $$
CREATE PROCEDURE MakeOrder (
    IN in_CustomerEmail VARCHAR(100), 
    IN in_PartID INT, 
    IN in_Quantity INT
)
BEGIN
    DECLARE v_customerID INT;
    DECLARE v_price INT;
    DECLARE v_totalCost INT;
	
	-- Hämta CustomerID baserat på e-post
    SELECT CustomerID INTO v_customerID FROM Customers WHERE Email = in_CustomerEmail;
    
    -- Hämta pris på delen/delarna
    SELECT Price INTO v_price FROM Parts WHERE PartID = in_PartID;
    SET v_totalCost = v_price * in_Quantity;
    
    -- Lägg till i Orders
    INSERT INTO Orders (CustomerID, TotalAmount) 
    VALUES (v_customerID, v_totalCost);

    -- Lägg till i Orderrows med nya orderns ID
    INSERT INTO Orderrows (OrderID, PartID, Quantity) 
    VALUES (LAST_INSERT_ID(), in_PartID, in_Quantity);
    
END$$
DELIMITER ;

-- Funktion för att automatiskt visa relevant information om alla orders
DELIMITER $$
CREATE PROCEDURE ShowOrders ()
BEGIN
	SELECT
    Orders.OrderID,
    Orders.DateAndTime,
    Orders.TotalAmount,
    Customers.CustomerID,
    Customers.Email,
    Parts.Part,
    Parts.FitsToCar,
    Orderrows.Quantity
	FROM Orderrows
	INNER JOIN Orders ON Orderrows.OrderID = Orders.OrderID
	INNER JOIN Customers ON Orders.CustomerID = Customers.CustomerID
	INNER JOIN Parts ON Orderrows.PartID = Parts.PartID;
END$$
DELIMITER ;

-- Funktion för att kunna separat söka upp alla delar till en specifik bil
DELIMITER $$
CREATE PROCEDURE ShowPartsForCar (
	in in_FitsToCar VARCHAR(100)
)
BEGIN
	SELECT PartID, Part, Price, Quantity FROM Parts WHERE FitsToCar = in_FitsToCar;
END$$
DELIMITER ;

-- Trigger som minskar kvantiteten i lagret på bildelar när en beställning läggs
DELIMITER $$
CREATE TRIGGER ReducePartQuantityAfterOrder
AFTER INSERT ON Orderrows
FOR EACH ROW
BEGIN
    UPDATE Parts
    SET Quantity = Quantity - NEW.Quantity
    WHERE PartID = NEW.PartID;
END$$
DELIMITER ;

-- Trigger som automatiskt minskar saldot på kunden när de lägger en beställning
DELIMITER $$
CREATE TRIGGER ReduceBalanceAfterOrder
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    UPDATE Customers
    SET Balance = Balance - NEW.TotalAmount
    WHERE CustomerID = NEW.CustomerID;
END$$
DELIMITER ;

-- Test exempel på en ny beställning 
CALL MakeOrder('erik.svensson@email.com', 1, 2);
CALL MakeOrder('anna.johansson@email.com', 2, 1);

-- Test exempel på funktionen som visar alla ordrar
CALL ShowOrders();