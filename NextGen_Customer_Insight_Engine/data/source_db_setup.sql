CREATE TABLE SupportTickets (
    TicketID INT PRIMARY KEY,
    CustomerID VARCHAR(50),
    Priority VARCHAR(10),
    Region VARCHAR(50),
    LoadTimestamp DATETIME DEFAULT GETDATE()
);

INSERT INTO SupportTickets (TicketID, CustomerID, Priority, Region)
VALUES 
(1, 'C-101', 'High', 'Philadelphia'),
(2, 'C-102', 'Low', 'New Jersey'),
(3, 'C-103', 'Medium', 'Pittsburgh');
