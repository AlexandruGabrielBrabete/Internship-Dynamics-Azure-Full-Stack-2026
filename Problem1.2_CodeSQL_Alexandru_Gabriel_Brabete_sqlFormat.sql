/* 1. CREATE DATABASE */
CREATE DATABASE CoffeeShopSarah;
GO

USE CoffeeShopSarah;
GO

/* 2. TABLE: COFFEESHOPS
   Each coffee shop location */
CREATE TABLE COFFEESHOPS (
    ShopID INT PRIMARY KEY IDENTITY,
    ShopName VARCHAR(50) NOT NULL,
    Location VARCHAR(100) NOT NULL
);

INSERT INTO COFFEESHOPS (ShopName, Location)
VALUES 
('Sarah Coffee Downtown','Cluj-Napoca'),
('Sarah Coffee Mall','Cluj-Napoca');

SELECT * FROM COFFEESHOPS;

/* 3. TABLE: BARISTAS
   Each barista belongs to a coffee shop */
CREATE TABLE BARISTAS (
    BaristaID INT PRIMARY KEY IDENTITY,
    BaristaName VARCHAR(50) NOT NULL,
    BaristaCode INT NOT NULL UNIQUE,
    ShopID INT NOT NULL
);

ALTER TABLE BARISTAS
ADD FOREIGN KEY (ShopID) REFERENCES COFFEESHOPS(ShopID);

INSERT INTO BARISTAS (BaristaName, BaristaCode, ShopID)
VALUES 
('Andrei',101,1),
('Maria',102,1),
('Alex',103,2);

SELECT * FROM BARISTAS;

/* 4. TABLE: CUSTOMERS
   Loyalty program: Regular or Gold */
CREATE TABLE CUSTOMERS (
    CustomerID INT PRIMARY KEY IDENTITY,
    CustomerName VARCHAR(50) NOT NULL,
    MembershipType VARCHAR(10) NOT NULL CHECK (MembershipType IN ('Regular','Gold')),
    LoyaltyPoints INT DEFAULT 0
);

INSERT INTO CUSTOMERS (CustomerName, MembershipType)
VALUES 
('Ion','Regular'),
('Ana','Gold');

SELECT * FROM CUSTOMERS;

/* 5. TABLE: BEVERAGE_CATEGORIES
   Espresso, Latte, Cappuccino */
CREATE TABLE BEVERAGE_CATEGORIES (
    CategoryID INT PRIMARY KEY IDENTITY,
    CategoryName VARCHAR(30) NOT NULL
);

INSERT INTO BEVERAGE_CATEGORIES (CategoryName)
VALUES ('Espresso'), ('Latte'), ('Cappuccino');

SELECT * FROM BEVERAGE_CATEGORIES;

/* 6. TABLE: BEVERAGES
   Different sizes with BasePrice */
CREATE TABLE BEVERAGES (
    BeverageID INT PRIMARY KEY IDENTITY,
    BeverageName VARCHAR(50) NOT NULL,
    Size VARCHAR(10) NOT NULL CHECK (Size IN ('Small','Medium','Large')),
    BasePrice DECIMAL(10,2) NOT NULL CHECK (BasePrice > 0),
    CategoryID INT NOT NULL
);

ALTER TABLE BEVERAGES
ADD FOREIGN KEY (CategoryID) REFERENCES BEVERAGE_CATEGORIES(CategoryID);

INSERT INTO BEVERAGES (BeverageName, Size, BasePrice, CategoryID)
VALUES 
('Espresso','Small',8,1),
('Espresso','Medium',10,1),
('Latte','Medium',15,2),
('Latte','Large',18,2),
('Cappuccino','Medium',16,3);

SELECT * FROM BEVERAGES;

/* 7. TABLE: EXTRAS
   Customizations for beverages */
CREATE TABLE EXTRAS (
    ExtraID INT PRIMARY KEY IDENTITY,
    ExtraName VARCHAR(30) NOT NULL,
    ExtraPrice DECIMAL(10,2) NOT NULL CHECK (ExtraPrice >= 0)
);

INSERT INTO EXTRAS (ExtraName, ExtraPrice)
VALUES 
('Extra Shot',3),
('Vanilla Syrup',2.5),
('Caramel Syrup',2.5),
('Whipped Cream',2);

SELECT * FROM EXTRAS;

/* 8. TABLE: SALES
   Tracks barista, customer, timestamp, total */
CREATE TABLE SALES (
    SaleID INT PRIMARY KEY IDENTITY,
    BaristaID INT NOT NULL,
    CustomerID INT NULL,
    SaleDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) NOT NULL CHECK (TotalAmount > 0)
);

ALTER TABLE SALES
ADD FOREIGN KEY (BaristaID) REFERENCES BARISTAS(BaristaID);

ALTER TABLE SALES
ADD FOREIGN KEY (CustomerID) REFERENCES CUSTOMERS(CustomerID);

/* 9. TABLE: SALE_DETAILS
   Each sale can have multiple beverages */
CREATE TABLE SALE_DETAILS (
    SaleDetailID INT PRIMARY KEY IDENTITY,
    SaleID INT NOT NULL,
    BeverageID INT NOT NULL
);

ALTER TABLE SALE_DETAILS
ADD FOREIGN KEY (SaleID) REFERENCES SALES(SaleID);

ALTER TABLE SALE_DETAILS
ADD FOREIGN KEY (BeverageID) REFERENCES BEVERAGES(BeverageID);

/* 10. TABLE: SALE_DETAIL_EXTRAS
   Link extras to each beverage in a sale */
CREATE TABLE SALE_DETAIL_EXTRAS (
    SaleDetailExtraID INT PRIMARY KEY IDENTITY,
    SaleDetailID INT NOT NULL,
    ExtraID INT NOT NULL
);

ALTER TABLE SALE_DETAIL_EXTRAS
ADD FOREIGN KEY (SaleDetailID) REFERENCES SALE_DETAILS(SaleDetailID);

ALTER TABLE SALE_DETAIL_EXTRAS
ADD FOREIGN KEY (ExtraID) REFERENCES EXTRAS(ExtraID);

/* 11. FUNCTION: Calculate loyalty points
   Gold = 2 points per euro, Regular = 1 point per euro */
GO
CREATE FUNCTION dbo.udf_CalculatePoints
(
    @Amount DECIMAL(10,2),
    @MembershipType VARCHAR(10)
)
RETURNS INT
AS
BEGIN
    RETURN (
        CASE 
            WHEN @MembershipType = 'Gold' THEN FLOOR(@Amount)*2
            ELSE FLOOR(@Amount)
        END
    );
END
GO

/* 12. TRIGGER: Update loyalty points after sale */
CREATE TRIGGER trg_UpdatePoints
ON SALES
AFTER INSERT
AS
BEGIN
    UPDATE C
    SET LoyaltyPoints = C.LoyaltyPoints +
        dbo.udf_CalculatePoints(I.TotalAmount, C.MembershipType)
    FROM CUSTOMERS C
    JOIN inserted I ON C.CustomerID = I.CustomerID;
END
GO

/* 13. VIEW: Complete sales report */
GO
CREATE VIEW vSalesReport AS
SELECT 
    S.SaleID,
    S.SaleDate,
    CS.ShopName,
    B.BaristaName,
    C.CustomerName,
    S.TotalAmount,
    BV.BeverageName,
    BV.Size
FROM SALES S
JOIN BARISTAS B ON S.BaristaID = B.BaristaID
JOIN COFFEESHOPS CS ON B.ShopID = CS.ShopID
LEFT JOIN CUSTOMERS C ON S.CustomerID = C.CustomerID
JOIN SALE_DETAILS SD ON S.SaleID = SD.SaleID
JOIN BEVERAGES BV ON SD.BeverageID = BV.BeverageID;
GO

SELECT * FROM vSalesReport;

/* 14. TABLE-VALUED FUNCTIONS: Filtered sales */
GO

CREATE FUNCTION dbo.ufn_SalesByCustomer(@CustomerID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT * FROM SALES
    WHERE CustomerID = @CustomerID
);
GO

CREATE FUNCTION dbo.ufn_SalesByBarista(@BaristaID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT * FROM SALES
    WHERE BaristaID = @BaristaID
);
GO

SELECT * FROM dbo.ufn_SalesByCustomer(2);
SELECT * FROM dbo.ufn_SalesByBarista(1);

/* 15. FUNCTION: Detailed Menu
   Shows Beverage, Size, BasePrice, Extra(s) */
GO
CREATE FUNCTION dbo.ufn_DetailedMenu()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        BV.BeverageID,
        BV.BeverageName,
        BV.Size,
        BV.BasePrice,
        EX.ExtraID,
        EX.ExtraName,
        EX.ExtraPrice
    FROM BEVERAGES BV
    CROSS JOIN EXTRAS EX
);
GO

SELECT * FROM dbo.ufn_DetailedMenu();

/* 16. STORED PROCEDURE: Create Sale automatically
   Calculates TotalAmount and inserts Sale, Details, Extras */
GO
CREATE PROCEDURE sp_CreateSale
    @BaristaID INT,
    @CustomerID INT = NULL,
    @BeverageID INT,
    @ExtraIDs NVARCHAR(MAX) = NULL -- comma-separated
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalAmount DECIMAL(10,2);
    DECLARE @SaleID INT;
    DECLARE @SaleDetailID INT;

    -- 1. Base price
    SELECT @TotalAmount = BasePrice
    FROM BEVERAGES
    WHERE BeverageID = @BeverageID;

    -- 2. Add extras price
    IF @ExtraIDs IS NOT NULL AND LEN(@ExtraIDs) > 0
    BEGIN
        ;WITH ExtraTable AS (
            SELECT CAST(value AS INT) AS ExtraID
            FROM STRING_SPLIT(@ExtraIDs, ',')
        )
        SELECT @TotalAmount = @TotalAmount + ISNULL(SUM(EX.ExtraPrice),0)
        FROM ExtraTable ET
        JOIN EXTRAS EX ON ET.ExtraID = EX.ExtraID;
    END

    -- 3. Insert into SALES
    INSERT INTO SALES (BaristaID, CustomerID, TotalAmount)
    VALUES (@BaristaID, @CustomerID, @TotalAmount);

    SET @SaleID = SCOPE_IDENTITY();

    -- 4. Insert into SALE_DETAILS
    INSERT INTO SALE_DETAILS (SaleID, BeverageID)
    VALUES (@SaleID, @BeverageID);

    SET @SaleDetailID = SCOPE_IDENTITY();

    -- 5. Insert into SALE_DETAIL_EXTRAS
    IF @ExtraIDs IS NOT NULL AND LEN(@ExtraIDs) > 0
    BEGIN
        ;WITH ExtraTable AS (
            SELECT CAST(value AS INT) AS ExtraID
            FROM STRING_SPLIT(@ExtraIDs, ',')
        )
        INSERT INTO SALE_DETAIL_EXTRAS (SaleDetailID, ExtraID)
        SELECT @SaleDetailID, ExtraID
        FROM ExtraTable;
    END

    -- 6. Return SaleID
    SELECT @SaleID AS CreatedSaleID;
END
GO

/* 17. TEST: Create a sample sale
    Latte Medium + Extra Shot + Vanilla Syrup by Barista 1, Customer 2 */
EXEC sp_CreateSale 
    @BaristaID = 1,
    @CustomerID = 2,
    @BeverageID = 3, -- Latte Medium
    @ExtraIDs = '1,2';

SELECT * FROM SALES;
SELECT * FROM SALE_DETAILS;
SELECT * FROM SALE_DETAIL_EXTRAS;
SELECT * FROM CUSTOMERS; -- to verify loyalty points
SELECT * FROM dbo.ufn_DetailedMenu();
SELECT * FROM vSalesReport;