-- 1. Report the store revenue, sort from high to low
SELECT 
    orders.Stores_Store_id,
    SUM(Quantity * FinalPrice) AS revenue
FROM
    orderdetails,
    orders
WHERE
    orderdetails.Orders_Orders_id = orders.Orders_id
GROUP BY orders.Stores_Store_id
ORDER BY revenue DESC;
 
 -- 2. How many customers had use new member discount?
SELECT 
    COUNT(DISTINCT orders.customers_Customers_id)
FROM
    orderdetails,
    orders
WHERE
    orderdetails.Orders_Orders_id = orders.Orders_id
        AND orderdetails.Coupons_Coupon_code = (SELECT 
            Coupon_code
        FROM
            coupons
        WHERE
            Coupon_description REGEXP '^new member');
 
 -- 3. Which products have higher than main category average quantity in stock?
SELECT 
    Product_name, QuantityInStock
FROM
    products,
    (SELECT 
        category_Main_category, AVG(QuantityInStock) AS avg_quant
    FROM
        products
    GROUP BY category_Main_category) AS subquery
WHERE
    products.category_Main_category = subquery.category_Main_category
        AND products.QuantityInStock > subquery.avg_quant;

-- 4. Which employees live close to the stores? (report the full employee names who have the same zipcode as the stores)
SELECT 
    CONCAT(firstName, ' ', lastName) AS employee_full_name
FROM
    employees,
    address
WHERE
    employees.address_Address_id = address.Address_id
        AND Zipcode IN (SELECT 
            zipcode
        FROM
            stores,
            address
        WHERE
            stores.address_Address_id = address.Address_id);

-- 5. Are there any customers who had shopped in all the stores?
SELECT 
    CONCAT(firstName, ' ', lastName) AS customer
FROM
    customers
WHERE
    NOT EXISTS( SELECT 
            *
        FROM
            stores
        WHERE
            NOT EXISTS( SELECT 
                    *
                FROM
                    orders
                WHERE
                    orders.Stores_Store_id = stores.Store_id
                        AND orders.customers_Customers_id = customers.Customers_id));

-- 6. Which coupon has more than 5% discount?
SELECT 
    coupon_description AS description,
    ROUND(AVG((unitprice - finalprice) / unitprice),
            2) AS discount
FROM
    coupons,
    orderdetails
WHERE
    coupons.coupon_code = orderdetails.Coupons_Coupon_code
GROUP BY coupon_code
HAVING discount > 0.05
ORDER BY discount DESC;

-- 7. Report the first and last name of the employees that work for the head of sales
SELECT 
    firstName, lastName
FROM
    employees,
    departments
WHERE
    departments.Depthead_Employee_id = employees.ReportTo_Employee_id
        AND departments.Department_name = 'Sales';

-- 8. Report the employees who has 4 as the last digit in their id, and his department head id ending with 1
SELECT 
    Employee_id, Depthead_Employee_id
FROM
    employees e
        LEFT JOIN
    departments d ON e.Department_name = d.Department_name
WHERE
    RIGHT(Employee_id, 1) = 4
        AND Depthead_Employee_id REGEXP '1$';

-- 9. Report the suppliers who have supplied more than 5 products
SELECT 
    Name
FROM
    suppliers
WHERE
    EXISTS( SELECT 
            COUNT(p.Product_id) AS p_numbers, s.Name
        FROM
            products p
                LEFT JOIN
            suppliers s ON p.Suppliers_Suppliers_id = s.Suppliers_id
        GROUP BY 2
        HAVING p_numbers > 5);

-- 10. Are there any suppliers not in Winston Salem?
SELECT 
    Name
FROM
    suppliers
WHERE
    address_Address_id NOT IN (SELECT 
            address_id
        FROM
            address
        WHERE
            city = 'Winston Salem');


