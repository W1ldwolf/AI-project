-- ===========================
-- Warehouse Order Management Setup and Process
-- ===========================

-- 1. Drop existing objects (if they exist)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ORDER_LINES';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ORDERS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE INVENTORY';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE ORDERS_SEQ';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE ORDER_LINES_SEQ';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- 2. Create tables

CREATE TABLE INVENTORY (
    ITEM_ID           NUMBER PRIMARY KEY,
    QUANTITY_ON_HAND  NUMBER NOT NULL
);
/

CREATE TABLE ORDERS (
    ORDER_ID      NUMBER PRIMARY KEY,
    CUSTOMER_ID   NUMBER NOT NULL,
    ORDER_DATE    DATE NOT NULL,
    STATUS        VARCHAR2(20) NOT NULL
);
/

CREATE TABLE ORDER_LINES (
    ORDER_LINE_ID  NUMBER PRIMARY KEY,
    ORDER_ID       NUMBER NOT NULL,
    ITEM_ID        NUMBER NOT NULL,
    QUANTITY       NUMBER NOT NULL,
    CONSTRAINT fk_order
        FOREIGN KEY (ORDER_ID) REFERENCES ORDERS(ORDER_ID),
    CONSTRAINT fk_item
        FOREIGN KEY (ITEM_ID) REFERENCES INVENTORY(ITEM_ID)
);
/

-- 3. Create sequences

CREATE SEQUENCE ORDERS_SEQ
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
/

CREATE SEQUENCE ORDER_LINES_SEQ
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
/

-- 4. Insert sample inventory data

INSERT INTO INVENTORY (ITEM_ID, QUANTITY_ON_HAND) VALUES (1001, 100);
INSERT INTO INVENTORY (ITEM_ID, QUANTITY_ON_HAND) VALUES (1002, 50);
COMMIT;
/

-- 5. Order Management Process (PL/SQL Block)

SET SERVEROUTPUT ON;
/

DECLARE
    v_order_id        NUMBER;
    v_customer_id     NUMBER := 201; -- Example customer
    v_order_date      DATE := SYSDATE;
    v_status          VARCHAR2(20) := 'NEW';
    -- Example data: list of items and quantities to order
    TYPE item_table IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE qty_table IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    items   item_table;
    qtys    qty_table;
    v_item_id         NUMBER;
    v_quantity        NUMBER;
    v_stock_on_hand   NUMBER;
BEGIN
    -- Example: Ordering 2 items
    items(1) := 1001; qtys(1) := 10;  -- Item 1001, 10 units
    items(2) := 1002; qtys(2) := 5;   -- Item 1002, 5 units

    -- Insert into ORDERS table
    INSERT INTO ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, STATUS)
    VALUES (ORDERS_SEQ.NEXTVAL, v_customer_id, v_order_date, v_status)
    RETURNING ORDER_ID INTO v_order_id;

    -- Loop through each item and process order lines
    FOR i IN 1 .. items.COUNT LOOP
        v_item_id := items(i);
        v_quantity := qtys(i);

        -- Check inventory
        SELECT NVL(QUANTITY_ON_HAND, 0)
        INTO v_stock_on_hand
        FROM INVENTORY
        WHERE ITEM_ID = v_item_id
        FOR UPDATE;

        IF v_stock_on_hand >= v_quantity THEN
            -- Insert into ORDER_LINES table
            INSERT INTO ORDER_LINES (ORDER_LINE_ID, ORDER_ID, ITEM_ID, QUANTITY)
            VALUES (ORDER_LINES_SEQ.NEXTVAL, v_order_id, v_item_id, v_quantity);

            -- Reserve stock (deduct from inventory)
            UPDATE INVENTORY
            SET QUANTITY_ON_HAND = QUANTITY_ON_HAND - v_quantity
            WHERE ITEM_ID = v_item_id;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Insufficient stock for item: ' || v_item_id);
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order process completed for order: ' || v_order_id);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in order process: ' || SQLERRM);
END;
/ 