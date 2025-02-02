-- Library Management System Project 2
CREATE DATABASE `libary_project2`;

USE `libary_project2`;

-- Creating branch table
DROP TABLE IF EXISTS `branch`;
CREATE TABLE `branch`(
    branch_id VARCHAR(10) PRIMARY KEY,
    manager_id VARCHAR(10),
    branch_address VARCHAR(55),
    contact_no VARCHAR(10)
);

-- Creating employees table
DROP TABLE IF EXISTS `employees`;
CREATE TABLE `employees`(
    emp_id VARCHAR(10) PRIMARY KEY,
    emo_name VARCHAR(25),
    position VARCHAR(15),
    salary INT,
    branch_id VARCHAR(25),  -- FK
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

-- Creating table for books
DROP TABLE IF EXISTS `books`;
CREATE TABLE `books`(
    isbn VARCHAR(20) PRIMARY KEY,
    book_title VARCHAR(25),
    category VARCHAR(10),
    rental_price FLOAT,
    status VARCHAR(15),
    author VARCHAR(35),
    publisher VARCHAR(35)
);

-- Creating table for members
DROP TABLE IF EXISTS `members`;
CREATE TABLE `members`(
    member_id VARCHAR(20) PRIMARY KEY,
    member_name VARCHAR(15),
    member_address VARCHAR(25),
    reg_date DATE
);

-- Creating table for issued_status
DROP TABLE IF EXISTS `issued_status`;
CREATE TABLE `issued_status`(
    issued_id VARCHAR(10) PRIMARY KEY,
    issued_member_id VARCHAR(20),  -- FK, matching with `member_id` in `members`
    issued_book_name VARCHAR(25),
    issued_date DATE,
    issued_book_isbn VARCHAR(20),  -- FK, matching with `isbn` in `books`
    issued_emp_id VARCHAR(10),     -- FK, matching with `emp_id` in `employees`
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn),
    FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id)
);

-- Creating table for return_status
DROP TABLE IF EXISTS `return_status`;
CREATE TABLE `return_status`(
    return_id VARCHAR(10) PRIMARY KEY,
    issued_id VARCHAR(10),
    return_book_name VARCHAR(75),
    return_date DATE,
    return_book_isbn VARCHAR(20),  -- Matches `isbn` in `books`
    FOREIGN KEY (issued_id) REFERENCES issued_status(issued_id),
    FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);

SELECT * FROM `books`;
SELECT * FROM `branch`;
SELECT * FROM `employees`;
SELECT * FROM `issued_status`;
SELECT * FROM `return_status`;
SELECT * FROM `members`;

 
---- Project Task CRUD Operations
-- Create: Inserted sample records into the books table.
-- Read: Retrieved and displayed data from various tables.
-- Update: Updated records in the employees table.
-- Delete: Removed records from the members table as needed.

--- Task 1. Create a New Book Recored -- "978-1-60129-456-2", "To Kill a Mockingbird", "Classic", "6.00", "Yes", "Harper Lee", "J.B. Lippincott & Co."
INSERT INTO `books` (`isbn`, `book_title`, `category`, `rental_price`, `status`, `author`, `publisher`)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', '6.00', 'Yes', 'Harper Lee', 'J.B. Lippincott & Co.');

SELECT * FROM `books`;



--- Task 2. Update an Existing Member's Address
UPDATE `members` SET member_address = '125 Main St'
WHERE member_id = 'C101';

SELECT * FROM `members`;



--- Task 3. Delete a Record from the Issued Status Table.
-- Objective: Delete the record with issued_id = 'IS106' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS106';

SELECT * FROM `issued_status`;



---- Task 4. Retrive All Books Issued by a specific Employee
-- Objective: Select all books issued by the employee with issued_emp_id = 'E111'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';



---- Task 5. List members who have issued more than one book.
-- Objective: Use GROUP BY find members who have issued more than one book.

SELECT 
       issued_emp_id,
       COUNT(issued_id) AS total_book_issued
FROM `issued_status`
GROUP BY issued_emp_id
HAVING COUNT(issued_id) > 1;



---- CTAS
-- Task 6. Create summary tables: Use CTAS to generate new tables based on querry results - each book and total book_issued_count.
CREATE TABLE book_cnts
AS
SELECT
      b.isbn,
      b.book_title,
      COUNT(ist.issued_id) AS number_issued
FROM books AS b
JOIN issued_status AS ist
ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

SELECT * FROM book_cnts;



--- Task 7. Retrive all books in a Specific Category.
SELECT * FROM `books` 
WHERE category = 'Fiction';



--- Task 8. Find total rental income by category.
SELECT
      b.category,
      SUM(b.rental_price),
      COUNT(*)
FROM `books` AS B
JOIN
issued_status AS ist
ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn;


--- Task 9. List members who registered on the last 180 days:
SELECT * FROM `members`
WHERE reg_date >= CURDATE() - INTERVAL 180 DAY;


--- Task 10. List employees with their branch manager's name and their branch details:
SELECT 
    e1.*,                          -- Select all columns from the first alias (employee)
    b.branch_id,                   -- Select the branch_id from the branch table
    e2.emo_name AS manager         -- Select the manager's name from the second employees table (e2) and alias it as 'manager'
FROM 
    `employees` AS e1              -- First join with employees (e1 for employee)
JOIN 
    branch AS b                    -- Join with the branch table
    ON b.branch_id = e1.branch_id  -- Match the branch_id from the employees table (e1) and branch table (b)
JOIN 
    employees AS e2                -- Second join with employees (e2 for manager)
    ON b.manager_id = e2.emp_id    -- Match the manager_id from the branch table (b) with the emp_id from the employees table (e2)



--- Task 11. Create a table of books with rental price above  a certain threshold 7USD:
CREATE TABLE `books_price_greater_than7USD` AS
SELECT * FROM `books`
WHERE rental_price > 7;

SELECT * FROM `books_price_greater_than7USD`;


--- Task 12. Retrive the list of books not yet returned:
SELECT 
      DISTINCT ist.issued_book_name
FROM `issued_status` AS ist
LEFT JOIN
return_status AS rs 
ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL;

SELECT * FROM `return_status`;



/*
Task 13:
Identify members with overdue books
Write a query to identify members who have overdue books (assume a 3-days return period).
Display the member's_id, member's name, book title, issue date and days overdue.
*/

-- issued_status == members == books == return_status
-- filter books which is return
-- overdue > 30 Days
SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    -- rs.return_date,
    DATEDIFF(CURDATE(), ist.issued_date) AS over_dues_days
FROM `issued_status` AS ist
JOIN members AS m
    ON m.member_id = ist.issued_member_id
JOIN books AS bk
    ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rs
    ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
    AND DATEDIFF(CURDATE(), ist.issued_date) > 310
ORDER BY 1;



/*
Task 14. Update book status on return
Write q querry to update the status of books in the books table to "Yes" when they are returned
(base on entried in thereturn_status table).
*/
-- 1. Select issued status for a specific book
SELECT * FROM `issued_status`
WHERE issued_book_isbn = '978-0-7432-7357-1';

-- 2. Select book details for the specified ISBN
SELECT * FROM `books`
WHERE isbn = '978-0-7432-7357-1';

-- 3. Update the book status to 'no'
UPDATE `books`
SET `status` = 'no'
WHERE `isbn` = '978-0-7432-7357-1';

-- 4. Select return status for a specific issued ID
SELECT * FROM `return_status`
WHERE issued_id = 'ISI101';

-- 5. Insert return status for a specific issued ID (corrected)
INSERT INTO `return_status` (`return_id`, `issued_id`, `return_date`)
VALUES ('RS125', 'ISI101', CURDATE());

SELECT * FROM return_status
WHERE issued_id = 'ISI101';
















 